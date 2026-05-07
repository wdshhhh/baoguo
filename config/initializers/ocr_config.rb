# OCR配置初始化
require 'yaml'

module OcrConfig
  CONFIG_PATH = Rails.root.join('config', 'ocr_config.yml')

  class << self
    # 获取当前环境的配置
    def config
      @config ||= load_config
    end

    # 获取当前使用的OCR引擎
    def current_engine
      config['engine'] || 'demo'
    end

    # 获取指定引擎的配置
    def engine_config(engine = current_engine)
      (config['engines'] || {})[engine] || {}
    end

    # 检查引擎是否启用
    def engine_enabled?(engine)
      engine_config(engine)['enabled']
    end

    # 设置使用哪个引擎
    def set_engine!(engine)
      config['engine'] = engine
      # 更新配置文件
      save_config!
    end

    # 可用的引擎列表
    def available_engines
      engines = config['engines'] || {}
      engines.keys.select { |e| engine_config(e)['enabled'] }
    end

    private

    # 加载配置
    def load_config
      if File.exist?(CONFIG_PATH)
        begin
          YAML.load_file(CONFIG_PATH)[Rails.env] || default_config
        rescue => e
          Rails.logger.error "OCR配置加载失败: #{e.message}"
          default_config
        end
      else
        default_config
      end
    end

    # 保存配置
    def save_config!
      begin
        full_config = YAML.load_file(CONFIG_PATH) rescue {}
        full_config[Rails.env] = config
        File.write(CONFIG_PATH, YAML.dump(full_config))
        @config = nil
      rescue => e
        Rails.logger.error "OCR配置保存失败: #{e.message}"
      end
    end

    # 默认配置
    def default_config
      {
        'engine' => 'demo',
        'engines' => {
          'tesseract' => { 'enabled' => true, 'lang' => 'chi_sim+eng', 'psm' => 1 },
          'demo' => { 'enabled' => true }
        }
      }
    end
  end
end

# 初始化时输出配置信息
Rails.logger.info "=" * 50
Rails.logger.info "OCR系统初始化"
Rails.logger.info "当前引擎: #{OcrConfig.current_engine}"
Rails.logger.info "可用引擎: #{OcrConfig.available_engines.join(', ')}"
Rails.logger.info "=" * 50
