class PagesController < ApplicationController
  def welcome
    # 欢迎页面
  end

  # PC端异常管理页面
  def pc_exception_management
    # PC端异常管理页面
  end

  # OCR演示页面
  def ocr_demo
    render "ocr_demo_fixed"
  end
end
