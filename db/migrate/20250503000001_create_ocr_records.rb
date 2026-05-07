# 创建OCR记录表
class CreateOcrRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :ocr_records do |t|
      # 图片信息
      t.string :image_url, null: false, comment: "图片URL"
      t.string :image_file_name, comment: "原始文件名"
      t.integer :image_file_size, comment: "文件大小(字节)"
      t.string :image_content_type, comment: "文件类型"
      
      # OCR识别结果
      t.text :raw_text, comment: "原始识别文本"
      t.string :tracking_number, comment: "运单号"
      t.string :recipient_name, comment: "收件人姓名"
      t.string :recipient_phone, comment: "收件人电话"
      t.string :recipient_province, comment: "收件省"
      t.string :recipient_city, comment: "收件市"
      t.string :recipient_district, comment: "收件区"
      t.string :recipient_address, comment: "收件详细地址"
      t.string :sender_name, comment: "寄件人姓名"
      t.string :sender_phone, comment: "寄件人电话"
      t.string :courier_company, comment: "快递公司"
      
      # 质量评估
      t.float :confidence_score, default: 0.0, comment: "置信度分数(0-1)"
      t.integer :status, default: 0, comment: "状态: 0-待处理, 1-识别中, 2-已识别, 3-已修正, 4-失败"
      t.text :error_message, comment: "错误信息"
      
      # 处理时间
      t.float :processing_time, comment: "处理耗时(秒)"
      
      # 关联用户
      t.references :user, foreign_key: true, comment: "操作用户"
      
      t.timestamps
    end
    
    # 添加索引
    add_index :ocr_records, :status
    add_index :ocr_records, :tracking_number
    add_index :ocr_records, :created_at
  end
end