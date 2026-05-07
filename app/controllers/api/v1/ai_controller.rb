module Api
  module V1
    class AiController < BaseController
      before_action :authenticate_user!
      skip_before_action :authenticate_user!, only: [ :ocr_parcel_public ]

      # POST /api/v1/ai/ocr_parcel_public
      # 公开OCR识别接口（免认证）
      def ocr_parcel_public
        begin
          # 检查是否上传了图片
          unless params[:image]
            return render_error("请上传快递面单图片")
          end

          # 使用Tesseract OCR服务（取消AI识别）
          tesseract_service = TesseractOcrService.new
          result = tesseract_service.recognize_parcel(params[:image])

          # 无论成功还是失败，都返回识别信息
          if result[:success]
            render json: { success: true, data: result[:data] }
          else
            # 即使失败，也返回识别数据（如果有的话）
            if result[:data]
              render json: { success: false, data: result[:data], error: result[:error] }
            else
              render json: { success: false, error: result[:error] }
            end
          end

        rescue => e
          Rails.logger.error("Tesseract OCR识别失败: #{e.message}")
          render_error("Tesseract OCR识别失败: #{e.message}")
        end
      end

      # POST /api/v1/ai/ocr_parcel
      # 快递面单OCR识别接口（旧版，兼容性接口）
      def ocr_parcel
        begin
          # 检查是否上传了图片
          unless params[:image]
            return render_error("请上传快递面单图片")
          end

          # 重定向到修复后的接口，保持兼容性
          ocr_parcel_enhanced

        rescue => e
          Rails.logger.error("OCR识别失败: #{e.message}")
          render_error("OCR识别失败: #{e.message}")
        end
      end

      # POST /api/v1/ai/ocr_manual_correction
      # 手动修正OCR识别结果
      def ocr_manual_correction
        begin
          unless params[:original_result] && params[:corrections]
            return render_error("请提供原始结果和修正内容")
          end

          ai_ocr_service = AiEnhancedOcrService.new
          result = ai_ocr_service.manual_correction(
            params[:original_result],
            params[:corrections]
          )

          if result[:success]
            render_json(result[:data])
          else
            render_error(result[:error])
          end

        rescue => e
          Rails.logger.error("手动修正失败: #{e.message}")
          render_error("手动修正失败: #{e.message}")
        end
      end

      # POST /api/v1/ai/ocr_batch
      # 批量OCR识别
      def ocr_batch
        begin
          unless params[:images] && params[:images].is_a?(Array)
            return render_error("请上传图片文件数组")
          end

          ai_ocr_service = AiEnhancedOcrService.new
          result = ai_ocr_service.batch_recognize(params[:images])

          if result[:success]
            render_json(result[:data])
          else
            render_error(result[:error])
          end

        rescue => e
          Rails.logger.error("批量OCR识别失败: #{e.message}")
          render_error("批量OCR识别失败: #{e.message}")
        end
      end

      # POST /api/v1/ai/ocr_parcel_enhanced
      # 修复的OCR识别接口（使用Tesseract OCR）
      def ocr_parcel_enhanced
        begin
          # 检查是否上传了图片
          unless params[:image]
            return render_error("请上传快递面单图片")
          end

          # 调用Tesseract OCR服务（取消AI识别）
          tesseract_service = TesseractOcrService.new
          result = tesseract_service.recognize_parcel(params[:image])

          # 无论成功还是失败，都返回识别信息
          if result[:success]
            render json: { success: true, data: result[:data] }
          else
            # 即使失败，也返回识别数据（如果有的话）
            if result[:data]
              render json: { success: false, data: result[:data], error: result[:error] }
            else
              render json: { success: false, error: result[:error] }
            end
          end

        rescue => e
          Rails.logger.error("Tesseract OCR识别失败: #{e.message}")
          render_error("Tesseract OCR识别失败: #{e.message}")
        end
      end
    end
  end
end
