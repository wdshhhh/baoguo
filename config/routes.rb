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

      # Packages
      resources :packages do
        collection do
          get "search_by_code"
          get "statistics"
          get "today_overview"
          get "export"
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
      end

      # Exceptions - 新的异常管理API
      resources :exceptions, controller: "exception_management", only: [:index, :show, :create, :destroy] do
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
      resources :operation_logs, only: [:index, :show]

      # System Settings
      resources :system_settings do
        collection do
          get "get_value"
          put "set_value"
          post "initialize_defaults"
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

      # OCR演示功能
      get "ocr/demo_data", to: "ocr_demo#demo_data"
      post "ocr/simulate", to: "ocr_demo#simulate_ocr"
      post "ocr/batch_simulate", to: "ocr_demo#batch_simulate"
      post "ocr/assess_quality", to: "ocr_demo#assess_quality"

      # OCR识别功能（包裹管理系统专用）
      post "ocr/recognize", to: "ocr#recognize"
      post "ocr/create_package", to: "ocr#create_package"
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
  get "pc/exception-management", to: "pages#pc_exception_management"
  get "ocr-demo", to: "pages#ocr_demo"

  # Catch-all route for frontend SPA - 正确处理前端路由
  get "*path", to: "pages#welcome", constraints: lambda { |req| req.format.html? }

  # Root path
  root "pages#welcome"
end
