class ExcelImportService
  def self.import(file_path)
    require "roo"

    spreadsheet = Roo::Spreadsheet.open(file_path)
    headers = spreadsheet.row(1).map(&:downcase)

    # 验证列名
    required_columns = [ "运单号", "收件人", "手机号", "地址", "快递公司" ].map(&:downcase)
    missing_columns = required_columns - headers

    return { success: false, message: "缺少必需的列：#{missing_columns.join(', ')}" } if missing_columns.any?

    results = { success: 0, failed: 0, errors: [] }

    (2..spreadsheet.last_row).each do |row_num|
      begin
        row = Hash[headers.zip(spreadsheet.row(row_num))]

        # 处理Excel中的数据，确保都是字符串
        tracking_number = row["运单号"] ? row["运单号"].to_s.strip : ""
        recipient_name = row["收件人"] ? row["收件人"].to_s.strip : ""
        recipient_phone = row["手机号"] ? row["手机号"].to_s.strip : ""
        recipient_address = row["地址"] ? row["地址"].to_s.strip : ""
        courier_company = row["快递公司"] ? row["快递公司"].to_s.strip : ""

        package = Package.new(
          tracking_number: tracking_number,
          recipient_name: recipient_name,
          recipient_phone: recipient_phone,
          recipient_address: recipient_address,
          courier_company: courier_company,
          status: :pending
        )

        if package.save
          results[:success] += 1
        else
          results[:failed] += 1
          results[:errors] << "第#{row_num}行: #{package.errors.full_messages.join(', ')}"
        end
      rescue => e
        results[:failed] += 1
        results[:errors] << "第#{row_num}行: #{e.message}"
      end
    end

    {
      success: true,
      message: "导入完成，成功 #{results[:success]} 条，失败 #{results[:failed]} 条",
      data: results
    }
  end
end
