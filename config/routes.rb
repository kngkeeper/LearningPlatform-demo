Rails.application.routes.draw do
  # Authentication routes with custom registration controller for student profile creation
  devise_for :users, controllers: {
    registrations: "registrations"
  }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "courses#index"

  # Course browsing and enrollment workflow
  # Students can view courses from their school and enroll through multiple payment methods
  resources :courses, only: [ :index, :show ] do
    resources :enrollments, only: [ :new, :create ]
  end

  # Analytics dashboard routes for platform administrators and school staff
  get "dashboard", to: "dashboard#index"
  get "dashboard/schools/:school_id", to: "dashboard#school", as: "dashboard_school"
end
