Rails.application.routes.draw do

  resources :users
  resources :identities
  resources :datasets
  resources :binaries
  resources :creators
  resources :creators
  resources :datasets

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'

  resources :datasets do
    resources :creators
  end

  get '/faqs', to: 'welcome#faqs', :as => :faq
  get '/policies', to: 'welcome#policies', :as => :policies
  get '/help', to: 'welcome#help', :as => :help
  get '/contact', to: 'welcome#contact', :as => :contact
  get '/datasets/:id/download_endNote_XML', to: 'datasets#download_endNote_XML'
  get '/datasets/:id/download_BibTeX', to: 'datasets#download_BibTeX'
  get '/datasets/:id/download_RIS', to: 'datasets#download_RIS'
  get '/datasets/:id/download_plaintext_citation', to: 'datasets#download_plaintext_citation'

  get '/datasets/:id/stream_file/:web_id', to: 'datasets#stream_file'
  get '/datasets/:id/destroy_file/:web_id', to: 'datasets#destroy_file'

  get '/binaries/:id/download', to: 'binaries#download'

  # deposit
  get '/datasets/:id/deposit', to: 'datasets#deposit'

  # authentication routes
  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match '/login', to: 'sessions#new', as: :login, via: [:get, :post]
  match '/logout', to: 'sessions#destroy', as: :logout, via: [:get, :post]

  match '/auth/failure', to: 'sessions#unauthorized', as: :unauthorized, via: [:get, :post]


end