Rails.application.routes.draw do
  # Main admin routes (moved outside domain constraints for Render compatibility)
    scope module: 'admin' do
      devise_for :users, controllers: {
        sessions: 'admin/devise/sessions',
        confirmations: 'admin/devise/confirmations',
        mailers: 'admin/devise/mailers',
        passwords: 'admin/devise/passwords',
        registrations: 'admin/devise/registrations',
        shared: 'admin/devise/shared',
        unlocks: 'admin/devise/unlocks'
    }

      resources :professor do
        member do
          patch :toggle_status
        end
      end

      resources :rooms do
        member do
          patch :toggle_status
        end
      end

      resources :users
      resources :schedules
      resources :room_display
      get "room_statuses", to: "room_display#room_statuses"
      resources :time_track
      resources :dashboard

      get 'history/index'
      get 'history/professor'
      get 'history/card'
      get 'history/room'
      get 'history/schedule'

    resources :rfids
    resources :cards do
      member do
        patch :toggle_status
      end
    end
    
    post 'registrations', to: 'cards#registrations'
    post 'card_scan', to: 'cards#card_scan'
  end

  # Keep professor domain constraint for professor-specific functionality (if needed)
  constraints(ProfessorDomainConstraint.new) do
    scope module: 'professor' do
      devise_for :users, controllers: {
        sessions: 'professor/users/sessions'
      }, as: :professor
    end
    root 'professor/professor#index', as: :professor_root
  end

  # Default root route
  root 'admin/dashboard#index'
  
  # Add admin_root_path helper for compatibility
  get '/admin', to: 'admin/dashboard#index', as: :admin_root
end
