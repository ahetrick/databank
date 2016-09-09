Rails.application.routes.draw do

  get '/datasets/:dataset_id/datafiles/add', to: 'datafiles#add'

  resources :tokens
  resources :admin
  resources :deckfiles
  get "/datasets/pre_deposit", to: "datasets#pre_deposit"

  resources :related_materials
  resources :funder_infos
  resources :funders
  resources :definitions
  resources :medusa_ingests
  resources :license_infos
  resources :datafiles
  resources :users
  resources :identities
  resources :datasets do
    resources :datafiles do
      member do
        get 'upload', to: 'datafiles#upload'
        patch 'upload', to: 'datafiles#do_upload'
        get 'resume_upload', to: 'datafiles#resume_upload'
        patch 'update_status', to: 'datafiles#update_status'
        get 'reset_upload', to: 'datafiles#reset_upload'
      end
    end
    resources :creators
    resources :funders
    resources :related_materials
  end
  resources :creators

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'

  get '/', to: 'welcome#index'

  get '/policies', to: 'policies#index', :as => :policies
  get '/help', to: 'help#index', :as => :help
  get '/welcome/deposit_login_modal', to: 'welcome#deposit_login_modal'
  get '/datasets/:id/download_endNote_XML', to: 'datasets#download_endNote_XML'
  get '/datasets/:id/download_BibTeX', to: 'datasets#download_BibTeX'
  get '/datasets/:id/download_RIS', to: 'datasets#download_RIS'
  get '/datasets/:id/download_plaintext_citation', to: 'datasets#download_plaintext_citation'

  get '/datasets/:id/destroy_file/:web_id', to: 'datasets#destroy_file'

  get '/datasets/:id/download_box_file/:box_file_id', to: 'datasets#download_box_file'

  post 'api/dataset/:dataset_key/upload', to: 'api_dataset#upload', defaults: {format: 'json'}
  post 'api/dataset/:dataset_key/datafile', to: 'api_dataset#datafile', defaults: {format: 'json'}

  # deposit
  get '/datasets/:id/publish', to: 'datasets#publish'

  # tombstone
  get '/datasets/:id/tombstone', to: 'datasets#tombstone'

  # nuke
  get '/datasets/:id/nuke', to: 'datasets#nuke'

  # review agreement
  get '/review_deposit_agreement', to: 'datasets#review_deposit_agreement'
  get '/datasets/:id/review_deposit_agreement', to: 'datasets#review_deposit_agreement'

  # controller method protected by cancan
  get '/datasets/:id/get_new_token', to: 'datasets#get_new_token', defaults: {format: 'json'}

  # authentication routes
  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match '/login', to: 'sessions#new', as: :login, via: [:get, :post]
  match '/logout', to: 'sessions#destroy', as: :logout, via: [:get, :post]

  match '/auth/failure', to: 'sessions#unauthorized', as: :unauthorized, via: [:get, :post]

  # route binary downloads
  get "/datafiles/:id/download", to: "datafiles#download"

  # create from box file select widget
  post "/datafiles/create_from_url", to: 'datafiles#create_from_url'

  #create from deckfile
  post "/datafiles/create_from_deckfile", to: 'datafiles#create_from_deckfile', defaults: {format: 'json'}

  # cancel box upload
  get "/datasets/:id/datafiles/:web_id/cancel_box_upload", to: 'datasets#cancel_box_upload', defaults: {format: 'js'}

  # get citation text
  get "/datasets/:id/citation_text", to: 'datasets#citation_text', defaults: {format: 'json'}

  #determine remote content length, if possible
  post "/datafiles/remote_content_length", to: 'datafiles#remote_content_length', defaults: {format: 'json'}

  #create from url
  post "/datafiles/create_from_remote", to: 'datafiles#create_from_url_unknown_size', defaults: {format: 'json'}

  #get publish confirm message
  get "/datasets/:id/confirmation_message", to: 'datasets#confirmation_message', defaults: {format: 'json'}

  #patch to validate before updating a published dataset
  match "/datasets/:id/validate_change2published", to: 'datasets#validate_change2published', via: [:get, :post, :patch], defaults: {format: 'json'}

  post "/creators/update_row_order", to: 'creators#update_row_order'
  post "/creators/create_for_form", to: 'creators#create_for_form', defaults: {format: 'json'}

  post "/help/help_mail", to: 'help#help_mail', as: :help_mail

  post "/role_switch", to: 'sessions#role_switch'

  get "/datasets/:id/download_link", to: 'datasets#download_link', defaults: {format: 'json'}

  get "/datasets/:id/serialization", to: 'datasets#serialization', defaults: {format: 'json'}

  get "/datasets/:id/changelog", to: 'changelogs#edit'

  get "/sitemaps/sitemap.xml.gz", to: 'welcome#sitemap'

  get "/metrics/dataset_downloads", to: 'metrics#dataset_downloads', defaults: {format: 'json'}

  get "/metrics/file_downloads", to: 'metrics#file_downloads', defaults: {format: 'json'}

  get "/metrics", to: 'metrics#index'

  get "/datasets/:id/download_metrics", to: 'datasets#download_metrics', defaults: {format: 'json'}

  post "/datasets/:id/download_deckfile", to: 'datasets#download_deckfile'

  get "/deckfiles/:id/download", to: 'deckfiles#download'

  # catch unknown routes, but ignore datatables and progress-job routes, which are generated by engines.
  match "/*a" => "errors#error404", :constraints => lambda{|req| req.path !~/progress-job/ && req.path !~ /datatables/ }, via: [ :get, :post, :patch, :delete ]

end