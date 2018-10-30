# config/routes.rb
require './lib/api/base'


Rails.application.routes.draw do

  resources :databank_tasks, only: [:index, :show]
  get '/databank_tasks/pending', to: 'databank_tasks#pending'
  resources :ingest_responses
  #mount API::Base => '/api'

  resources :nested_items
  get '/featured_researchers/feature_none', to: 'featured_researchers#feature_none'

  get '/researcher_spotlights', to: 'featured_researchers#index'

  resources :featured_researchers do
    member do
      get 'preview'
      get 'feature'
    end
  end

  get '/datasets/download_citation_report', to: 'datasets#download_citation_report'

  get '/datasets/:dataset_id/datafiles/add', to: 'datafiles#add'

  get '/datasets/:id/recordtext', to: 'datasets#recordtext'

  resources :tokens
  resources :admin
  resources :deckfiles
  get "/datasets/pre_deposit", to: "datasets#pre_deposit"

  resources :related_materials
  resources :funders
  resources :definitions
  resources :medusa_ingests
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
        get 'preview', to: 'datafiles#preview'
        get 'display', to: 'datafiles#display'
        get 'filepath', to: 'datafiles#filepath', defaults: {format: 'json'}
        get 'bucket_and_key', to: 'datafiles#bucket_and_key', defaults: {format: 'json'}
        get 'viewtext', to: 'datafiles#peek_text', defaults: {format: 'json'}
        get 'iiif_filepath', to: 'datafiles#iiif_filepath', defaults: {format: 'json'}
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

  get '/check_token', to: 'welcome#check_token'

  get '/restoration_events', to: 'restoration_events#index'

  get '/audits', to: 'admin#audits'

  get '/policies', to: 'policies#index', :as => :policies
  get '/help', to: 'help#index', :as => :help
  get '/welcome/deposit_login_modal', to: 'welcome#deposit_login_modal'
  get '/datasets/:id/download_endNote_XML', to: 'datasets#download_endNote_XML'
  get '/datasets/:id/download_BibTeX', to: 'datasets#download_BibTeX'
  get '/datasets/:id/download_RIS', to: 'datasets#download_RIS'
  get '/datasets/:id/download_plaintext_citation', to: 'datasets#download_plaintext_citation'
  get '/datasets/:id/download_plaintext_citation', to: 'datasets#download_plaintext_citation'
  get '/datasets/:id/download_box_file/:box_file_id', to: 'datasets#download_box_file'

  post 'api/dataset/:dataset_key/upload', to: 'api_dataset#upload', defaults: {format: 'json'}
  post 'api/dataset/:dataset_key/datafile', to: 'api_dataset#datafile', defaults: {format: 'json'}

  # deposit
  get '/datasets/:id/publish', to: 'datasets#publish'

  # reserve doi
  get '/datasets/:id/reserve_doi', to: 'datasets#reserve_doi', defaults: {format: 'json'}

  # tombstone
  get '/datasets/:id/tombstone', to: 'datasets#tombstone'

  # nuke
  get '/datasets/:id/nuke', to: 'datasets#nuke'

  # review agreement
  get '/review_deposit_agreement', to: 'datasets#review_deposit_agreement'
  get '/datasets/:id/review_deposit_agreement', to: 'datasets#review_deposit_agreement'

  # controller method protected by cancan
  get '/datasets/:id/get_new_token', to: 'datasets#get_new_token', defaults: {format: 'json'}

  get '/datasets/:id/get_current_token', to: 'datasets#get_current_token', defaults: {format: 'json'}


  # authentication routes
  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match '/login', to: 'sessions#new', as: :login, via: [:get, :post]
  match '/logout', to: 'sessions#destroy', as: :logout, via: [:get, :post]

  match '/auth/failure', to: 'sessions#unauthorized', as: :unauthorized, via: [:get, :post]

  # route binary downloads
  get "/datafiles/:id/download", to: "datafiles#download"
  
  # direct display
  get '/datafiles/:id/display', to: "datafiles#display"

  # filepath
  get '/datafiles/:id/filepath', to: "datafiles#filepath", defaults: {format: 'json'}

  # viewtext
  get '/datafiles/:id/viewtext', to: 'datafiles#peek_text', defaults: {format: 'json'}

  # iiif_filepath
  get '/datafiles/:id/iiif_filepath', to: "datafiles#iiif_filepath", defaults: {format: 'json'}

  # create from box file select widget
  post "/datafiles/create_from_url", to: 'datafiles#create_from_url'

  #create from deckfile
  post "/datafiles/create_from_deckfile", to: 'datafiles#create_from_deckfile', defaults: {format: 'json'}

  # cancel box upload
  get "/datasets/:id/datafiles/:web_id/cancel_box_upload", to: 'datasets#cancel_box_upload', defaults: {format: 'json'}

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

  get "/metrics/dataset_downloads", to: 'metrics#dataset_downloads', defaults: {format: 'json'}

  get "/metrics/file_downloads", to: 'metrics#file_downloads', defaults: {format: 'json'}

  get "/metrics/datafiles_simple_list", to: "metrics#datafiles_simple_list"

  get "/metrics/datasets_csv", to: "metrics#datasets_csv"

  get "/metrics/datafiles_csv", to: "metrics#datafiles_csv"

  get "/metrics/related_materials_csv", to: "metrics#related_materials_csv"

  get "/metrics/archived_content_csv", to: "metrics#archived_content_csv"

  get "/metrics", to: 'metrics#index'

  get "/datasets/:id/download_metrics", to: 'datasets#download_metrics', defaults: {format: 'json'}

  post "/datasets/:id/download_deckfile", to: 'datasets#download_deckfile'

  get "/datasets/:id/request_review", to: 'datasets#request_review', defaults: {format: 'html'}

  get "/deckfiles/:id/download", to: 'deckfiles#download'

  # catch unknown routes, but ignore datatables and progress-job routes, which are generated by engines.
  match "/*a" => "errors#error404", :constraints => lambda{|req| req.path !~/progress-job/ && req.path !~ /datatables/ }, via: [ :get, :post, :patch, :delete ]

end
