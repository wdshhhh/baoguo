# 百度OCR服务
class BaiduOcrService
  def initialize(image_path)
    @image_path = image_path
    @config = OcrConfig.engine_config('baidu')
    @access_token = nil
  end

  # 执行OCR识别
  def recognize
    start_time = Time.now

    # 检查配置是否完整
    unless valid_config?
      return {
        success: false,
        error: "百度OCR配置不完整，请检查 config/ocr_config.yml"
      }
    end

    # 预处理图片
    process_result = ImageProcessingService.new(@image_path).process
    unless process_result[:success]
      return {
        success: false,
        error: "图片预处理失败: #{process_result[:error]}"
      }
    end

    # 保存临时图片
    temp_path = Rails.root.join('tmp', "baidu_ocr_#{SecureRandom.uuid}.png")
    process_result[:image].write(temp_path)

    # 获取Access Token
    token = get_access_token
    unless token[:success]
      return {
        success: false,
        error: token[:error]
      }
    end
    @access_token = token[:access_token]

    # 调用百度OCR API
    result = call_baidu_ocr(temp_path)

    processing_time = Time.now - start_time

    # 清理临时文件
    File.delete(temp_path) if File.exist?(temp_path)

    if result[:success]
      {
        success: true,
        raw_text: result[:text],
        processing_time: processing_time,
        image_info: process_result[:processed_info],
        engine: 'baidu'
      }
    else
      {
        success: false,
        error: result[:error]
      }
    end
  rescue => e
    {
      success: false,
      error: "百度OCR识别失败: #{e.message}"
    }
  end

  private

  # 检查配置是否有效
  def valid_config?
    @config['api_key'].present? &&
      @config['secret_key'].present? &&
      @config['api_key'] != 'your_api_key'
  end

  # 获取百度Access Token
  def get_access_token
    url = "#{@config['endpoint']}/oauth/2.0/token"
    params = {
      grant_type: 'client_credentials',
      client_id: @config['api_key'],
      client_secret: @config['secret_key']
    }

    require 'net/http'
    require 'uri'
    require 'json'

    uri = URI.parse(url)
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      { success: true, access_token: result['access_token'] }
    else
      { success: false, error: "获取Access Token失败: #{response.message}" }
    end
  rescue => e
    { success: false, error: "获取Access Token异常: #{e.message}" }
  end

  # 调用百度OCR API
  def call_baidu_ocr(image_path)
    require 'net/http'
    require 'uri'
    require 'json'
    require 'base64'

    url = "#{@config['endpoint']}/rest/2.0/ocr/v1/general_basic?access_token=#{@access_token}"
    image_data = Base64.encode64(File.read(image_path)).gsub("\n", '')

    uri = URI.parse(url)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request.set_form_data(image: image_data)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      if result['error_code']
        { success: false, error: result['error_msg'] }
      else
        text = result['words_result'].map { |w| w['words'] }.join("\n")
        { success: true, text: text }
      end
    else
      { success: false, error: "API调用失败: #{response.message}" }
    end
  rescue => e
    { success: false, error: "调用百度OCR异常: #{e.message}" }
  end
end
