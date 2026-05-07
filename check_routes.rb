#!/usr/bin/env ruby

# 检查路由配置
require_relative 'config/environment'

puts "=== 路由配置详细检查 ==="
puts ""

# 获取所有路由
all_routes = Rails.application.routes.routes

# 查找OCR相关路由
ocr_routes = all_routes.select do |route|
  path = route.path.spec.to_s
  path.include?('ocr') || path.include?('ai')
end

puts "1. 所有OCR/AI相关路由:"
puts ""

ocr_routes.each do |route|
  path = route.path.spec.to_s
  verb = route.verb
  controller = route.defaults[:controller]
  action = route.defaults[:action]
  
  puts "   #{verb} #{path}"
  puts "     控制器: #{controller}##{action}"
  puts ""
end

puts ""
puts "2. 检查关键路由的完整路径:"
puts ""

# 检查关键路由的完整路径
critical_paths = [
  '/api/v1/ai/ocr_parcel',
  '/api/v1/ai/ocr_parcel_enhanced'
]

critical_paths.each do |path|
  matching_route = all_routes.find do |route|
    route_path = route.path.spec.to_s
    route_path == path || route_path == path + '(.:format)'
  end
  
  if matching_route
    puts "   ✅ #{path}: 路由存在"
    puts "     控制器: #{matching_route.defaults[:controller]}##{matching_route.defaults[:action]}"
    puts "     HTTP方法: #{matching_route.verb}"
  else
    puts "   ❌ #{path}: 路由不存在"
    
    # 查找相似路由
    similar_routes = all_routes.select do |route|
      route_path = route.path.spec.to_s
      route_path.include?('ocr') || route_path.include?('ai')
    end
    
    if similar_routes.any?
      puts "     相似路由:"
      similar_routes.first(3).each do |route|
        puts "       #{route.verb} #{route.path.spec.to_s}"
      end
    end
  end
  puts ""
end

puts ""
puts "3. 测试路由可用性:"
puts ""

# 测试路由可用性
begin
  # 创建测试请求
  app = Rails.application
  
  critical_paths.each do |path|
    puts "   测试 #{path}:"
    
    # 检查路由匹配
    env = Rack::MockRequest.env_for(path, method: 'POST')
    
    begin
      # 尝试匹配路由
      route_match = app.routes.recognize_path(path, method: 'POST')
      puts "     ✅ 路由匹配成功"
      puts "        控制器: #{route_match[:controller]}"
      puts "        动作: #{route_match[:action]}"
    rescue ActionController::RoutingError => e
      puts "     ❌ 路由匹配失败: #{e.message}"
    end
    
    puts ""
  end
  
rescue => e
  puts "   路由测试失败: #{e.message}"
end

puts "=== 路由检查完成 ==="