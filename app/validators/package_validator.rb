# 包裹数据验证器
class PackageValidator
  def self.validate_create_params(params)
    errors = []
    
    # 必填字段验证
    required_fields = [:tracking_number, :recipient_name, :recipient_phone, :recipient_address]
    required_fields.each do |field|
      if params[field].blank?
        errors << "#{field.to_s.humanize}不能为空"
      end
    end
    
    # 手机号格式验证
    if params[:recipient_phone].present?
      phone_regex = /^1[3-9]\d{9}$/
      unless phone_regex.match?(params[:recipient_phone])
        errors << "手机号格式不正确"
      end
    end
    
    # 运单号格式验证
    if params[:tracking_number].present?
      unless params[:tracking_number].match?(/^[A-Za-z0-9]{10,20}$/)
        errors << "运单号格式不正确"
      end
      
      # 检查运单号是否已存在
      if Package.exists?(tracking_number: params[:tracking_number])
        errors << "运单号已存在"
      end
    end
    
    # 重量验证
    if params[:weight].present?
      weight = params[:weight].to_f
      if weight <= 0 || weight > 100
        errors << "包裹重量必须在0.01-100kg之间"
      end
    end
    
    errors
  end
  
  def self.validate_update_params(params)
    errors = []
    
    # 状态验证
    if params[:status].present?
      valid_statuses = Package.statuses.keys
      unless valid_statuses.include?(params[:status])
        errors << "无效的状态值"
      end
    end
    
    # 包裹类型验证
    if params[:package_type].present?
      valid_types = Package.package_types.keys
      unless valid_types.include?(params[:package_type])
        errors << "无效的包裹类型"
      end
    end
    
    errors
  end
  
  def self.validate_pickup_params(params)
    errors = []
    
    if params[:pickup_code].blank?
      errors << "取件码不能为空"
    end
    
    if params[:pickup_code].present? && !params[:pickup_code].match?(/^\d{8}$/)
      errors << "取件码必须是8位数字"
    end
    
    errors
  end
end