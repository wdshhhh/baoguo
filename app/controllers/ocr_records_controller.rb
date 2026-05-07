# OCR记录控制器
class OcrRecordsController < ApplicationController
  before_action :set_ocr_record, only: [:show, :edit, :update, :destroy, :recognize]

  # GET /ocr_records
  def index
    @ocr_records = OcrRecord.recent.page(params[:page])
    @current_engine = OcrConfig.current_engine
    @available_engines = UnifiedOcrService.available_engines
  end

  # GET /ocr_records/1
  def show
    @current_engine = OcrConfig.current_engine
    @available_engines = UnifiedOcrService.available_engines
  end

  # GET /ocr_records/new
  def new
    @ocr_record = OcrRecord.new
    @current_engine = OcrConfig.current_engine
    @available_engines = UnifiedOcrService.available_engines
  end

  # GET /ocr_records/1/edit
  def edit
    @current_engine = OcrConfig.current_engine
    @available_engines = UnifiedOcrService.available_engines
  end

  # POST /ocr_records
  def create
    if params[:image].present?
      # 处理上传的图片
      result = process_uploaded_image(params[:image])

      if result[:success]
        @ocr_record = result[:ocr_record]
        redirect_to @ocr_record, notice: '面单上传成功，正在识别...'
      else
        flash[:alert] = result[:error]
        @ocr_record = OcrRecord.new
        render :new
      end
    else
      @ocr_record = OcrRecord.new(ocr_record_params)
      if @ocr_record.save
        redirect_to @ocr_record, notice: 'OCR记录创建成功。'
      else
        render :new
      end
    end
  end

  # PATCH/PUT /ocr_records/1
  def update
    if @ocr_record.update(ocr_record_params)
      @ocr_record.update_status(:corrected) if @ocr_record.recognized?
      redirect_to @ocr_record, notice: 'OCR记录更新成功。'
    else
      render :edit
    end
  end

  # DELETE /ocr_records/1
  def destroy
    @ocr_record.destroy
    redirect_to ocr_records_url, notice: 'OCR记录删除成功。'
  end

  # POST /ocr_records/1/recognize (重新识别)
  def recognize
    engine = params[:engine] || OcrConfig.current_engine
    OcrRecognitionJob.perform_later(@ocr_record, engine)
    @ocr_record.update_status(:processing)
    redirect_to @ocr_record, notice: "正在使用 #{engine} 引擎重新识别..."
  end

  # POST /ocr_records/switch_engine (切换引擎)
  def switch_engine
    engine = params[:engine]
    if engine.present?
      result = UnifiedOcrService.switch_engine!(engine)
      if result[:success]
        flash[:notice] = "已切换到 #{engine} 引擎"
      else
        flash[:alert] = result[:error]
      end
    end
    redirect_back(fallback_location: ocr_records_path)
  end

  private

  # 处理上传的图片
  def process_uploaded_image(uploaded_file)
    begin
      # 1. 创建临时文件
      temp_file = Tempfile.new(['ocr', File.extname(uploaded_file.original_filename)])
      temp_file.binmode
      temp_file.write(uploaded_file.read)
      temp_file.rewind

      # 2. 保存图片到public/uploads目录
      upload_dir = Rails.root.join('public', 'uploads', 'ocr')
      FileUtils.mkdir_p(upload_dir) unless File.exist?(upload_dir)

      filename = "ocr_#{SecureRandom.uuid}#{File.extname(uploaded_file.original_filename)}"
      file_path = upload_dir.join(filename)

      FileUtils.cp(temp_file.path, file_path)

      # 3. 创建OCR记录
      @ocr_record = OcrRecord.new(
        user: current_user,
        image_url: "/uploads/ocr/#{filename}",
        image_file_name: uploaded_file.original_filename,
        image_file_size: uploaded_file.size,
        image_content_type: uploaded_file.content_type,
        status: :pending
      )

      if @ocr_record.save
        # 4. 后台执行OCR识别
        OcrRecognitionJob.perform_later(@ocr_record)

        { success: true, ocr_record: @ocr_record }
      else
        { success: false, error: @ocr_record.errors.full_messages.join(', ') }
      end
    rescue => e
      { success: false, error: "上传失败: #{e.message}" }
    ensure
      temp_file&.close
      temp_file&.unlink
    end
  end

  # 设置OCR记录
  def set_ocr_record
    @ocr_record = OcrRecord.find(params[:id])
  end

  # 允许的参数
  def ocr_record_params
    params.require(:ocr_record).permit(
      :image_url, :tracking_number, :recipient_name, :recipient_phone,
      :recipient_province, :recipient_city, :recipient_district,
      :recipient_address, :sender_name, :sender_phone, :courier_company
    )
  end
end
