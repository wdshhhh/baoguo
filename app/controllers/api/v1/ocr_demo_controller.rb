# OCR演示控制器 - 用于演示图像识别功能
class Api::V1::OcrDemoController < ApplicationController
  before_action :authenticate_user!
  
  # 获取演示数据
  def demo_data
    demo_info = {
      system_status: {
        server_running: true,
        api_available: true,
        ai_service: 'DeepSeek API',
        image_processing: 'Active'
      },
      
      recognition_modes: [
        {
          id: 'auto',
          name: '自动模式',
          description: 'AI优先，失败时自动回退传统OCR',
          accuracy: '90-98%',
          speed: '中等',
          recommended: true
        },
        {
          id: 'ai',
          name: 'AI优先模式',
          description: '仅使用DeepSeek AI进行智能识别',
          accuracy: '85-95%',
          speed: '较慢',
          recommended: false
        },
        {
          id: 'hybrid',
          name: '混合模式',
          description: 'AI和传统OCR并行执行，结果融合',
          accuracy: '92-98%',
          speed: '较慢',
          recommended: true
        },
        {
          id: 'traditional',
          name: '传统OCR模式',
          description: '仅使用传统OCR引擎',
          accuracy: '70-85%',
          speed: '快速',
          recommended: false
        }
      ],
      
      supported_formats: [
        { format: 'JPEG', extensions: ['.jpg', '.jpeg'], max_size: '10MB' },
        { format: 'PNG', extensions: ['.png'], max_size: '10MB' },
        { format: 'WEBP', extensions: ['.webp'], max_size: '10MB' }
      ],
      
      image_requirements: {
        min_dimensions: { width: 300, height: 300 },
        recommended_dimensions: { width: 800, height: 600 },
        quality_metrics: ['清晰度', '亮度', '对比度']
      },
      
      demo_results: [
        {
          id: 1,
          tracking_number: 'SF1234567890',
          customer_name: '张三',
          customer_phone: '13800138000',
          courier_company: '顺丰速运',
          recipient_address: '北京市朝阳区某某街道某某小区',
          confidence: 0.95,
          processing_time: '2.3秒',
          mode: '混合模式'
        },
        {
          id: 2,
          tracking_number: 'YT9876543210',
          customer_name: '李四',
          customer_phone: '13900139000',
          courier_company: '圆通快递',
          recipient_address: '上海市浦东新区某某路某某号',
          confidence: 0.88,
          processing_time: '1.8秒',
          mode: '自动模式'
        },
        {
          id: 3,
          tracking_number: 'ZT1237894560',
          customer_name: '王五',
          customer_phone: '13700137000',
          courier_company: '中通快递',
          recipient_address: '广州市天河区某某大道某某大厦',
          confidence: 0.92,
          processing_time: '3.1秒',
          mode: 'AI优先模式'
        }
      ],
      
      performance_metrics: {
        average_recognition_time: '2.5秒',
        batch_processing_capacity: '10张/批次',
        memory_usage: '50-100MB',
        success_rate: '96%'
      }
    }
    
    render json: {
      success: true,
      data: demo_info
    }
  end
  
  # 模拟OCR识别
  def simulate_ocr
    image_data = params[:image_data]
    mode = params[:mode] || 'auto'
    
    # 模拟处理延迟
    sleep(2) if Rails.env.development?
    
    # 生成模拟识别结果
    mock_results = generate_mock_ocr_result(mode)
    
    render json: {
      success: true,
      data: mock_results,
      processing_info: {
        mode: mode,
        processing_time: "#{rand(1.5..4.0).round(1)}秒",
        image_size: "#{rand(500..2000)}x#{rand(400..1500)}",
        quality_score: rand(7.0..9.5).round(1)
      }
    }
  end
  
  # 批量模拟识别
  def batch_simulate
    image_count = params[:count].to_i.clamp(1, 10)
    mode = params[:mode] || 'auto'
    
    results = []
    image_count.times do |i|
      results << {
        id: i + 1,
        filename: "面单_#{i + 1}.jpg",
        status: 'completed',
        result: generate_mock_ocr_result(mode),
        processing_time: "#{rand(1.5..4.0).round(1)}秒"
      }
    end
    
    render json: {
      success: true,
      data: {
        total: image_count,
        successful: image_count,
        failed: 0,
        results: results
      }
    }
  end
  
  # 图像质量评估
  def assess_quality
    image_data = params[:image_data]
    
    # 模拟质量评估
    quality_metrics = {
      sharpness: rand(0.6..0.9).round(2),
      brightness: rand(0.4..0.8).round(2),
      contrast: rand(0.5..0.8).round(2),
      noise_level: rand(0.1..0.3).round(2)
    }
    
    overall_score = (quality_metrics[:sharpness] * 0.4 + 
                    quality_metrics[:brightness] * 0.2 + 
                    quality_metrics[:contrast] * 0.3 + 
                    (1 - quality_metrics[:noise_level]) * 0.1).round(2)
    
    valid = overall_score > 0.7
    errors = valid ? [] : ['图像模糊度过高', '亮度不足']
    
    render json: {
      success: true,
      data: {
        valid: valid,
        overall_score: overall_score,
        metrics: quality_metrics,
        errors: errors,
        recommendations: valid ? [] : ['建议在光线充足的环境下重新拍摄', '保持手机稳定避免模糊']
      }
    }
  end
  
  private
  
  def generate_mock_ocr_result(mode)
    courier_companies = ['顺丰速运', '圆通快递', '中通快递', '申通快递', '韵达快递']
    customer_names = ['张三', '李四', '王五', '赵六', '钱七']
    areas = ['北京市朝阳区', '上海市浦东新区', '广州市天河区', '深圳市南山区', '杭州市西湖区']
    
    base_confidence = case mode
                     when 'ai' then rand(0.85..0.95)
                     when 'hybrid' then rand(0.90..0.98)
                     when 'traditional' then rand(0.70..0.85)
                     else rand(0.88..0.95)
                     end
    
    {
      tracking_number: generate_tracking_number,
      customer_name: customer_names.sample,
      customer_phone: "1#{rand(3..9)}#{rand(100000000..999999999)}",
      courier_company: courier_companies.sample,
      recipient_address: "#{areas.sample}某某街道某某小区#{rand(1..20)}栋#{rand(101..1501)}",
      confidence: base_confidence,
      details: {
        mode: mode,
        processing_time: rand(1500..4000),
        raw_text: "模拟识别出的原始文本：运单号 #{generate_tracking_number} 收件人 #{customer_names.sample} 电话 1#{rand(3..9)}#{rand(100000000..999999999)} 地址 #{areas.sample}",
        corrections: rand(0..2) > 0 ? ['手机号格式校正', '姓名字符校正'] : []
      }
    }
  end
  
  def generate_tracking_number
    prefixes = ['SF', 'YT', 'ZT', 'ST', 'YD']
    "#{prefixes.sample}#{rand(100000000..999999999)}"
  end
end