class AddFieldsToOcrRecords < ActiveRecord::Migration[8.1]
  def change
    add_column :ocr_records, :parsed_data, :text, comment: '解析后的结构化数据(JSON)'
    add_column :ocr_records, :confidence, :float, comment: '整体置信度'
    add_column :ocr_records, :tracking_number_confidence, :float, default: 0.0, comment: '运单号置信度'
    add_column :ocr_records, :recipient_name_confidence, :float, default: 0.0, comment: '收件人置信度'
    add_column :ocr_records, :recipient_phone_confidence, :float, default: 0.0, comment: '手机号置信度'
    add_column :ocr_records, :recipient_address_confidence, :float, default: 0.0, comment: '地址置信度'
    add_column :ocr_records, :courier_company_confidence, :float, default: 0.0, comment: '快递公司置信度'
    add_reference :ocr_records, :package, foreign_key: true, comment: '关联的包裹'
  end
end
