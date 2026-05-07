# 异常数据验证器
class ExceptionValidator
  def self.validate_create_params(params)
    errors = []
    
    required_fields = [:package_id, :exception_type, :description]
    required_fields.each do |field|
      if params[field].blank?
        errors << "#{field.to_s.humanize}不能为空"
      end
    end
    
    if params[:package_id].present?
      unless Package.exists?(params[:package_id])
        errors << "包裹不存在"
      end
    end
    
    if params[:exception_type].present?
      valid_types = PackageException.exception_types.keys
      unless valid_types.include?(params[:exception_type])
        errors << "无效的异常类型"
      end
    end
    
    if params[:description].present? && params[:description].length > 500
      errors << "异常描述不能超过500个字符"
    end
    
    errors
  end
  
  def self.validate_resolve_params(params)
    errors = []
    
    if params[:solution].blank?
      errors << "解决方案不能为空"
    end
    
    if params[:solution].present? && params[:solution].length > 1000
      errors << "解决方案不能超过1000个字符"
    end
    
    errors
  end
  
  def self.validate_update_params(params)
    errors = []
    
    if params[:status].present?
      valid_statuses = PackageException.statuses.keys
      unless valid_statuses.include?(params[:status])
        errors << "无效的状态值"
      end
    end
    
    errors
  end
end