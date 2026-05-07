# 图片处理服务
class ImageProcessingService
  def initialize(image_path)
    @image_path = image_path
    @image = MiniMagick::Image.open(image_path)
  end

  # 完整预处理流程
  def process
    start_time = Time.now
    
    processed_image = @image
      .yield_self { |img| auto_rotate(img) }    # 自动旋转
      .yield_self { |img| resize(img) }         # 缩放
      .yield_self { |img| enhance(img) }        # 增强
      .yield_self { |img| denoise(img) }        # 去噪
    
    processing_time = Time.now - start_time
    
    {
      success: true,
      image: processed_image,
      processing_time: processing_time,
      original_info: {
        width: @image.width,
        height: @image.height,
        format: @image.type
      },
      processed_info: {
        width: processed_image.width,
        height: processed_image.height,
        format: processed_image.type
      }
    }
  rescue => e
    {
      success: false,
      error: e.message,
      error_backtrace: e.backtrace
    }
  end

  private

  # 自动旋转（基于EXIF信息）
  def auto_rotate(img)
    img.auto_orient
    img
  end

  # 缩放到合适尺寸
  def resize(img)
    max_width = 2000
    max_height = 2000
    
    if img.width > max_width || img.height > max_height
      img.resize "#{max_width}x#{max_height}>"
    end
    
    # 如果太小，放大
    if img.width < 800 || img.height < 800
      img.resize "800x800<"
    end
    
    img
  end

  # 图片增强
  def enhance(img)
    # 提高对比度
    img.contrast
    
    # 轻微锐化
    img.sharpen "0x1"
    
    img
  end

  # 去噪
  def denoise(img)
    # 使用降噪滤镜
    img.noise "gaussian"
    
    img
  end

  # 二值化（可选）
  def binarize(img, threshold = 128)
    img.threshold threshold
    img
  end

  # 保存处理后的图片
  def save_processed_image(output_path)
    result = process
    if result[:success]
      result[:image].write(output_path)
      output_path
    else
      nil
    end
  end
end