Rails.application.routes.draw do
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"

  # API Routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post "login", to: "sessions#create"
      post "register", to: "sessions#register"
      delete "logout", to: "sessions#destroy"
      get "current_user", to: "sessions#current"
      post "refresh_token", to: "sessions#refresh"

      # Packages
      resources :packages do
        collection do
          get "search_by_code"
          get "search_by_phone_suffix"
          get "statistics"
          get "today_overview"
          get "weekly_stats"
          get "export"
          post "import"
          post "batch_store"
          post "batch_pick_up"
        end
        member do
          post "store"
          post "pick_up"
          post "mark_exception"
        end
      end

      # Users
      resources :users do
        collection do
          get "profile"
          put "update_profile"
          put "change_password"
        end
        member do
          put "update_role"
          put "reset_password"
          put "enable"
          put "disable"
        end
      end

      # Exceptions - 新的异常管理API
      resources :exceptions, controller: "exception_management", only: [ :index, :show, :create, :destroy ] do
        member do
          post :process, to: "exception_management#mark_as_processing"
          post :resolve
        end
      end

      # Notifications
      resources :notifications do
        collection do
          get "unread_count"
          post "mark_all_read"
        end
        member do
          post "mark_read"
        end
      end

      # Operation Logs
      resources :operation_logs, only: [ :index, :show ] do
        collection do
          post "export"
        end
      end

      # Dashboard
      get "dashboard/stats", to: "dashboard#stats"
      get "dashboard/recent_activities", to: "dashboard#recent_activities"

      # AI功能
      post "ai/ocr_parcel", to: "ai#ocr_parcel"
      post "ai/ocr_parcel_enhanced", to: "ai#ocr_parcel_enhanced"
      post "ai/ocr_parcel_public", to: "ai#ocr_parcel_public"

      # 增强AI功能
      post "ai/intelligent_classification", to: "ai_enhanced#intelligent_classification"
      get "ai/exception_prediction", to: "ai_enhanced#exception_prediction"
      post "ai/chatbot", to: "ai_enhanced#chatbot"
      get "ai/analytics_report", to: "ai_enhanced#analytics_report"
      post "ai/speech_recognition", to: "ai_enhanced#speech_recognition"
      post "ai/text_to_speech", to: "ai_enhanced#text_to_speech"
      post "ai/advanced_ocr", to: "ai_enhanced#advanced_ocr"
      get "ai/real_time_alerts", to: "ai_enhanced#real_time_alerts"
      post "ai/batch_processing", to: "ai_enhanced#batch_processing"
      get "ai/system_status", to: "ai_enhanced#system_status"

      # AI助手
      post "ai/assistant", to: "ai_assistant#assistant"
      post "ai/validate_ocr", to: "ai_assistant#validate_ocr"
      post "ai/analyze_exceptions", to: "ai_assistant#analyze_exceptions"
      get "ai/get_suggestion", to: "ai_assistant#get_suggestion"
      get "ai/quick_actions", to: "ai_assistant#quick_actions"

      # 菜鸟驿站AI助手
      post "courier_ai/chat", to: "courier_ai#chat"
      get "courier_ai/quick_questions", to: "courier_ai#quick_questions"
      get "courier_ai/knowledge_base", to: "courier_ai#knowledge_base"
      get "courier_ai/daily_report", to: "courier_ai#daily_report"
      post "courier_ai/package_search", to: "courier_ai#package_search"
      post "courier_ai/clear_history", to: "courier_ai#clear_history"

      # OCR演示功能
      get "ocr/demo_data", to: "ocr_demo#demo_data"
      post "ocr/simulate", to: "ocr_demo#simulate_ocr"
      post "ocr/batch_simulate", to: "ocr_demo#batch_simulate"
      post "ocr/assess_quality", to: "ocr_demo#assess_quality"

      # OCR识别功能（包裹管理系统专用）
      post "ocr/recognize", to: "ocr#recognize"
      post "ocr/batch_recognize", to: "ocr#batch_recognize"
      get "ocr/history", to: "ocr#history"
      get "ocr/stats", to: "ocr#stats"
      post "ocr/create_package", to: "ocr#create_package"

      # 统计分析
      get "statistics/summary", to: "statistics#summary"
      get "statistics/trend", to: "statistics#trend"
      get "statistics/package_by_courier", to: "statistics#package_by_courier"
      get "statistics/weight_distribution", to: "statistics#weight_distribution"
      post "statistics/export", to: "statistics#export"

      # 系统设置
      get "system_settings", to: "system_settings#index"
      get "system_settings/logs", to: "system_settings#logs"
      get "system_settings/logs/history/:key", to: "system_settings#history"
      post "system_settings/rollback", to: "system_settings#rollback"
      get "system_settings/:key", to: "system_settings#show"
      put "system_settings/:key", to: "system_settings#update"
      put "system_settings/batch_update", to: "system_settings#batch_update"
      post "system_settings/reset", to: "system_settings#reset"
      post "system_settings/initialize_defaults", to: "system_settings#initialize_defaults"

      # 快递公司管理
      resources :courier_companies, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          put "toggle_status"
        end
      end

      # 货架管理
      resources :shelves, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          put "toggle_status"
        end
      end
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # OCR Records 路由
  resources :ocr_records do
    member do
      post :recognize
    end
    collection do
      post :switch_engine
    end
  end

  # 页面路由
  get "pages/welcome"
  get "pc", to: "pages#pc_cdn"
  get "dashboard", to: "pages#pc_cdn"
  get "login", to: "pages#login_cdn"
  get "pc/exception-management", to: "pages#pc_exception_management"
  get "ocr-demo", to: "pages#ocr_demo"
  get "test", to: "pages#test"
  get "test-simple", to: "pages#test_simple"
  get "test-basic", to: "pages#test_basic"
  get "test-nav", to: "pages#test_nav"
  get "login-simple", to: "pages#login_simple"
  get "debug", to: "pages#debug"
  get "login-cdn", to: "pages#login_cdn"
  get "student_query", to: "pages#student_query"

  # 前端SPA路由 - 所有pc子路径都指向pc_cdn
  get "pc/packages", to: "pages#pc_cdn"
  get "pc/exceptions", to: "pages#pc_cdn"
  get "pc/statistics", to: "pages#pc_cdn"
  get "pc/ocr", to: "pages#pc_cdn"
  get "pc/ai_assistant", to: "pages#pc_cdn"
  
  # 系统设置页面 - 使用旧版界面
  get "pc/settings", to: "pages#pc_cdn"

  # Root path - redirect to login
  root to: redirect("/login")

  # Catch-all route for frontend SPA - 正确处理前端路由
  get "*path", to: "pages#pc_cdn", constraints: lambda { |req| req.format.html? }
end
