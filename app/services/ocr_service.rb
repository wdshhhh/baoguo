class OcrService
  # 快递面单OCR识别
  # 使用Tesseract引擎进行真实OCR识别
  def recognize_parcel(image)
    begin
      # 创建临时文件保存图片（指定二进制模式）
      temp_file = Tempfile.new([ "ocr_upload", ".png" ], encoding: "binary")
      temp_path = temp_file.path
      temp_file.close

      # 处理图片数据
      if image.is_a?(String) && image.start_with?("data:image/")
        base64_data = image.split(",")[1]
        File.binwrite(temp_path, Base64.decode64(base64_data))
      elsif image.respond_to?(:read)
        # 读取二进制数据
        binary_data = image.read
        binary_data = binary_data.force_encoding("ASCII-8BIT") if binary_data.respond_to?(:force_encoding)
        File.binwrite(temp_path, binary_data)
      else
        return {
          success: false,
          error: "无法处理图片格式"
        }
      end

      # 使用OcrEngine进行真实识别
      result = OcrEngine.recognize(temp_path, {
        lang: "chi_sim+eng",
        enable_preprocessing: true
      })

      return result unless result[:success]

      # 使用后处理器进行纠错
      post_result = OcrPostProcessor.process(result[:result])
      result_data = post_result[:result]

      {
        success: true,
        data: {
          tracking_number: result_data[:tracking_number],
          name: result_data[:recipient_name],
          phone: result_data[:recipient_phone],
          company: result_data[:courier_company],
          address: result_data[:address]
        },
        raw_text: result[:text],
        confidence: result[:confidence],
        quality: post_result[:result][:quality],
        corrections: post_result[:corrections],
        suggestions: post_result[:suggestions]
      }

    rescue => e
      Rails.logger.error "OCR识别失败: #{e.message}"
      {
        success: false,
        error: "OCR识别失败: #{e.message}"
      }
    ensure
      File.delete(temp_path) if defined?(temp_path) && File.exist?(temp_path)
    end
  end
end
