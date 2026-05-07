# OCR识别后台任务
class OcrRecognitionJob < ApplicationJob
  queue_as :default

  def perform(ocr_record, engine = nil)
    Rails.logger.info "开始OCR识别: OCR记录ID=#{ocr_record.id}, 引擎=#{engine || OcrConfig.current_engine}"
    
    # 更新状态为处理中
    ocr_record.update_status(:processing)
    
    start_time = Time.now
    
    begin
      # 获取图片完整路径
      image_path = Rails.root.join('public', ocr_record.image_url.delete_prefix('/'))
      
      unless File.exist?(image_path)
        raise "图片文件不存在: #{image_path}"
      end
      
      # 1. 使用统一OCR服务
      ocr_service = UnifiedOcrService.new(image_path, engine)
      ocr_result = ocr_service.recognize
      
      unless ocr_result[:success]
        raise ocr_result[:error]
      end
      
      # 2. 解析结果
      parser = OcrResultParser.new(ocr_result[:raw_text])
      parsed_data = parser.parse
      
      # 3. 更新记录
      processing_time = Time.now - start_time
      
      ocr_record.update!(
        raw_text: ocr_result[:raw_text],
        tracking_number: parsed_data[:tracking_number],
        recipient_name: parsed_data[:recipient_name],
        recipient_phone: parsed_data[:recipient_phone],
        recipient_province: parsed_data[:recipient_province],
        recipient_city: parsed_data[:recipient_city],
        recipient_district: parsed_data[:recipient_district],
        recipient_address: parsed_data[:recipient_address],
        sender_name: parsed_data[:sender_name],
        sender_phone: parsed_data[:sender_phone],
        courier_company: parsed_data[:courier_company],
        processing_time: processing_time,
        status: :recognized
      )
      
      # 计算置信度
      confidence = ocr_record.calculate_confidence
      ocr_record.update!(confidence_score: confidence)
      
      Rails.logger.info "OCR识别完成: OCR记录ID=#{ocr_record.id}, 耗时=#{processing_time}s, 置信度=#{confidence}"
      
    rescue => e
      Rails.logger.error "OCR识别失败: OCR记录ID=#{ocr_record.id}, 错误=#{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      ocr_record.update_status(:failed, e.message)
    end
  end
end
