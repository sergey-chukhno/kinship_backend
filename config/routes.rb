Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  require "sidekiq/web"
  require "sidekiq/cron/web"
  # devise_for :admin_users, ActiveAdmin::Devise.config
  begin
    ActiveAdmin.routes(self)
  rescue
    ActiveAdmin::DatabaseHitDuringLoad
  end

  mount Lookbook::Engine, at: "/lookbook" if Rails.env.development?

  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  devise_for :users, path: "auth", controllers: {
    confirmations: "auth/confirmations",
    passwords: "auth/passwords",
    registrations: "auth/registrations",
    sessions: "auth/sessions"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root to: "projects#index"

  # pages
  get "/modal_example", to: "pages#modal_example"
  get "banned_information", to: "pages#banned_information"

  namespace :registration_stepper do
    resources :first_steps, only: %i[new create]
    resources :second_steps, only: %i[new create]
    resources :third_steps, only: %i[new create]
    resources :fourth_steps, only: %i[new create edit update]
    resources :fifth_steps, only: %i[edit update]
    resources :pupils, only: %i[new create]
    resources :pupil_skills, only: %i[edit]
    get "pending_confirmation", to: "fifth_steps#pending_confirmation"
    get "registration_complete", to: "fifth_steps#registration_complete"
  end

  resources :projects, only: %i[index show new create] do
    resources :project_members, only: %i[new create]
    resources :team_members, only: %i[edit update]
  end
  resources :user_skills, only: %i[update]
  resources :pupils, only: %i[update]
  resources :schools, only: %i[new create]
  resources :school_levels, only: %i[index]
  resources :companies, only: %i[new create]

  resources :participants, only: %i[index new create], controller: "participants/participants"
  namespace :participants do
    resources :schools, only: %i[index]
    resources :companies, only: %i[index]
    resources :projects, only: %i[index]
    resources :other_companies, only: %i[index]
    resources :contacts, only: %i[new create]
    resources :certificate, only: %i[update]
  end

  namespace :account do
    resources :profile, only: %i[edit update] do
      get "badges_tree", to: "badges#tree"
      get "badges_level", to: "badges#level"
      get "download", to: "badges#download"
    end
    resources :delete_account, only: %i[show new destroy]
    resources :skills, only: %i[edit update]
    resources :availabilities, only: %i[edit update]
    resources :networks, only: %i[edit update destroy]
    resources :schools, only: %i[edit update destroy]
    namespace :schools do
      resources :school_levels, only: %i[edit update]
    end
    resources :childrens, only: %i[index new create edit update destroy] do
      collection do
        get :school_levels
      end
    end
  end

  namespace :school_admin_panel do
    resources :school, only: %i[edit]
    resources :school_levels, only: %i[create edit update]
    resources :school_members, only: %i[show destroy]
    put "school_members/update_confirmation/:id", to: "school_members#update_confirmation",
      as: "school_members_update_confirmation"
    put "school_members/update_school_level/:id", to: "school_members#update_school_level",
      as: "school_members_update_school_level"
    put "school_members/update_role/:id", to: "school_members#update_role", as: "school_members_update_role"
    resources :partnerships, only: %i[show update]
    delete "partnerships/destroy_partnership/:member_id", to: "partnerships#destroy_partnership", as: "partnership_destroy_partnership"
  end

  namespace :company_admin_panel do
    resources :company_members, only: %i[show update destroy]
    put "company_members/update_confirmation/:id", to: "company_members#update_confirmation",
      as: "company_members_update_confirmation"
    put "company_members/update_role/:id", to: "company_members#update_role", as: "company_members_update_role"
    resources :company, only: %i[edit update]
    resources :company_skills, only: %i[edit update]
    resources :partnerships, only: %i[edit update]
    put "partnerships/update_sponsor_confirmation/:id", to: "partnerships#update_sponsor_confirmation", as: "partnership_update_sponsor_confirmation"
    delete "partnerships/destroy_sponsor/:sponsor_id", to: "partnerships#destroy_sponsor", as: "partnership_destroy_sponsor"
  end

  namespace :project_admin_panel do
    resources :project, only: %i[edit update] do
      get "badges_tree"
      get "modal_badges_details"
    end
    resources :project_members, only: %i[show destroy new create] do
      member do
        put :update_team
      end
    end
    put "project_members/update_confirmation/:id", to: "project_members#update_confirmation", as: "project_members_update_confirmation"
    put "project_members/update_admin_status/:id", to: "project_members#update_admin_status", as: "project_members_update_admin_status"
  end

  namespace :assign_badge_stepper do
    resources :first_step, only: %i[new create]
    resources :second_step, only: %i[new create]
    resources :third_step, only: %i[new create]
    resources :fourth_step, only: %i[new create]
    resources :fifth_step, only: %i[new create]
    resources :success_step, only: %i[show]
  end

  namespace :api do
    namespace :v1 do
      resources :companies, only: %i[index]
      resources :schools, only: %i[index]
    end
    namespace :v2 do
      resources :users, only: %i[index show]
    end
  end
end
