# 包裹数据验证器
class PackageValidator
  def self.validate_create_params(params)
    errors = {}
    
    # 运单号验证
    if params[:tracking_number].blank?
      errors[:tracking_number] = ["运单号不能为空"]
    else
      if params[:tracking_number].length < 12 || params[:tracking_number].length > 18
        errors[:tracking_number] = ["运单号长度必须在12-18位之间"]
      elsif !params[:tracking_number].match?(/^[A-Z0-9]+$/)
        errors[:tracking_number] = ["运单号只能包含大写字母和数字"]
      elsif Package.exists?(tracking_number: params[:tracking_number])
        errors[:tracking_number] = ["该运单号已存在"]
      end
    end
    
    # 收件人验证
    if params[:recipient_name].blank?
      errors[:recipient_name] = ["收件人不能为空"]
    else
      if params[:recipient_name].length < 2 || params[:recipient_name].length > 20
        errors[:recipient_name] = ["收件人姓名长度必须在2-20个字符之间"]
      elsif !params[:recipient_name].match?(/^[\u4e00-\u9fa5a-zA-Z0-9]+$/)
        errors[:recipient_name] = ["收件人姓名只能包含中文、英文和数字"]
      end
    end
    
    # 手机号验证
    if params[:recipient_phone].blank?
      errors[:recipient_phone] = ["手机号不能为空"]
    elsif !params[:recipient_phone].match?(/^1[3-9]\d{9}$/)
      errors[:recipient_phone] = ["请输入正确的11位手机号"]
    end
    
    # 快递公司验证
    if params[:courier_company].blank?
      errors[:courier_company] = ["请选择快递公司"]
    end
    
    # 地址验证（非必填）
    if params[:recipient_address].present? && params[:recipient_address].length > 200
      errors[:recipient_address] = ["地址不能超过200个字符"]
    end
    
    # 重量验证
    if params[:weight].present?
      weight = params[:weight].to_f
      if weight <= 0 || weight > 100
        errors[:weight] = ["包裹重量必须在0.01-100kg之间"]
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