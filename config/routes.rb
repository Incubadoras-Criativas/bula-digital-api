Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      scope 'data', controller: :data do
        post :ping
        get :app_info
        get :medicamentos_search
        scope ':uuid' do
          get :edit_user
          post :update_user
        end
        scope ':medicamento_id' do
          get :bula_versoes
        end
        scope ':bula_id' do
          get :detalhes_bula
        end
      end
    end
  end

end
