# OCR控制器 - 专门用于包裹管理系统的OCR识别
module Api
  module V1
    class OcrController < BaseController
      before_action :authenticate_user!

      # POST /api/v1/ocr/recognize
      # OCR识别接口，专门用于包裹管理系统
      def recognize
        begin
          # 检查参数
          unless params[:image]
            return render_error("请上传快递面单图片")
          end

          # 验证图片格式和大小
          image = params[:image]
          unless valid_image?(image)
            return render_error("图片格式不支持或文件过大（最大10MB）")
          end

          # 保存临时文件
          temp_file_path = save_temp_image(image)

          # 调用修复的OCR服务
          ocr_service = FixedOcrService.new(temp_file_path)
          ocr_result = ocr_service.recognize

          unless ocr_result[:success]
            return render_error(ocr_result[:error])
          end

          # 解析结果
          parser = OcrResultParser.new(ocr_result[:raw_text])
          parsed_data = parser.parse

          # 清理临时文件
          File.delete(temp_file_path) if File.exist?(temp_file_path)

          # 返回结构化数据
          render_json({
            success: true,
            data: {
              tracking_number: parsed_data[:tracking_number],
              recipient_name: parsed_data[:recipient_name],
              recipient_phone: parsed_data[:recipient_phone],
              recipient_address: format_address(parsed_data),
              courier_company: parsed_data[:courier_company],
              raw_text: parsed_data[:raw_text],
              confidence: calculate_confidence(parsed_data)
            },
            processing_time: ocr_result[:processing_time]
          })

        rescue => e
          # 清理临时文件
          File.delete(temp_file_path) if temp_file_path && File.exist?(temp_file_path)

          Rails.logger.error("OCR识别失败: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          render_error("OCR识别失败: #{e.message}")
        end
      end

      # POST /api/v1/ocr/create_package
      # 直接创建包裹（OCR识别后直接入库）
      def create_package
        begin
          # 检查参数
          unless params[:image] && params[:package_data]
            return render_error("请上传图片并提供包裹数据")
          end

          # OCR识别
          image = params[:image]
          temp_file_path = save_temp_image(image)

          ocr_service = FixedOcrService.new(temp_file_path)
          ocr_result = ocr_service.recognize

          unless ocr_result[:success]
            return render_error(ocr_result[:error])
          end

          # 解析结果
          parser = OcrResultParser.new(ocr_result[:raw_text])
          parsed_data = parser.parse

          # 合并OCR结果和用户输入数据
          package_params = build_package_params(parsed_data, params[:package_data])

          # 创建包裹
          package = Package.new(package_params)
          package.stored_by = current_user
          package.status = :stored

          if package.save
            # 创建OCR记录
            OcrRecord.create!(
              user: current_user,
              package: package,
              image_path: save_ocr_image(image),
              raw_text: parsed_data[:raw_text],
              parsed_data: parsed_data,
              confidence: calculate_confidence(parsed_data)
            )

            render_json({
              success: true,
              message: "包裹创建成功",
              package: package.as_json(only: [ :id, :tracking_number, :recipient_name, :recipient_phone, :status ])
            })
          else
            render_error("包裹创建失败: #{package.errors.full_messages.join(', ')}")
          end

        rescue => e
          File.delete(temp_file_path) if temp_file_path && File.exist?(temp_file_path)
          Rails.logger.error("OCR包裹创建失败: #{e.message}")
          render_error("包裹创建失败: #{e.message}")
        end
      end

      private

      # 验证图片格式和大小
      def valid_image?(image)
        return false unless image.respond_to?(:content_type)

        allowed_types = [ "image/jpeg", "image/jpg", "image/png", "image/gif" ]
        max_size = 10.megabytes

        allowed_types.include?(image.content_type) && image.size <= max_size
      end

      # 保存临时图片
      def save_temp_image(image)
        temp_dir = Rails.root.join("tmp", "ocr_uploads")
        FileUtils.mkdir_p(temp_dir)

        temp_path = File.join(temp_dir, "ocr_#{SecureRandom.uuid}_#{image.original_filename}")
        File.binwrite(temp_path, image.read)

        temp_path
      end

      # 保存OCR图片到永久存储
      def save_ocr_image(image)
        upload_dir = Rails.root.join("public", "uploads", "ocr")
        FileUtils.mkdir_p(upload_dir)

        filename = "ocr_#{SecureRandom.uuid}_#{image.original_filename}"
        file_path = File.join(upload_dir, filename)

        File.binwrite(file_path, image.read)
        "/uploads/ocr/#{filename}"
      end

      # 格式化地址
      def format_address(parsed_data)
        address_parts = [
          parsed_data[:recipient_province],
          parsed_data[:recipient_city],
          parsed_data[:recipient_district],
          parsed_data[:recipient_address]
        ].compact.reject(&:empty?)

        address_parts.join("")
      end

      # 计算识别置信度
      def calculate_confidence(parsed_data)
        fields = [ :tracking_number, :recipient_name, :recipient_phone, :recipient_address ]
        detected_fields = fields.count { |field| parsed_data[field].present? }

        (detected_fields.to_f / fields.count).round(2)
      end

      # 构建包裹参数
      def build_package_params(parsed_data, user_data)
        {
          tracking_number: user_data[:tracking_number] || parsed_data[:tracking_number],
          recipient_name: user_data[:recipient_name] || parsed_data[:recipient_name],
          recipient_phone: user_data[:recipient_phone] || parsed_data[:recipient_phone],
          recipient_address: user_data[:recipient_address] || format_address(parsed_data),
          courier_company: user_data[:courier_company] || parsed_data[:courier_company],
          package_type: user_data[:package_type] || "normal",
          weight: user_data[:weight],
          description: user_data[:description],
          storage_location: user_data[:storage_location]
        }.compact
      end
    end
  end
end
