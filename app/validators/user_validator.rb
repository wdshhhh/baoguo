# 用户数据验证器
class UserValidator
  def self.validate_login_params(params)
    errors = []
    
    if params[:phone].blank?
      errors << "手机号不能为空"
    end
    
    if params[:password].blank?
      errors << "密码不能为空"
    end
    
    if params[:phone].present?
      phone_regex = /^1[3-9]\d{9}$/
      unless phone_regex.match?(params[:phone])
        errors << "手机号格式不正确"
      end
    end
    
    errors
  end
  
  def self.validate_register_params(params)
    errors = []
    
    required_fields = [:phone, :password, :name]
    required_fields.each do |field|
      if params[field].blank?
        errors << "#{field.to_s.humanize}不能为空"
      end
    end
    
    if params[:phone].present?
      phone_regex = /^1[3-9]\d{9}$/
      unless phone_regex.match?(params[:phone])
        errors << "手机号格式不正确"
      end
      
      if User.exists?(phone: params[:phone])
        errors << "手机号已注册"
      end
    end
    
    if params[:password].present? && params[:password].length < 6
      errors << "密码长度不能少于6位"
    end
    
    errors
  end
  
  def self.validate_update_params(params)
    errors = []
    
    if params[:name].present? && params[:name].length > 50
      errors << "姓名长度不能超过50个字符"
    end
    
    if params[:role].present?
      valid_roles = User.roles.keys
      unless valid_roles.include?(params[:role])
        errors << "无效的角色类型"
      end
    end
    
    errors
  end
end