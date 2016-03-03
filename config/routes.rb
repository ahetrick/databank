Rails.application.routes.draw do

  resources :related_materials
  resources :funder_infos
  resources :funders
  resources :definitions
  #special temporary work-around
  get '/datasets/r1epy', to: redirect('https://www.ideals.illinois.edu/handle/2142/65511')

  resources :medusa_ingests
  resources :license_infos
  resources :datafiles
  resources :users
  resources :identities
  resources :datasets
  resources :creators


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'

  get '/faqs', to: 'welcome#faqs', :as => :faq
  get '/policies', to: 'welcome#policies', :as => :policies
  get '/help', to: 'help#index', :as => :help
  get '/welcome/deposit_login_modal', to: 'welcome#deposit_login_modal'
  get '/datasets/:id/download_endNote_XML', to: 'datasets#download_endNote_XML'
  get '/datasets/:id/download_BibTeX', to: 'datasets#download_BibTeX'
  get '/datasets/:id/download_RIS', to: 'datasets#download_RIS'
  get '/datasets/:id/download_plaintext_citation', to: 'datasets#download_plaintext_citation'

  get '/datasets/:id/destroy_file/:web_id', to: 'datasets#destroy_file'

  get '/datasets/:id/download_box_file/:box_file_id', to: 'datasets#download_box_file'

  # datafiles
  # get '/datafiles', to: 'datafiles#index'
  # get '/datasets/:dataset_key/datafiles', to: 'datafiles#index'
  #
  # get '/datasets/:dataset_key/datafiles/new', to: 'datafiles#new'
  # post '/datasets/:dataset_key/datafiles/new', to: 'datafiles#create'
  #
  # post '/datasets/:dataset_key/datafiles', to: 'datafiles#create'
  #
  # get '/datafiles/:web_id', to: 'datafiles#show'
  #
  # patch '/datafiles/:web_id', to: 'datafiles#update'
  # put '/datafiles/:web_id', to: 'datafiles#update'
  #
  # get '/datafiles/:web_id/edit', to: 'datafiles#edit'
  # get '/datafiles/:web_id/edit', to: 'datafiles#edit'
  #
  # delete '/datafiles/:web_id', to: 'datafiles#destroy'

  # deposit
  get '/datasets/:id/deposit', to: 'datasets#deposit'

  # tombstone
  get '/datasets/:id/tombstone', to: 'datasets#tombstone'

  # nuke
  get '/datasets/:id/nuke', to: 'datasets#nuke'

  # review agreement
  get '/review_deposit_agreement', to: 'datasets#review_deposit_agreement'
  get '/datasets/:id/review_deposit_agreement', to: 'datasets#review_deposit_agreement'


  # authentication routes
  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match '/login', to: 'sessions#new', as: :login, via: [:get, :post]
  match '/logout', to: 'sessions#destroy', as: :logout, via: [:get, :post]

  match '/auth/failure', to: 'sessions#unauthorized', as: :unauthorized, via: [:get, :post]

  # route binary downloads
  get "/datafiles/:id/download", to: "datafiles#download"

  # create from box file select widget
  post "/datafiles/create_from_box", to: 'datafiles#create_from_box'

  # cancel box upload
  get "/datasets/:id/datafiles/:web_id/cancel_box_upload", to: 'datasets#cancel_box_upload', defaults: { format: 'js' }

  # get citation text
  get "datasets/:id/citation_text", to: 'datasets#citation_text', defaults: {format: 'json'}

  post "/creators/update_row_order", to: 'creators#update_row_order'
  post "/creators/create_for_form", to: 'creators#create_for_form', defaults: {format: 'json'}

  post "/help/help_mail", to: 'help#help_mail', as: :help_mail

end