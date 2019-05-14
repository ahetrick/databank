require 'open-uri'
require 'net/http'
require 'boxr'
require 'zip'
require 'zipline'
require 'json'
require 'pathname'

Placeholder_FacetRow = Struct.new(:value, :count)

class DatasetsController < ApplicationController

  protect_from_forgery except: [:cancel_box_upload, :validate_change2published]
  skip_before_action :verify_authenticity_token, :only => :validate_change2published
  before_action :set_dataset, only: [:show, :edit, :update, :destroy, :download_link, :download_endNote_XML, :download_plaintext_citation, :download_BibTeX, :download_RIS, :publish, :zip_and_download_selected, :request_review, :reserve_doi, :cancel_box_upload, :citation_text, :changelog, :serialization, :download_metrics, :confirmation_message, :get_current_token, :get_new_token, :send_to_medusa, :validate_change2published, :update_permissions, :add_review_request]

  @@num_box_ingest_deamons = 10

  # enable streaming responses
  include ActionController::Streaming

  # enable zipline
  include Zipline

  # GET /datasets
  # GET /datasets.json
  def index

    @datasets = Dataset.where(publication_state: [Databank::PublicationState::RELEASED, Databank::PublicationState::Embargo::FILE, Databank::PublicationState::TempSuppress::FILE, Databank::PublicationState::PermSuppress::FILE]).where(is_test: false) #used for json response

    @my_datasets_count = 0

    @search = nil
    search_get_facets = nil

    if params.has_key?(:per_page)
      per_page = params[:per_page].to_i
    else
      per_page = 25
    end

    if current_user&.role

      case current_user.role
      when "admin"

        search_get_facets = Dataset.search do
          without(:depositor, 'error')
          with(:is_most_recent_version, true)
          keywords(params[:q])
          facet(:license_code)
          facet(:funder_codes)
          facet(:depositor)
          facet(:subject_text)
          facet(:visibility_code)
          facet(:hold_state)
          facet(:datafile_extensions)
          facet(:publication_year)

        end

        @search = Dataset.search do

          without(:depositor, 'error')

          if params.has_key?('license_codes')
            any_of do
              params['license_codes'].each do |license_code|
                with :license_code, license_code
              end
            end
          end

          if params.has_key?('subjects')
            any_of do
              params['subjects'].each do |subject|
                with :subject_text, subject
              end
            end
          end

          if params.has_key?('depositors')
            any_of do
              params['depositors'].each do |depositor_netid|
                with :depositor_netid, depositor_netid
              end
            end
          end

          if params.has_key?('funder_codes')
            any_of do
              params['funder_codes'].each do |funder_code|
                with :funder_codes, funder_code
              end
            end
          end

          if params.has_key?('visibility_codes')
            any_of do
              params['visibility_codes'].each do |visibility_code|
                with :visibility_code, visibility_code
              end
            end
          end

          if params.has_key?('publication_years')
            any_of do
              params['publication_years'].each do |publication_year|
                with :publication_year, publication_year
              end
            end
          end

          keywords (params[:q])

          if params.has_key?('sort_by')
            if params['sort_by'] == 'sort_updated_asc'
              order_by :updated_at, :asc
            elsif params['sort_by'] == 'sort_released_asc'
              order_by :release_datetime, :asc
            elsif params['sort_by'] == 'sort_released_desc'
              order_by :release_datetime, :desc
            elsif params['sort_by'] == 'sort_ingested_asc'
              order_by :ingest_datetime, :asc
            elsif params['sort_by'] == 'sort_ingested_desc'
              order_by :ingest_datetime, :desc
            else
              order_by :updated_at, :desc
            end
          else
            order_by :updated_at, :desc
          end

          facet(:license_code)
          facet(:funder_codes)
          facet(:depositor)
          facet(:subject_text)
          facet(:visibility_code)
          facet(:hold_state)
          facet(:datafile_extensions)
          facet(:publication_year)

          paginate(page: params[:page] || 1, per_page: per_page)

        end

        # this makes a row for each category, even if the current search does not have any results in a category
        # these facets are only for admins

        search_get_facets.facet(:visibility_code).rows.each do |outer_row|
          has_this_row = false
          @search.facet(:visibility_code).rows.each do |inner_row|
            has_this_row = true if inner_row.value == outer_row.value
          end
          @search.facet(:visibility_code).rows << Placeholder_FacetRow.new(outer_row.value, 0) unless has_this_row
        end

        search_get_facets.facet(:depositor).rows.each do |outer_row|
          has_this_row = false

          @search.facet(:depositor).rows.each do |inner_row|
            has_this_row = true if inner_row.value == outer_row.value
          end
          @search.facet(:depositor).rows << Placeholder_FacetRow.new(outer_row.value, 0) unless has_this_row
        end


      when "depositor"

        search_get_my_facets = Dataset.search do

          all_of do
            without(:depositor, 'error')
            with :depositor_email, current_user.email
            with(:is_most_recent_version, true)
            with :is_test, false
            any_of do
              with :publication_state, Databank::PublicationState::DRAFT
              with :publication_state, Databank::PublicationState::RELEASED
              with :publication_state, Databank::PublicationState::Embargo::FILE
              with :publication_state, Databank::PublicationState::TempSuppress::FILE
              with :publication_state, Databank::PublicationState::TempSuppress::METADATA
              with :publication_state, Databank::PublicationState::PermSuppress::FILE
            end
          end
          keywords (params[:q])
          facet(:visibility_code)

        end

        search_get_facets = Dataset.search do

          all_of do
            without(:depositor, 'error')
            with(:is_test, false)
            any_of do
              with :depositor_email, current_user.email
              with :publication_state, Databank::PublicationState::RELEASED
              with :publication_state, Databank::PublicationState::Embargo::FILE
              with :publication_state, Databank::PublicationState::TempSuppress::FILE
              with :publication_state, Databank::PublicationState::PermSuppress::FILE
              all_of do
                with :depositor_email, current_user.email
                with :publication_state, Databank::PublicationState::TempSuppress::METADATA
              end
            end
          end

          keywords (params[:q])
          facet(:license_code)
          facet(:funder_codes)
          facet(:creator_names)
          facet(:subject_text)
          facet(:depositor)
          facet(:visibility_code)
          facet(:hold_state)
          facet(:datafile_extensions)
          facet(:publication_year)

        end

        @search = Dataset.search do

          all_of do
            without(:depositor, 'error')
            with :is_test, false
            any_of do
              with :depositor_email, current_user.email
              with :publication_state, Databank::PublicationState::RELEASED
              with :publication_state, Databank::PublicationState::Embargo::FILE
              with :publication_state, Databank::PublicationState::TempSuppress::FILE
              with :publication_state, Databank::PublicationState::PermSuppress::FILE
            end

            if params.has_key?('depositors')
              any_of do
                params['depositors'].each do |depositor_netid|
                  with :depositor_netid, depositor_netid
                end
              end
            end

            if params.has_key?('subjects')
              any_of do
                params['subjects'].each do |subject|
                  with :subject_text, subject
                end
              end
            end

            if params.has_key?('license_codes')
              any_of do
                params['license_codes'].each do |license_code|
                  with :license_code, license_code
                end
              end
            end

            if params.has_key?('funder_codes')
              any_of do
                params['funder_codes'].each do |funder_code|
                  with :funder_codes, funder_code
                end
              end
            end

            if params.has_key?('visibility_codes')
              any_of do
                params['visibility_codes'].each do |visibility_code|
                  with :visibility_code, visibility_code
                end
              end
            end

            if params.has_key?('publication_years')
              any_of do
                params['publication_years'].each do |publication_year|
                  with :publication_year, publication_year
                end
              end
            end

          end

          keywords (params[:q])
          if params.has_key?('sort_by')
            if params['sort_by'] == 'sort_updated_asc'
              order_by :updated_at, :asc
            elsif params['sort_by'] == 'sort_released_asc'
              order_by :release_datetime, :asc
            elsif params['sort_by'] == 'sort_released_desc'
              order_by :release_datetime, :desc
            elsif params['sort_by'] == 'sort_ingested_asc'
              order_by :ingest_datetime, :asc
            elsif params['sort_by'] == 'sort_ingested_desc'
              order_by :ingest_datetime, :desc
            else
              order_by :updated_at, :desc
            end
          else
            order_by :updated_at, :desc
          end
          facet(:license_code)
          facet(:funder_codes)
          facet(:subject_text)
          facet(:depositor)
          facet(:visibility_code)
          facet(:hold_state)
          facet(:datafile_extensions)
          facet(:publication_year)

          paginate(page: params[:page] || 1, per_page: per_page)

        end

        # this gets all categories for facets, even if current results do not have any instances

        search_get_my_facets.facet(:visibility_code).rows.each do |outer_row|
          has_this_row = false
          @search.facet(:visibility_code).rows.each do |inner_row|
            has_this_row = true if inner_row.value == outer_row.value
          end
          @search.facet(:visibility_code).rows << Placeholder_FacetRow.new(outer_row.value, 0) unless has_this_row
        end
      else

        search_get_facets = Dataset.search do
          all_of do
            without(:depositor, 'error')
            with(:is_most_recent_version, true)
            with :is_test, false
            without :hold_state, Databank::PublicationState::TempSuppress::METADATA
            any_of do
              with :publication_state, Databank::PublicationState::RELEASED
              with :publication_state, Databank::PublicationState::Embargo::FILE
              with :publication_state, Databank::PublicationState::TempSuppress::FILE
              with :publication_state, Databank::PublicationState::PermSuppress::FILE
            end
          end

          keywords (params[:q])
          facet(:license_code)
          facet(:funder_codes)
          facet(:creator_names)
          facet(:subject_text)
          facet(:depositor)
          facet(:visibility_code)
          facet(:hold_state)
          facet(:datafile_extensions)
          facet(:publication_year)
        end

        @search = Dataset.search do

          all_of do

            without(:depositor, 'error')
            with(:is_test, false)
            any_of do
              with :publication_state, Databank::PublicationState::RELEASED
              with :publication_state, Databank::PublicationState::Embargo::FILE
              with :publication_state, Databank::PublicationState::TempSuppress::FILE
            end

            if params.has_key?('depositors')
              any_of do
                params['depositors'].each do |depositor|
                  with :depositor, depositor
                end
              end
            end

            if params.has_key?('subjects')
              any_of do
                params['subjects'].each do |subject|
                  with :subject_text, subject
                end
              end
            end

            if params.has_key?('publication_years')
              any_of do
                params['publication_years'].each do |publication_year|
                  with :publication_year, publication_year
                end
              end
            end

            if params.has_key?('license_codes')
              any_of do
                params['license_codes'].each do |license_code|
                  with :license_code, license_code
                end
              end
            end

            if params.has_key?('funder_codes')
              any_of do
                params['funder_codes'].each do |funder_code|
                  with :funder_codes, funder_code
                end
              end
            end
          end

          keywords (params[:q])
          if params.has_key?('sort_by')
            if params['sort_by'] == 'sort_updated_asc'
              order_by :updated_at, :asc
            elsif params['sort_by'] == 'sort_released_asc'
              order_by :release_datetime, :asc
            elsif params['sort_by'] == 'sort_released_desc'
              order_by :release_datetime, :desc
            elsif params['sort_by'] == 'sort_ingested_asc'
              order_by :ingest_datetime, :asc
            elsif params['sort_by'] == 'sort_ingested_desc'
              order_by :ingest_datetime, :desc
            else
              order_by :updated_at, :desc
            end
          else
            order_by :updated_at, :desc
          end
          facet(:license_code)
          facet(:funder_codes)
          facet(:creator_names)
          facet(:subject_text)
          facet(:depositor)
          facet(:visibility_code)
          facet(:hold_state)
          facet(:datafile_extensions)
          facet(:publication_year)

          paginate(page: params[:page] || 1, per_page: per_page)

        end
      end

    else

      search_get_facets = Dataset.search do

        all_of do
          without(:depositor, 'error')
          with(:is_most_recent_version, true)
          with :is_test, false
          without :hold_state, Databank::PublicationState::TempSuppress::METADATA
          any_of do
            with :publication_state, Databank::PublicationState::RELEASED
            with :publication_state, Databank::PublicationState::Embargo::FILE
            with :publication_state, Databank::PublicationState::TempSuppress::FILE
          end
        end

        keywords (params[:q])
        facet(:license_code)
        facet(:funder_codes)
        facet(:subject_text)
        facet(:creator_names)
        facet(:depositor)
        facet(:visibility_code)
        facet(:hold_state)
        facet(:datafile_extensions)
        facet(:publication_year)
      end

      @search = Dataset.search do

        all_of do
          without(:depositor, 'error')
          with(:is_most_recent_version, true)
          with :is_test, false
          without :hold_state, Databank::PublicationState::TempSuppress::METADATA
          any_of do
            with :publication_state, Databank::PublicationState::RELEASED
            with :publication_state, Databank::PublicationState::Embargo::FILE
            with :publication_state, Databank::PublicationState::TempSuppress::FILE
          end


          if params.has_key?('license_codes')
            any_of do
              params['license_codes'].each do |license_code|
                with :license_code, license_code
              end
            end
          end

          if params.has_key?('publication_years')
            any_of do
              params['publication_years'].each do |publication_year|
                with :publication_year, publication_year
              end
            end
          end

          if params.has_key?('subjects')
            any_of do
              params['subjects'].each do |subject|
                with :subject_text, subject
              end
            end
          end

          if params.has_key?('funder_codes')
            any_of do
              params['funder_codes'].each do |funder_code|
                with :funder_codes, funder_code
              end
            end
          end
        end

        keywords (params[:q])
        if params.has_key?('sort_by')
          if params['sort_by'] == 'sort_updated_asc'
            order_by :updated_at, :asc
          elsif params['sort_by'] == 'sort_released_asc'
            order_by :release_datetime, :asc
          elsif params['sort_by'] == 'sort_released_desc'
            order_by :release_datetime, :desc
          elsif params['sort_by'] == 'sort_ingested_asc'
            order_by :ingest_datetime, :asc
          elsif params['sort_by'] == 'sort_ingested_desc'
            order_by :ingest_datetime, :desc
          else
            order_by :updated_at, :desc
          end
        else
          order_by :updated_at, :desc
        end
        facet(:license_code)
        facet(:funder_codes)
        facet(:creator_names)
        facet(:subject_text)
        facet(:depositor)
        facet(:visibility_code)
        facet(:hold_state)
        facet(:datafile_extensions)
        facet(:publication_year)

        paginate(page: params[:page] || 1, per_page: per_page)

      end

    end

    # this makes a row for each category, even if the current search does not have any results in a category
    # these facets are in all searchers

    search_get_facets.facet(:subject_text).rows.each do |outer_row|
      has_this_row = false
      @search.facet(:subject_text).rows.each do |inner_row|
        has_this_row = true if inner_row.value == outer_row.value
      end
      @search.facet(:subject_text).rows << Placeholder_FacetRow.new(outer_row.value, 0) unless has_this_row
    end

    search_get_facets.facet(:publication_year).rows.each do |outer_row|
      has_this_row = false
      @search.facet(:publication_year).rows.each do |inner_row|
        has_this_row = true if inner_row.value == outer_row.value
      end
      @search.facet(:publication_year).rows << Placeholder_FacetRow.new(outer_row.value, 0) unless has_this_row
    end

    search_get_facets.facet(:license_code).rows.each do |outer_row|
      has_this_row = false
      @search.facet(:license_code).rows.each do |inner_row|
        has_this_row = true if inner_row.value == outer_row.value
      end
      @search.facet(:license_code).rows << Placeholder_FacetRow.new(outer_row.value, 0) unless has_this_row
    end

    search_get_facets.facet(:funder_codes).rows.each do |outer_row|
      has_this_row = false
      @search.facet(:funder_codes).rows.each do |inner_row|
        has_this_row = true if inner_row.value == outer_row.value
      end
      @search.facet(:funder_codes).rows << Placeholder_FacetRow.new(outer_row.value, 0) unless has_this_row
    end

    @report = Indexable.citation_report(@search, request.original_url, current_user)

    if params.has_key?('download') && params['download'] == 'now'
      send_data @report, :filename => 'report.txt'
    end

  end

  # GET /datasets/1
  # GET /datasets/1.json
  def show

    authorize! :view, @dataset

    if Rails.env.aws_production?
      @datacite_fabrica_url = "https://doi.datacite.org/"
    else
      @datacite_fabrica_url = "https://doi.test.datacite.org/"
    end

    if params.has_key?(:selected_files)
      zip_and_download_selected
    elsif params.has_key?(:suppression_action)
      case params[:suppression_action]
      when "temporarily_suppress_files"
        temporarily_suppress_files
      when "temporarily_suppress_metadata"
        temporarily_suppress_metadata
      when "permanently_suppress_files"
        permanently_suppress_files
      when "permanently_suppress_metadata"
        permanently_suppress_metadata
      when "unsuppress"
        unsuppress
      when "suppress_changelog"
        suppress_changelog
      when "unsuppress_changelog"
        unsuppress_changelog
      end
    end

    @completion_check = Dataset.completion_check(@dataset, current_user)
    @review_request = ReviewRequest.new(dataset_key: @dataset.key, requested_at: Time.now)

    set_file_mode

  end

  def update_permissions

    #Rails.logger.warn params
    authorize! :manage, @dataset
    if params.has_key?(:permission_action)
      if params.has_key?(:can_read)
        if params[:can_read].include?(Databank::UserRole::NETWORK_REVIEWER)
          @dataset.update_attribute(:data_curation_network, true)
        else
          @dataset.update_attribute(:data_curation_network, false)
        end
      else
        @dataset.update_attribute(:data_curation_network, false)
      end
    end
    redirect_to "/datasets/#{@dataset.key}"
  end

  def cancel_box_upload

    Rails.logger.warn "cancel box upload params: #{params}"

    begin

      @job_id_string = "0"

      @datafile = Datafile.find_by_web_id(params[:web_id])

      if @datafile

        Rails.logger.warn "datafile found"

        if @datafile.job_id
          @job_id_string = @datafile.job_id.to_s
          job = Delayed::Job.where(id: @datafile.job_id).first
          if job && job.locked_by && !job.locked_by.empty?
            locked_by_text = job.locked_by.to_s

            pid = locked_by_text.split(":").last

            if !pid.empty?

              Process.kill('QUIT', Integer(pid))
              Dir.foreach(IDB_CONFIG[:delayed_job_pid_dir]) do |pid_filename|
                next if pid_filename == '.' or pid_filename == '..'
                next unless pid_filename.include? 'delayed_job'
                pid_filepath = "#{IDB_CONFIG[:delayed_job_pid_dir]}/#{pid_filename}"

                if File.exists?(pid_filepath)

                  file_contents = IO.read(pid_filepath)
                  if file_contents.include? pid.to_s
                    File.delete(pid_filepath)
                  end
                else
                  Rails.logger.warn "#{pid_filepath} did not exist"
                end

              end

              if Delayed::Job.all.count == 0
                system "cd #{Rails.root} && RAILS_ENV=#{::Rails.env} bin/delayed_job -n #{@@num_box_ingest_deamons} restart"
              else
                running_deamon_count = 0
                Dir.foreach(IDB_CONFIG[:delayed_job_pid_dir]) do |item|
                  next if item == '.' or item == '..'
                  next unless item.include? 'delayed_job'
                  running_deamon_count = running_deamon_count + 1
                end
              end
            elsif job
              if job.destroy && @datafile.destroy
                render json: {}, status: :ok
              else
                Rails.logger.warn("failed to destroy job or datafile")
                render json: {}, status: :unprocessable_entity
              end
            end
          else
            if @datafile.destroy
              render json: {}, status: :ok
            else
              Rails.logger.warn("there was no job, failed to destroy datafile")
              render json: {}, status: :unprocessable_entity
            end
          end

        else
          if @datafile.destroy
            render json: {}, status: :ok
          else
            Rails.logger.warn("there was no job_id, failed to destroy datafile")
            render json: {}, status: :unprocessable_entity
          end
        end

      else
        Rails.logger.warn "did not find datafile"
        render json: {}, status: :ok
      end

    rescue Errno::ESRCH => ex
      Rails.logger.warn ex.message
      render json: {}, status: :unprocessable_entity
    rescue Exception::StandardError => ex
      Rails.logger.warn ex.message
      render json: {}, status: :unprocessable_entity
    end
  end

  # GET /datasets/new
  def new
    authorize! :create, Dataset
    @dataset = Dataset.new
    @dataset.publication_state = Databank::PublicationState::DRAFT
    @dataset.creators.build
    @dataset.funders.build
    @dataset.related_materials.build
    set_file_mode
  end

  # GET /datasets/1/edit
  def edit
    if @dataset.org_creators && @dataset.org_creators == true
      @dataset.contributors.build unless @dataset.contributors.count > 0
    end
    @dataset.creators.build unless @dataset.creators.count > 0
    @dataset.funders.build unless @dataset.funders.count > 0
    @dataset.related_materials.build unless @dataset.related_materials.count > 0
    @completion_check = Dataset.completion_check(@dataset, current_user)
    @dataset.org_creators = @dataset.org_creators || false
    #set_license(@dataset)
    @publish_modal_msg = Dataset.publish_modal_msg(@dataset)
    if @dataset.deck_content?
      @dataset.deck_filepaths.each do |filepath|
        Deckfile.find_or_create_by!(path: filepath, dataset_id: @dataset.id)
      end
    end

    @dataset.embargo ||= Databank::PublicationState::Embargo::NONE

    @dataset.deckfiles.each do |deckfile|
      unless File.exists?(deckfile.path)
        deckfile.destroy
      end
    end
    @token = @dataset.current_token

    set_file_mode

    @funder_info_arr = FUNDER_INFO_ARR
    @license_info_arr = LICENSE_INFO_ARR

    @dataset.subject = Databank::Subject::NONE unless @dataset.subject
    authorize! :edit, @dataset

  end

  def get_new_token
    authorize! :edit, @dataset
    @token = @dataset.new_token
    render json: {token: @token.identifier, expires: @token.expires}
  end

  def get_current_token

    if @dataset.current_token && !@dataset.current_token.nil?
      @token = @dataset.current_token
      render json: {token: @token.identifier, expires: @token.expires}
    else
      @token = nil
      render json: {token: "token"}
    end

  end

  # POST /datasets
  # POST /datasets.json
  def create

    @dataset = Dataset.new(dataset_params)

    authorize! :edit, @dataset

    set_file_mode

    respond_to do |format|
      if @dataset.save
        format.html {redirect_to edit_dataset_path(@dataset.key)}
        format.json {render :edit, status: :created, location: edit_dataset_path(@dataset.key)}
      else
        format.html {render :new}
        format.json {render json: @dataset.errors, status: :unprocessable_entity}
      end
    end


  end

  # PATCH/PUT /datasets/1
  # PATCH/PUT /datasets/1.json
  def update

    authorize! :edit, @dataset

    old_publication_state = @dataset.publication_state

    old_creator_state = @dataset.org_creators || false

    Rails.logger.warn dataset_params

    @dataset.release_date ||= Date.current

    respond_to do |format|

      if @dataset.update(dataset_params)

        if dataset_params[:org_creators] == 'true' && old_creator_state == false

          # convert individual creators to additional contacts (contributors)
          @dataset.ind_creators_to_contributors
          params['context'] = 'continue_edit'

        elsif dataset_params[:org_creators] == 'false' && old_creator_state == true

          # delete all institutional creators
          @dataset.institutional_creators.delete_all

          # convert all additional contacts (contributors) to individual authors
          @dataset.contributors_to_ind_creators
          params['context'] = 'continue_edit'

        end

        if params.has_key?('context') && params['context'] == 'exit'

          if @dataset.publication_state == Databank::PublicationState::DRAFT
            format.html {redirect_to "/datasets?q=&#{URI.encode('depositors[]')}=#{current_user.name}&context=exit_draft"}
          else
            format.html {redirect_to "/datasets?q=&#{URI.encode('depositors[]')}=#{current_user.name}&context=exit_doi"}
          end

        elsif params.has_key?('context') && params['context'] == 'publish'

          if Databank::PublicationState::DRAFT == @dataset.publication_state
            raise "invalid publication state for update-and-publish"

            # only update complete datasets
          elsif Dataset.completion_check(@dataset, current_user) == 'ok'

            # set publication_state
            if @dataset.embargo && [Databank::PublicationState::Embargo::FILE, Databank::PublicationState::Embargo::METADATA].include?(@dataset.embargo)
              @dataset.publication_state = @dataset.embargo
            else
              @dataset.publication_state = Databank::PublicationState::RELEASED
            end

            if old_publication_state != Databank::PublicationState::RELEASED && @dataset.publication_state == Databank::PublicationState::RELEASED
              @dataset.release_date ||= Date.current
            end

            @dataset.save
            # send_dataset_to_medusa only sends metadata files unless old_publication_state is draft
            MedusaIngest.send_dataset_to_medusa(@dataset)

            if @dataset.is_test? || @dataset.update_doi
              format.html {redirect_to dataset_path(@dataset.key)}
              format.json {render :show, status: :ok, location: dataset_path(@dataset.key)}
            else
              format.html {redirect_to dataset_path(@dataset.key), notice: 'Error updating DataCite Metadata, details have been logged.'}
              format.json {render json: @dataset.errors, status: :unprocessable_entity}
            end

          else #this else means completion_check was not ok within publish context
            Rails.logger.warn Dataset.completion_check(@dataset, current_user)
            raise "Error: Cannot update published dataset with incomplete information."
          end

        elsif params.has_key?('context') && params['context'] == 'continue_edit'
          format.html {redirect_to edit_dataset_path(@dataset)}
          format.json {render :edit, status: :ok, location: edit_dataset_path(@dataset)}

        else #this else means context was not set to exit or publish - this is the normal draft update
          format.html {redirect_to dataset_path(@dataset.key)}
          format.json {render :show, status: :ok, location: dataset_path(@dataset.key)}
        end

      else #this else means update failed
        format.html {render :edit}
        format.json {render json: @dataset.errors, status: :unprocessable_entity}
      end

    end

  end

  def validate_change2published

    authorize! :edit, @dataset

    # Rails.logger.warn params.to_yaml

    if params.has_key?(:dataset) && (params[:dataset]).has_key?(:identifier) && params[:dataset][:identifer] != ""

      proposed_dataset = Dataset.create()
      if params[:dataset].has_key?(:title)
        proposed_dataset.title = params[:dataset][:title]
      end
      if params[:dataset].has_key?(:license)
        proposed_dataset.license = params[:dataset][:license]
      end

      has_license_file = false

      if @dataset.complete_datafiles.count > 0

        proposed_dataset.datafiles = Array.new

        @dataset.complete_datafiles.each do |datafile|
          if datafile.bytestream_name && ((datafile.bytestream_name).downcase == "license.txt")
            has_license_file = true
            temporary_datafile = Datafile.create(dataset_id: proposed_dataset.id)
            temporary_datafile.storage_root = 'draft'
            temporary_datafile.storage_key = 'license.txt'
            temporary_datafile.binary_name = 'license.txt'
            proposed_dataset.datafiles.push(temporary_datafile)
          end
        end

        unless has_license_file
          temporary_datafile = Datafile.create(dataset_id: proposed_dataset.id)
          temporary_datafile.storage_root = 'draft'
          temporary_datafile.storage_key = 'placeholder.txt'
          temporary_datafile.binary_name = 'placeholder.txt'
          proposed_dataset.datafiles.push(temporary_datafile)
        end

      end

      if params[:dataset].has_key?(:embargo)
        proposed_dataset.embargo = params[:dataset][:embargo]
      end

      if params[:dataset].has_key?(:release_date)
        proposed_dataset.release_date = params[:dataset][:release_date]
      end

      if params[:dataset].has_key?(:license)
        proposed_dataset.license = params[:dataset][:license]
      end

      if (params[:dataset]).has_key?(:creators_attributes)

        # Rails.logger.warn params[:dataset][:creators_attributes]

        proposed_dataset.creators = Array.new

        params[:dataset][:creators_attributes].each do |creator_params|
          creator_p = creator_params[1]
          temporary_creator = nil
          if creator_p.has_key?(:type_of)

            if creator_p[:type_of] == Databank::CreatorType::PERSON.to_s &&
                creator_p.has_key?(:family_name) && creator_p.has_key?(:given_name) &&
                creator_p[:family_name] != '' && creator_p[:given_name] != ''
              temporary_creator = Creator.create(dataset_id: proposed_dataset.id,
                                                 type_of: Databank::CreatorType::PERSON,
                                                 family_name: creator_p[:family_name],
                                                 given_name: creator_p[:given_name])


            elsif creator_p[:type_of] == Databank::CreatorType::INSTITUTION.to_s &&
                creator_p.has_key?(:institution_name) && creator_p[:institution_name] != ''
              temporary_creator = Creator.create(dataset_id: proposed_dataset.id,
                                                 type_of: Databank::CreatorType::INSTITUTION,
                                                 institution_name: creator_p[:institution_name])
            else
              Rails.logger.warn("invalid creator record: #{creator.to_yaml}")
              respond_to do |format|
                format.html {render json: {"message": "invalid creator record found"}} and return
                format.json {render json: {"message": "invalid creator record found"}, status: :unprocessable_entity} and return
              end
            end
          end

          if creator_p.has_key?(:email)
            temporary_creator.email = creator_p[:email]
          end
          if creator_p.has_key?(:is_contact)
            temporary_creator.is_contact = creator_p[:is_contact]
          end

          temporary_creator.save
          proposed_dataset.creators.push(temporary_creator)
        end

      end

      completion_check_message = Dataset.completion_check(proposed_dataset, current_user)

      proposed_dataset.destroy

      respond_to do |format|

        format.html {render :edit, alert: completion_check_message}
        format.json {render json: {"message": completion_check_message}}
      end

    else
      respond_to do |format|
        format.html {render json: {"message": "dataset not found"}}
        format.json {render json: {"message": "published dataset not found"}, status: :unprocessable_entity}
      end

    end

  end

  # DELETE /datasets/1
  # DELETE /datasets/1.json
  def destroy

    authorize! :edit, @dataset

    @dataset.destroy
    respond_to do |format|
      if current_user
        format.html {redirect_to "/datasets?q=&#{URI.encode('depositors[]')}=#{current_user.username}", notice: 'Dataset was successfully deleted.'}
      else
        format.html {redirect_to datasets_url, notice: 'Dataset was successfully deleted.'}
      end

      format.json {head :no_content}
    end
  end

  def pre_deposit
    @dataset = Dataset.new
    set_file_mode
  end

  def suppress_changelog

    authorize! :manage, @dataset

    @dataset.suppress_changelog = true
    respond_to do |format|
      if @dataset.save
        format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Dataset changelog has suppressed.]}
        format.json {render :show, status: :ok, location: dataset_path(@dataset.key)}
      else
        format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.]}
        format.json {render json: @dataset.errors, status: :unprocessable_entity}
      end
    end

  end

  def unsuppress_changelog

    authorize! :manage, @dataset

    @dataset.suppress_changelog = false
    respond_to do |format|
      if @dataset.save
        format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Dataset changelog has been unsuppressed.]}
        format.json {render :show, status: :ok, location: dataset_path(@dataset.key)}
      else
        format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.]}
        format.json {render json: @dataset.errors, status: :unprocessable_entity}
      end
    end

  end

  def temporarily_suppress_files

    authorize! :manage, @dataset

    @dataset.hold_state = Databank::PublicationState::TempSuppress::FILE

    respond_to do |format|
      if @dataset.save
        format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Dataset files have been temporarily suppressed.]}
        format.json {render :show, status: :ok, location: dataset_path(@dataset.key)}
      else
        format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.]}
        format.json {render json: @dataset.errors, status: :unprocessable_entity}
      end
    end

  end

  def temporarily_suppress_metadata

    authorize! :manage, @dataset

    @dataset.hold_state = Databank::PublicationState::TempSuppress::METADATA

    respond_to do |format|

      if @dataset.save

        if @dataset.update_doi
          format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Dataset metadata and files have been temporarily suppressed.]}
          format.json {render :show, status: :ok, location: dataset_path(@dataset.key)}
        else
          format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Dataset metadata and files have been temporarily suppressed in IDB, but DataCite was not updated.]}
          format.json {render :show, status: :ok, location: dataset_path(@dataset.key)}
        end
      else
        format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.]}
        format.json {render json: @dataset.errors, status: :unprocessable_entity}

      end
    end

  end

  def unsuppress

    authorize! :manage, @dataset

    @dataset.hold_state = Databank::PublicationState::TempSuppress::NONE

    respond_to do |format|

      if @dataset.save

        if @dataset.update_doi
          format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Dataset has been unsuppressed.]}
          format.json {render :show, status: :ok, location: dataset_path(@dataset.key)}
        else
          format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Dataset has been unsuppressed in IDB, but DataCite was not updated.]}
          format.json {render :show, status: :ok, location: dataset_path(@dataset.key)}
        end
      else
        format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.]}
        format.json {render json: @dataset.errors, status: :unprocessable_entity}

      end
    end
  end

  def permanently_suppress_files

    authorize! :manage, @dataset

    @dataset.publication_state = Databank::PublicationState::PermSuppress::FILE
    @dataset.hold_state = Databank::PublicationState::PermSuppress::FILE
    @dataset.tombstone_date = Date.current

    respond_to do |format|

      if @dataset.save
        format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Dataset files have been permanently supressed.]}
        format.json {render :show, status: :ok, location: dataset_path(@dataset.key)}
      else
        format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.]}
        format.json {render json: @dataset.errors, status: :unprocessable_entity}
      end

    end

  end

  def permanently_suppress_metadata

    authorize! :manage, @dataset

    @dataset.hold_state = Databank::PublicationState::PermSuppress::METADATA
    @dataset.publication_state = Databank::PublicationState::PermSuppress::METADATA
    @dataset.tombstone_date = Date.current.iso8601
    @dataset.embargo = Databank::PublicationState::Embargo::NONE
    @dataset.save

    if @dataset.hide_doi
      format.html {redirect_to dataset_path(@dataset.key), notice: %Q[Dataset has been permanently supressed in Illinois Data Bank and DataCite.]}
      format.json {render :show, status: :ok, location: dataset_path(@dataset.key)}
    else
      format.html {redirect_to dataset_path(@dataset.key), alert: %Q[Dataset metadata and files have been permenantly suppressed in Illinois Data Bank, but DataCite has not been updated.]}
      format.json {render :show, status: :unprocessable_entity, location: dataset_path(@dataset.key)}
    end

  end

  def request_review

    params = Hash.new
    params['help-name'] = @dataset.depositor_name
    params['help-email'] = @dataset.depositor_email
    params['help-topic'] = 'Dataset Consultation'
    params['help-dataset'] = "#{request.base_url}#{dataset_path(@dataset.key)}"
    params['help-message'] = "Pre-deposit review request"

    if @dataset.is_test?
      shoulder = IDB_CONFIG[:test_datacite_shoulder]
    else
      shoulder = IDB_CONFIG[:datacite_shoulder]
    end

    if !@dataset.identifier || @dataset.identifier == ''
      @dataset.identifier = "#{shoulder}#{@dataset.key}_V1"
    end

    ReviewRequest.create(dataset_key: @dataset.key, requested_at: Time.now)

    help_request = DatabankMailer.contact_help(params)
    help_request.deliver_now

    respond_to do |format|

      if @dataset.save
        format.html {redirect_to dataset_path(@dataset.key), notice: "Your request has been submitted. In the meantime, your DOI has been reserved and you can give your citation to your publisher as a placeholder:  #{@dataset.plain_text_citation}"}
        format.json {render json: {status: :ok}, content_type: request.format, :layout => false}
      else
        format.html {redirect_to dataset_path(@dataset.key), notice: "Your request has been submitted."}
        format.json {render json: {status: :ok}, content_type: request.format, :layout => false}
      end

    end

  end

  # publishing in IDB means interacting with DataCite and Medusa
  def publish

    authorize! :edit, @dataset

    publish_attempt_result = @dataset.publish(current_user)

    respond_to do |format|
      if publish_attempt_result[:status] == :ok && @dataset.save
        format.html {redirect_to dataset_path(@dataset.key), notice: Dataset.deposit_confirmation_notice(publish_attempt_result[:old_publication_state], @dataset)}
        format.json {render json: :show, status: :ok, location: dataset_path(@dataset.key)}
      elsif publish_attempt_result[:status] == :error_occurred
        format.html {redirect_to dataset_path(@dataset.key), notice: publish_attempt_result[:error_text]}
        format.json {render json: {status: :unprocessable_entity}, content_type: request.format, :layout => false}
      else
        Rails.logger.warn publish_attempt_result.to_yaml
        format.html {redirect_to dataset_path(@dataset.key), notice: 'Error in publishing dataset has been logged for review by the Research Data Service.'}
        format.json {render json: {status: :unprocessable_entity}, content_type: request.format, :layout => false}
      end
    end

  end

  def send_to_medusa

    authorize! :edit, @dataset

    ingest_record_url = MedusaIngest.send_dataset_to_medusa(@dataset)
    render json: {result: ingest_record_url || "error", status: :ok}
  end

  def review_deposit_agreement
    if params.has_key?(:id)
      set_dataset
    end

    if @dataset
      if Application.storage_manager.draft_root.exist?(@dataset.draft_agreement_key)
        @agreement_text = Application.storage_manager.draft_root.as_string(@dataset.draft_agreement_key)
      elsif Application.storage_manager.medusa_root.exist?(@dataset.medusa_agreement_key)
        @agreement_text = Application.storage_manager.medusa_root.as_string(@dataset.medusa_agreement_key)
      else
        raise("Deposit agreement not found for dataset #{@dataset.key}.")
      end
    else
      @agreement_text = File.read(Rails.root.join("public", "deposit_agreement.txt"))
    end

  end

  def zip_and_download_selected

    if @dataset.identifier && !@dataset.identifier.empty? && @dataset.publication_state != Databank::PublicationState::DRAFT
      @dataset.complete_datafiles.each do |datafile|

        if params[:selected_files].include?(datafile.web_id)
          datafile.record_download(request.remote_ip)
        end
      end
      file_name = "DOI-#{@dataset.identifier}".parameterize + ".zip"
    else
      file_name = "datafiles.zip"
    end

    datafiles = Datafile.where(web_id: params[:selected_files])

    datafiles = Array.new

    web_ids = params[:selected_files]

    web_ids.each do |web_id|

      df = Datafile.find_by_web_id(web_id)
      if df
        datafiles.append([df.bytestream_path, df.bytestream_name])
      end

    end

    file_mappings = datafiles
                        .lazy # Lazy allows us to begin sending the download immediately instead of waiting to download everything
                        .map {|url, path| [open(url), path]}
    zipline(file_mappings, file_name)

  end

  # precondition: all valid web_ids in medusa
  def download_link

    return_hash = Hash.new

    if params.has_key?('web_ids')
      web_ids_str = params['web_ids']
      web_ids = web_ids_str.split('~')

      if !web_ids.respond_to?(:count) || web_ids.count < 1
        return_hash["status"] = "error"
        return_hash["error"] = "no web_ids after split"
        render(json: return_hash.to_json, content_type: request.format, :layout => false)
      end

      web_ids.each(&:strip!)

      path_arr = Array.new

      parametrized_doi = @dataset.identifier.parameterize

      download_hash = DownloaderClient.datafiles_download_hash(@dataset, web_ids, "DOI-#{parametrized_doi}")
      if download_hash
        if download_hash['status'] == 'ok'
          web_ids.each do |web_id|
            datafile = Datafile.find_by_web_id(web_id)
            if datafile
              #Rails.logger.warn "recording datafile download for web_id #{web_id}"
              datafile.record_download(request.remote_ip)
            else
              #Rails.logger.warn "did not find datafile for web_id #{web_id}"
            end
          end

          return_hash["status"] = "ok"
          return_hash["url"] = download_hash['download_url']
          return_hash["total_size"] = download_hash['total_size']
        else
          return_hash["status"] = "error"
          return_hash["error"] = download_hash["error"]
        end
      else
        return_hash["status"] = "error"
        return_hash["error"] = "nil zip link returned"
      end
      render(json: return_hash.to_json, content_type: request.format, :layout => false)
    else
      return_hash["status"] = "error"
      return_hash["error"] = "no web_ids in request"
      render(json: return_hash.to_json, content_type: request.format, :layout => false)
    end

  end

  def confirmation_message()

    # Rails.logger.warn "params inside confirmation messaage: #{params.to_yaml}"

    proposed_dataset = @dataset
    old_embargo_state = @dataset.embargo || Databank::PublicationState::Embargo::NONE
    new_embargo_state = @dataset.embargo || Databank::PublicationState::Embargo::NONE
    #old_publication_state = @dataset.publication_state
    #new_publication_state = @dataset.publication_state

    if params.has_key?('new_embargo_state')

      # Rails.logger.warn "new_embargo state detected: #{params['new_embargo_state']}"

      case params['new_embargo_state']
      when Databank::PublicationState::Embargo::FILE
        new_embargo_state = Databank::PublicationState::Embargo::FILE

        #new_publication_state = Databank::PublicationState::Embargo::FILE
      when Databank::PublicationState::Embargo::METADATA
        new_embargo_state = Databank::PublicationState::Embargo::METADATA
        #new_publication_state = Databank::PublicationState::Embargo::METADATA
      else
        new_embargo_state = Databank::PublicationState::Embargo::NONE
        #new_publication_state = Databank::PublicationState::RELEASED
      end

      proposed_dataset.embargo = new_embargo_state
      proposed_dataset.release_date = params['release_date'] || @dataset.release_date

      #proposed_dataset.publication_state = new_publication_state

    end

    # Rails.logger.warn "proposed dataset just before detection"
    # Rails.logger.warn proposed_dataset.to_yaml
    render json: {status: :ok, message: Dataset.publish_modal_msg(proposed_dataset)}

  end

  def download_endNote_XML

    t = Tempfile.new("#{@dataset.key}_endNote")

    doc = Nokogiri::XML::Document.parse(%Q(<?xml version="1.0" encoding="UTF-8"?><xml></xml>))

    recordsNode = doc.create_element('records')
    recordsNode.parent = doc.root

    recordNode = doc.create_element('record')
    recordNode.parent = recordsNode


    reftypeNode = doc.create_element('ref-type')
    reftypeNode.parent = recordNode
    reftypeNode['name'] = 'Online Database'
    reftypeNode.content = '45'

    contributorsNode = doc.create_element('contributors')
    contributorsNode.parent = recordNode

    authorsNode = doc.create_element('authors')
    authorsNode.parent = contributorsNode


    authorNode = doc.create_element('author')
    authorNode.content = @dataset.creator_list
    authorNode.parent = authorsNode

    titlesNode = doc.create_element('titles')
    titlesNode.parent = recordNode

    titleNode = doc.create_element('title')
    titleNode.parent = titlesNode
    titleNode.content = @dataset.title

    datesNode = doc.create_element('dates')
    datesNode.parent = recordNode

    yearNode = doc.create_element('year')
    yearNode.content = @dataset.publication_year
    yearNode.parent = datesNode

    publisherNode = doc.create_element('publisher')
    publisherNode.parent = recordNode
    publisherNode.content = @dataset.publisher

    urlsNode = doc.create_element('urls')
    urlsNode.parent = recordNode

    relatedurlsNode = doc.create_element('related-urls')
    relatedurlsNode.parent = urlsNode

    if @dataset.identifier
      urlNode = doc.create_element('url')
      urlNode.parent = relatedurlsNode
      urlNode.content = "#{IDB_CONFIG[:datacite_url_prefix]}/#{@dataset.identifier}"
    end

    electronicNode = doc.create_element('electronic-resource-num')
    electronicNode.parent = recordNode
    electronicNode.content = @dataset.identifier

    t.write(doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML).strip.sub("\n", ''))

    send_file t.path, :type => 'application/xml',
              :disposition => 'attachment',
              :filename => "DOI-#{@dataset.identifier}.xml"

    t.close

  end

  def download_RIS

    if !@dataset.identifier
      @dataset.identifier = @dataset.key
    end

    t = Tempfile.new("#{@dataset.key}_datafiles")

    t.write(%Q[Provider: Illinois Data Bank\nContent: text/plain; charset=%Q[us-ascii]\nTY  - DATA\nT1  - #{@dataset.title}\n])

    t.write(%Q[DO  - #{@dataset.identifier}\nPY  - #{@dataset.publication_year}\nUR  - #{IDB_CONFIG[:datacite_url_prefix]}/#{@dataset.identifier}\nPB  - #{@dataset.publisher}\nER  - ])

    if !@dataset.identifier
      @dataset.identifer = @dataset.key
    end

    send_file t.path, :type => 'application/x-Research-Info-Systems',
              :disposition => 'attachment',
              :filename => "DOI-#{@dataset.identifier}.ris"
    t.close
  end

  def download_plaintext_citation

    t = Tempfile.new("#{@dataset.key}_citation")

    t.write(%Q[#{@dataset.plain_text_citation}\n])

    send_file t.path, :type => 'text/plain',
              :disposition => 'attachment',
              :filename => "DOI-#{@dataset.identifier}.txt"

    t.close

  end


  def download_BibTeX

    if !@dataset.identifier
      @dataset.identifier = @dataset.key
    end

    t = Tempfile.new("#{@dataset.key}_endNote")
    citekey = SecureRandom.uuid

    t.write("@data{#{citekey},\ndoi = {#{@dataset.identifier}},\nurl = {#{IDB_CONFIG[:datacite_url_prefix]}/#{@dataset.identifier}},\nauthor = {#{@dataset.creator_list}},\npublisher = {#{@dataset.publisher}},\ntitle = {#{@dataset.title} ﻿},\nyear = {#{@dataset.publication_year}}
}")

    send_file t.path, :type => 'application/application/x-bibtex',
              :disposition => 'attachment',
              :filename => "DOI-#{@dataset.identifier}.bib"

    t.close

  end

  def citation_text
    render json: {"citation" => @dataset.plain_text_citation}
  end

  def serialization

    @serialization_json = self.recovery_serialization.to_json
    respond_to do |format|
      format.html
      format.json
    end
  end

  def download_metrics
  end

  def download_deckfile
    # Rails.logger.warn params.to_yaml
    render :edit
  end

  def recordtext
  end

  def temporary_error
  end

  def medusa_info_list
    @datasets = Dataset.all
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_dataset

    @dataset = Dataset.find_by_key(params[:id])
    unless @dataset
      @dataset = Dataset.find(params[:dataset_id])
    end
    raise ActiveRecord::RecordNotFound unless @dataset
  end

  def set_file_mode

    #Databank::Application.file_mode = Databank::FileMode::READ_ONLY

    Databank::Application.file_mode = Databank::FileMode::WRITE_READ

    #if IDB_CONFIG[:aws][:s3_mode] == false

    #  mount_path = (Pathname.new(IDB_CONFIG[:storage_mount]).realpath).to_s.strip
    #  read_only_path = (IDB_CONFIG[:read_only_realpath]).to_s.strip

    #  if (mount_path.casecmp(read_only_path) == 0)
    #    Databank::Application.file_mode = Databank::FileMode::READ_ONLY
    #  end

    #end

  end

  # Never trust parameters from the scary internet, only allow the white list through.
  # def dataset_params

  def dataset_params
    params.require(:dataset).permit(:medusa_dataset_dir, :title, :identifier, :publisher, :license, :key, :description, :keywords, :depositor_email, :depositor_name, :corresponding_creator_name, :corresponding_creator_email, :embargo, :complete, :search, :dataset_version, :release_date, :is_test, :is_import, :audit_id, :removed_private, :have_permission, :agree, :web_ids, :org_creators, :version_comment, :subject,
                                    datafiles_attributes: [:datafile, :description, :attachment, :dataset_id, :id, :_destroy, :_update, :audit_id],
                                    creators_attributes: [:dataset_id, :family_name, :given_name, :institution_name, :identifier, :identifier_scheme, :type_of, :row_position, :is_contact, :email, :id, :_destroy, :_update, :audit_id],
                                    contributors_attributes: [:dataset_id, :family_name, :given_name, :identifier, :identifier_scheme, :type_of, :row_position, :is_contact, :email, :id, :_destroy, :_update, :audit_id],
                                    funders_attributes: [:dataset_id, :code, :name, :identifier, :identifier_scheme, :grant, :id, :_destroy, :_update, :audit_id],
                                    related_materials_attributes: [:material_type, :selected_type, :availability, :link, :uri, :uri_type, :citation, :datacite_list, :dataset_id, :_destroy, :id, :_update, :audit_id],
                                    deckfiles_attributes: [:disposition, :remove, :path, :dataset_id, :id])
  end


end
