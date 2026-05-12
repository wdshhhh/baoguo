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

  # 测试页面
  def test
    # 测试页面
  end

  # 简单测试页面
  def test_simple
    # 简单测试页面
  end

  # 基础Vue测试页面
  def test_basic
    # 基础Vue测试页面
  end

  # 简单登录页面
  def login_simple
    # 简单登录页面
    render layout: false
  end

  # 调试页面
  def debug
    # 调试页面
    render layout: false
  end

  # CDN登录页面
  def login_cdn
    # CDN登录页面
    render layout: false
  end

  # PC主页面
  def pc_main
    # PC主页面
    render layout: false
  end

  # PC CDN主页面
  def pc_cdn
    # PC CDN主页面
    render layout: false
  end

  # 新版Vue应用主页面
  def app_cdn
    # 新版Vue应用主页面
    # 添加缓存控制头，防止浏览器缓存旧版页面
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    render layout: false
  end

  # 用户端包裹查询页面
  def student_query
    # 用户端包裹查询页面 - 手机端适配
    render layout: false
  end
end
