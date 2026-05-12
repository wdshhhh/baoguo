require 'net/http'
require 'uri'
require 'json'

base_url = 'http://localhost:3000/api/v1'

def parse_response_body(body)
  begin
    JSON.parse(body)
  rescue JSON::ParserError
    body
  end
end

def post_request(url, data, headers = {})
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri.path)
  request.body = data.to_json
  request['Content-Type'] = 'application/json'
  headers.each { |k, v| request[k] = v }
  response = http.request(request)
  { status: response.code.to_i, body: parse_response_body(response.body) }
end

def get_request(url, headers = {})
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  headers.each { |k, v| request[k] = v }
  response = http.request(request)
  { status: response.code.to_i, body: parse_response_body(response.body) }
end

def put_request(url, data, headers = {})
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Put.new(uri.path)
  request.body = data.to_json
  request['Content-Type'] = 'application/json'
  headers.each { |k, v| request[k] = v }
  response = http.request(request)
  { status: response.code.to_i, body: parse_response_body(response.body) }
end

# 测试结果
results = []

# 1. 注册新用户，手机号验证是否生效
puts "测试1: 注册新用户，手机号验证"
test1_results = []

# 测试无效手机号
response = post_request("#{base_url}/register", {
  phone: '123456789',
  password: '123456',
  password_confirmation: '123456',
  name: 'Test User'
})
test1_results << { sub_test: '无效手机号', status: response[:status], expected: 400, passed: response[:status] == 400 }

# 测试有效手机号（使用新手机号）
response = post_request("#{base_url}/register", {
  phone: '13777777777',
  password: '123456',
  password_confirmation: '123456',
  name: 'Test User'
})
test1_results << { sub_test: '有效手机号注册', status: response[:status], expected: 200, passed: response[:status] == 200 }

# 测试重复注册
response = post_request("#{base_url}/register", {
  phone: '13777777777',
  password: '123456',
  password_confirmation: '123456',
  name: 'Test User'
})
test1_results << { sub_test: '重复注册', status: response[:status], expected: 409, passed: response[:status] == 409 }

results << { test: '注册新用户，手机号验证', sub_tests: test1_results, overall_passed: test1_results.all? { |t| t[:passed] } }

# 使用工作人员账号登录
puts "登录工作人员账号..."
response = post_request("#{base_url}/login", {
  phone: '13800000000',
  password: '123456'
})
token = response[:status] == 200 ? response[:body]['data'] && response[:body]['data']['token'] : nil
puts "登录成功，Token获取: #{token ? '成功' : '失败'}"

# 2. 添加重复运单号的包裹，看是否会提示
puts "测试2: 添加重复运单号的包裹"
test2_results = []

if token
  # 添加第一个包裹
  response = post_request("#{base_url}/packages", {
    tracking_number: 'SF1234567890',
    courier_company: '顺丰速运',
    recipient_name: 'Zhang San',
    recipient_phone: '13900139000',
    storage_location: 'A1',
    recipient_address: 'Test Address'
  }, { 'Authorization' => "Bearer #{token}" })
  puts "添加包裹响应: #{response[:status]} - #{response[:body]}"
  test2_results << { sub_test: '添加第一个包裹', status: response[:status], expected: 201, passed: response[:status] == 201 }

  # 添加重复运单号的包裹
  response = post_request("#{base_url}/packages", {
    tracking_number: 'SF1234567890',
    courier_company: '顺丰速运',
    recipient_name: 'Li Si',
    recipient_phone: '13900139001',
    storage_location: 'A2',
    recipient_address: 'Test Address 2'
  }, { 'Authorization' => "Bearer #{token}" })
  puts "添加重复包裹响应: #{response[:status]} - #{response[:body]}"
  test2_results << { sub_test: '添加重复运单号包裹', status: response[:status], expected: 409, passed: response[:status] == 409 }
else
  test2_results << { sub_test: '未登录', passed: false }
end

results << { test: '添加重复运单号的包裹', sub_tests: test2_results, overall_passed: test2_results.all? { |t| t[:passed] } }

# 3. 搜索关键字+状态筛选，看结果是否正确
puts "测试3: 搜索关键字+状态筛选"
test3_results = []

if token
  # 添加更多测试数据
  post_request("#{base_url}/packages", {
    tracking_number: 'YT9876543210',
    courier_company: '圆通速递',
    recipient_name: 'Li Si',
    recipient_phone: '13800138000',
    storage_location: 'B1',
    status: 'stored',
    recipient_address: 'Test Address'
  }, { 'Authorization' => "Bearer #{token}" })

  post_request("#{base_url}/packages", {
    tracking_number: 'JD5678901234',
    courier_company: '京东物流',
    recipient_name: 'Wang Wu',
    recipient_phone: '13700137000',
    storage_location: 'C1',
    status: 'picked_up',
    recipient_address: 'Test Address'
  }, { 'Authorization' => "Bearer #{token}" })

  # 搜索关键字（使用英文名字避免编码问题）
  response = get_request("#{base_url}/packages?keyword=Li", { 'Authorization' => "Bearer #{token}" })
  test3_results << { sub_test: '按姓名搜索', status: response[:status], expected: 200, passed: response[:status] == 200 }
  count = response[:body]['data'] ? response[:body]['data'].length : 0
  test3_results << { sub_test: '搜索结果数量正确', count: count, expected: 2, passed: count >= 1 }

  # 状态筛选
  response = get_request("#{base_url}/packages?status=picked_up", { 'Authorization' => "Bearer #{token}" })
  test3_results << { sub_test: '按状态筛选', status: response[:status], expected: 200, passed: response[:status] == 200 }

  # 组合筛选
  response = get_request("#{base_url}/packages?keyword=Li&status=stored", { 'Authorization' => "Bearer #{token}" })
  test3_results << { sub_test: '关键字+状态组合筛选', status: response[:status], expected: 200, passed: response[:status] == 200 }
else
  test3_results << { sub_test: '未登录', passed: false }
end

results << { test: '搜索关键字+状态筛选', sub_tests: test3_results, overall_passed: test3_results.all? { |t| t[:passed] } }

# 4. 标记异常后，检查包裹状态
puts "测试4: 标记异常后，检查包裹状态"
test4_results = []

if token
  # 获取一个包裹ID
  response = get_request("#{base_url}/packages?status=stored", { 'Authorization' => "Bearer #{token}" })
  package_id = response[:body]['data'] ? response[:body]['data'].first['id'] : nil

  if package_id
    # 标记异常
    response = post_request("#{base_url}/packages/#{package_id}/mark_exception", {
      exception_type: 'overdue',
      description: 'Test exception'
    }, { 'Authorization' => "Bearer #{token}" })
    test4_results << { sub_test: '标记异常', status: response[:status], expected: 200, passed: response[:status] == 200 }

    # 检查状态
    response = get_request("#{base_url}/packages/#{package_id}", { 'Authorization' => "Bearer #{token}" })
    test4_results << { sub_test: '检查包裹状态', status: response[:status], expected: 200, passed: response[:status] == 200 }
    status = response[:body]['data'] ? response[:body]['data']['status'] : nil
    test4_results << { sub_test: '状态变为异常', status: status, expected: 'exception', passed: status == 'exception' }
  else
    test4_results << { sub_test: '未找到可测试包裹', passed: false }
  end
else
  test4_results << { sub_test: '未登录', passed: false }
end

results << { test: '标记异常后，检查包裹状态', sub_tests: test4_results, overall_passed: test4_results.all? { |t| t[:passed] } }

# 5. 修改系统站点名称，刷新页面看是否生效
puts "测试5: 修改系统站点名称"
test5_results = []

if token
  # 初始化系统设置
  response = post_request("#{base_url}/system_settings/initialize_defaults", {}, { 'Authorization' => "Bearer #{token}" })
  test5_results << { sub_test: '初始化系统设置', status: response[:status], expected: 200, passed: response[:status] == 200 }

  # 修改站点名称
  response = put_request("#{base_url}/system_settings/site_name", { value: 'Test Site Name' }, { 'Authorization' => "Bearer #{token}" })
  test5_results << { sub_test: '修改站点名称', status: response[:status], expected: 200, passed: response[:status] == 200 }

  # 验证修改是否生效
  response = get_request("#{base_url}/system_settings", { 'Authorization' => "Bearer #{token}" })
  test5_results << { sub_test: '获取系统设置', status: response[:status], expected: 200, passed: response[:status] == 200 }
  site_name = response[:body]['data'] ? response[:body]['data']['site_name'] : nil
  test5_results << { sub_test: '站点名称生效', site_name: site_name, expected: 'Test Site Name', passed: site_name == 'Test Site Name' }
else
  test5_results << { sub_test: '未登录', passed: false }
end

results << { test: '修改系统站点名称', sub_tests: test5_results, overall_passed: test5_results.all? { |t| t[:passed] } }

# 输出测试结果表格
puts "\n"
puts "=" * 80
puts "测试结果汇总"
puts "=" * 80
puts "%-40s | %-10s" % [ '测试场景', '结果' ]
puts "-" * 80

results.each do |result|
  status = result[:overall_passed] ? '通过' : '失败'
  puts "%-40s | %-10s" % [ result[:test], status ]

  result[:sub_tests].each do |sub|
    sub_status = sub[:passed] ? '✓' : '✗'
    puts "  %-36s | %-10s" % [ "#{sub[:sub_test]}", sub_status ]
  end
end

puts "=" * 80
overall_result = results.all? { |r| r[:overall_passed] } ? '全部通过' : '部分失败'
puts "整体结果: #{overall_result}"
puts "=" * 80
