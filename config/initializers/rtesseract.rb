# RTesseract配置
# Tesseract OCR初始化配置

RTesseract.configure do |config|
  # Tesseract可执行文件路径（如果不在PATH中，取消注释并设置）
  # config.command = '/usr/local/bin/tesseract'

  # OCR语言配置（简体中文+英文）
  config.lang = 'chi_sim+eng'

  # PSM模式（页面分割模式）
  # 1: 自动页面分割
  # 3: 完全自动页面分割
  # 6: 统一文本块
  config.psm = 1

  # OEM模式（OCR引擎模式）
  # 3: 默认，基于深度学习的LSTM
  config.oem = 3

  # 置信度阈值
  # config.threshold = 60
end

Rails.logger.info "✓ RTesseract配置已加载"
Rails.logger.info "  - 语言: chi_sim+eng (简体中文+英文)"
Rails.logger.info "  - PSM模式: 1 (自动页面分割)"
Rails.logger.info "  - OEM模式: 3 (LSTM深度学习)"
