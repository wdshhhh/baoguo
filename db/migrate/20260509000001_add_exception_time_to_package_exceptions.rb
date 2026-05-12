class AddExceptionTimeToPackageExceptions < ActiveRecord::Migration[8.1]
  def change
    add_column :package_exceptions, :exception_time, :datetime, comment: '异常时间'
  end
end
