require 'mini_magick'

class ImagePreprocessor
  # 预处理配置
  DEFAULT_OPTIONS = {
    enable_preprocessing: true,
    grayscale: true,
    binarize: true,
    denoise: true,
    deskew: true,
    sharpen: true,
    threshold: 0.5,
    blur_radius: 1,
    sharpen_radius: 1
  }.freeze

  def initialize(image_path, options = {})
    @image_path = image_path
    @options = DEFAULT_OPTIONS.merge(options)
    @image = MiniMagick::Image.open(image_path)
  end

  # 执行完整的预处理流程
  def process
    return @image_path unless @options[:enable_preprocessing]

    temp_file = Tempfile.new(['ocr_preprocessed', '.png'])
    temp_path = temp_file.path
    temp_file.close

    processed_image = @image.dup

    # 1. 灰度化
    processed_image = grayscale(processed_image) if @options[:grayscale]

    # 2. 二值化
    processed_image = binarize(processed_image) if @options[:binarize]

    # 3. 去噪
    processed_image = denoise(processed_image) if @options[:denoise]

    # 4. 纠偏
    processed_image = deskew(processed_image) if @options[:deskew]

    # 5. 锐化
    processed_image = sharpen(processed_image) if @options[:sharpen]

    processed_image.write(temp_path)

    temp_path
  end

  # 灰度化
  def grayscale(image)
    image.colorspace('Gray')
  end

  # 二值化（阈值处理）
  def binarize(image)
    image.threshold("#{(@options[:threshold] * 100).round}%")
  end

  # 去噪（使用中值滤波）
  def denoise(image)
    image.median(@options[:blur_radius])
  end

  # 纠偏
  def deskew(image)
    # 使用Deskew算法自动检测并纠正倾斜
    begin
      # 获取图像的方向信息
      result = `convert "#{image.path}" -deskew 40% -format "%[deskew:angle]" info:`
      angle = result.to_f
      
      if angle.abs > 0.5
        image.rotate(angle)
      else
        image
      end
    rescue StandardError
      image
    end
  end

  # 锐化
  def sharpen(image)
    image.unsharp("#{@options[:sharpen_radius]}x#{@options[:sharpen_radius] * 2}")
  end

  # 获取图像信息
  def info
    {
      width: @image.width,
      height: @image.height,
      format: @image.format,
      size: @image.size
    }
  end

  # 类方法：快速处理
  def self.process(image_path, options = {})
    new(image_path, options).process
  end
end
