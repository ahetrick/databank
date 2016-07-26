require 'open-uri'
require 'net/http'
require 'boxr'
require 'zipruby'
require 'json'
require 'pathname'

class DatasetsController < ApplicationController
  protect_from_forgery except: [:cancel_box_upload, :validate_change2published]
  skip_before_filter :verify_authenticity_token, :only => :validate_change2published

  load_resource :find_by => :key
  authorize_resource
  skip_load_and_authorize_resource :only => :download_endNote_XML
  skip_load_and_authorize_resource :only => :download_plaintext_citation
  skip_load_and_authorize_resource :only => :download_BibTeX
  skip_load_and_authorize_resource :only => :download_RIS
  skip_load_and_authorize_resource :only => :stream_file
  skip_load_and_authorize_resource :only => :show_agreement
  skip_load_and_authorize_resource :only => :review_deposit_agreement
  skip_load_and_authorize_resource :only => :datacite_record
  skip_load_and_authorize_resource :only => :download_link
  skip_load_and_authorize_resource :only => :pre_deposit
  skip_load_and_authorize_resource :only => :confirmation_message
  skip_load_and_authorize_resource :only => :validate_change2published

  before_action :set_dataset, only: [:show, :edit, :update, :destroy, :download_link, :download_endNote_XML, :download_plaintext_citation, :download_BibTeX, :download_RIS, :publish, :zip_and_download_selected, :cancel_box_upload, :citation_text, :changelog, :serialization, :download_metrics, :confirmation_message]

  @@num_box_ingest_deamons = 10

  # enable streaming responses
  include ActionController::Streaming
  # enable zipline
  # include Zipline

  # GET /datasets
  # GET /datasets.json
  def index

    @datasets = nil #used for json response
    @datatable = nil

    if current_user && current_user.role
      case current_user.role
        when "admin"
          @datasets = Dataset.order(updated_at: :desc)
          @datatable = Effective::Datatables::CuratorDatasets.new
        when "depositor"
          if params.has_key?('depositor')
            @datasets = Dataset.where.not(publication_state: Databank::PublicationState::PermSuppress::METADATA).where("depositor_email = ?", current_user.email).order(updated_at: :desc)
            @datatable = Effective::Datatables::MyDatasets.new(current_email: current_user.email)
          else
            @datasets = Dataset.where.not(publication_state: Databank::PublicationState::PermSuppress::METADATA).where("publication_state = ? OR publication_state = ? OR depositor_email = ?", Databank::PublicationState::Embargo::FILE, Databank::PublicationState::RELEASED, current_user.email).order(updated_at: :desc)
            @datatable = Effective::Datatables::DepositorDatasets.new(current_email: current_user.email, current_name: current_user.name)
          end
        else
          @datasets = Dataset.where(publication_state: [Databank::PublicationState::RELEASED, Databank::PublicationState::Embargo::FILE, Databank::PublicationState::PermSuppress::FILE]).order(updated_at: :desc)
          @datatable = Effective::Datatables::GuestDatasets.new
      end
    else
      @datasets = Dataset.where(publication_state: [Databank::PublicationState::RELEASED, Databank::PublicationState::Embargo::FILE, Databank::PublicationState::PermSuppress::FILE]).order(updated_at: :desc)
      @datatable = Effective::Datatables::GuestDatasets.new

    end

  end

  # GET /datasets/1
  # GET /datasets/1.json
  def show

    if params.has_key?(:selected_files)
      zip_and_download_selected
    end

    if params.has_key?(:suppression_action)
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


    @all_in_medusa = true
    @total_files_size = 0
    @local_zip_max_size = 750000000
    @single_download_ok = true

    @dataset.datafiles.each do |df|

      if df.bytestream_size > 500000000
        @single_download_ok = false
      end

      @total_files_size = @total_files_size + df.bytestream_size
      if !df.medusa_path || df.medusa_path == ""
        # Rails.logger.warn "no path found for #{df.to_yaml}"
        @all_in_medusa = false
      end

      set_file_mode

    end


    @completion_check = Dataset.completion_check(@dataset, current_user)

    @changetable = nil

    changes = Audited::Adapters::ActiveRecord::Audit.where("(auditable_type=? AND auditable_id=?) OR (associated_id=?)", 'Dataset', @dataset.id, @dataset.id)
    # Rails.logger.warn "changes: #{changes.to_yaml}"

    if changes && changes.count > 0 && @dataset.publication_state != Databank::PublicationState::DRAFT
      @changetable = Effective::Datatables::DatasetChanges.new(dataset_id: @dataset.id)
    end

    # Rails.logger.warn "changetable: #{@changetable.to_yaml}"

    @publish_modal_msg = Dataset.publish_modal_msg(@dataset)

    set_license(@dataset)

  end

  def cancel_box_upload

    @job_id_string = "0"

    @datafile = Datafile.find_by_web_id(params[:web_id])

    if @datafile
      if @datafile.job_id
        @job_id_string = @datafile.job_id.to_s
        job = Delayed::Job.where(id: @datafile.job_id).first
        if job && job.locked_by && !job.locked_by.empty?
          locked_by_text = job.locked_by.to_s

          pid = locked_by_text.split(":").last

          if !pid.empty?

            begin

              Process.kill('QUIT', Integer(pid))
              Dir.foreach(IDB_CONFIG[:delayed_job_pid_dir]) do |item|
                next if item == '.' or item == '..'
                next unless item.include? 'delayed_job'
                file_contents = IO.read(item)
                pid_file_path = item.path
                if file_contents.include? pid.to_s
                  File.delete(pid_file_path)
                end
              end

            rescue Errno::ESRCH => ex
              Rails.logger.warn ex.message
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
          job.destroy
          @datafile.destroy

        end
      else
        @datafile.destroy
      end

    end
  end


  # GET /datasets/new
  def new
    @dataset = Dataset.new
    @dataset.publication_state = Databank::PublicationState::DRAFT
    @dataset.creators.build
    @dataset.funders.build
    @dataset.related_materials.build
    set_file_mode
  end

  # GET /datasets/1/edit
  def edit
    @dataset.creators.build unless @dataset.creators.count > 0
    @dataset.funders.build unless @dataset.funders.count > 0
    @dataset.related_materials.build unless @dataset.related_materials.count > 0
    @completion_check = Dataset.completion_check(@dataset, current_user)
    set_license(@dataset)
    @publish_modal_msg = Dataset.publish_modal_msg(@dataset)
    if @dataset.has_deck_content
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
    set_file_mode

  end

  # POST /datasets
  # POST /datasets.json
  def create

    @dataset = Dataset.new(dataset_params)

    respond_to do |format|
      if @dataset.save
        format.html { redirect_to edit_dataset_path(@dataset.key) }
        format.json { render :edit, status: :created, location: edit_dataset_path(@dataset.key) }
      else
        format.html { render :new }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end
    set_file_mode

  end

  # PATCH/PUT /datasets/1
  # PATCH/PUT /datasets/1.json
  def update

    old_publication_state = @dataset.publication_state
    @dataset.release_date ||= Date.current

    respond_to do |format|

      if @dataset.update(dataset_params)

        if params.has_key?('context') && params['context'] == 'exit'

          if @dataset.publication_state == Databank::PublicationState::DRAFT
            format.html { redirect_to "/datasets?depositor=#{current_user.name}&context=exit_draft" }
          else
            format.html { redirect_to "/datasets?depositor=#{current_user.name}&context=exit_doi" }
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
              @dataset.release_date = Date.current
            end

            @dataset.save
            # send_dataset_to_medusa only sends metadata files unless old_publication_state is draft
            MedusaIngest.send_dataset_to_medusa(@dataset, old_publication_state)
            Dataset.update_datacite_metadata(@dataset, current_user)

            format.html { redirect_to dataset_path(@dataset.key), notice: "Dataset successfully updated." }
            format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }

          else #this else means completion_check was not ok within publish context
            Rails.logger.warn Dataset.completion_check(@dataset, current_user)
            raise "Error: Cannot update published dataset with incomplete information."
          end

        else #this else means context was not set to exit or publish - this is the normal draft update
          format.html { redirect_to dataset_path(@dataset.key)}
          format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
        end

      else #this else means update failed
        format.html { render :edit }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end

    end

  end

  def validate_change2published

    set_dataset

    raise "dataset not found" unless @dataset

    Rails.logger.warn params.to_yaml

    if params.has_key?(:dataset) && (params[:dataset]).has_key?(:identifier) && params[:dataset][:identifer] != ""

      proposed_dataset = Dataset.create()
      if params[:dataset].has_key?(:title)
        proposed_dataset.title = params[:dataset][:title]
      end
      if params[:dataset].has_key?(:license)
        proposed_dataset.license = params[:dataset][:license]
      end

      has_license_file = false

      if @dataset.datafiles
        @dataset.datafiles.each do |datafile|
          if datafile.bytestream_name && ((datafile.bytestream_name).downcase == "license.txt")
            has_license_file = true
            temporary_datafile = Datafile.create(dataset_id: proposed_dataset.id)
            temporary_datafile.binary = Pathname.new(datafile.bytestream_path).open()
            temporary_datafile.save
          end
        end

        unless has_license_file
          temporary_datafile = Datafile.create(dataset_id: proposed_dataset.id)
          temporary_datafile.binary = Pathname.new("#{IDB_CONFIG[:agreements_root_path]}/new/deposit_agreement.txt").open()
          temporary_datafile.save
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

          # Rails.logger.warn "inside create temporary creator"
          # Rails.logger.warn "creator_p has a family name key? #{creator_p.has_key?(:family_name)}"
          if creator_p.has_key?(:family_name)
            temporary_creator = Creator.create(dataset_id: proposed_dataset.id, family_name: creator_p[:family_name])

          end
          if creator_p.has_key?(:given_name)
            temporary_creator.given_name = creator_p[:given_name]
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

        format.html { render :edit, alert: completion_check_message }
        format.json { render json: {"message":completion_check_message}}
      end

    else
      respond_to do |format|
        format.html { render json: {"message":"dataset not found"} }
        format.json { render json: {"message":"published dataset not found"}, status: :unprocessable_entity }
      end

    end

  end

  # DELETE /datasets/1
  # DELETE /datasets/1.json
  def destroy

    @dataset.destroy
    respond_to do |format|
      if current_user
        format.html { redirect_to "/datasets?depositor=#{current_user.name}", notice: 'Dataset was successfully deleted.' }
      else
        format.html { redirect_to datasets_url, notice: 'Dataset was successfully deleted.' }
      end

      format.json { head :no_content }
    end
  end

  def pre_deposit
    @dataset = Dataset.new
    set_file_mode
  end

  def suppress_changelog
    @dataset.suppress_changelog = true
    respond_to do |format|
      if @dataset.save
        format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset changelog has suppressed.] }
        format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
      else
        format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.] }
        format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
      end
    end
  end

  def unsuppress_changelog
    @dataset.suppress_changelog = false
    respond_to do |format|
      if @dataset.save
        format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset changelog has been unsuppressed.] }
        format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
      else
        format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.] }
        format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
      end
    end
  end


  def temporarily_suppress_files

    @dataset.hold_state = Databank::PublicationState::TempSuppress::FILE

    respond_to do |format|
      if @dataset.save
        format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset files have been temporarily suppressed.] }
        format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
      else
        format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.] }
        format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
      end
    end

  end

  def temporarily_suppress_metadata

    @dataset.hold_state = Databank::PublicationState::TempSuppress::METADATA

    respond_to do |format|

      if @dataset.save

        if Dataset.update_datacite_metadata(@dataset, current_user)
          @dataset.save
          format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset metadata and files have been temporarily suppressed.] }
          format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
        else
          format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset metadata and files have been temporarily suppressed in IDB, but DataCite was not updated.] }
          format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
        end
      else
        format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.] }
        format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }

      end
    end

  end

  def unsuppress
    @dataset.hold_state = nil

    respond_to do |format|

      if @dataset.save

        if Dataset.update_datacite_metadata(@dataset, current_user)
          @dataset.save
          format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset has been unsuppressed.] }
          format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
        else
          format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset has been unsuppressed in IDB, but DataCite was not updated.] }
          format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
        end
      else
        format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.] }
        format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }

      end
    end
  end

  def permanently_suppress_files

    @dataset.publication_state = Databank::PublicationState::PermSuppress::FILE
    @dataset.tombstone_date = Date.current

    respond_to do |format|

      if @dataset.save
        format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset files have been permanently supressed.] }
        format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
      else
        format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.] }
        format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
      end

    end

  end


  def permanently_suppress_metadata

    old_state = @dataset.publication_state
    @dataset.publication_state = Databank::PublicationState::PermSuppress::METADATA
    @dataset.tombstone_date = Date.current.iso8601

    if old_state == Databank::PublicationState::Embargo::METADATA
      respond_to do |format|

        if @dataset.save
          if Dataset.delete_datacite_id(@dataset, current_user)
            @dataset.save
            format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Reserved DOI has been deleted and all files have been permanently supressed.] }
            format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
          else
            format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset metadata and files have been permenantly suppressed in IDB, but DataCite has not been updated.] }
            format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
          end
        else
          format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.] }
          format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
        end
      end

    else
      respond_to do |format|

        if @dataset.save
          if Dataset.update_datacite_metadata(@dataset, current_user)
            format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset metadata and all files have been permanently supressed.] }
            format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
          else
            format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset metadata and files have been permanently supressed in IDB, but DataCite has not been updated.] }
            format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
          end
        else
          format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.] }
          format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
        end

      end
    end
  end

  # publishing in IDB means interacting with DataCite and Medusa
  def publish

    old_publication_state = @dataset.publication_state

    @dataset.release_date ||= Date.current

    # only publish complete datasets
    if Dataset.completion_check(@dataset, current_user) == 'ok'

      @dataset.complete = true

      # set publication_state
      if @dataset.embargo && [Databank::PublicationState::Embargo::FILE, Databank::PublicationState::Embargo::METADATA].include?(@dataset.embargo)
        @dataset.publication_state = @dataset.embargo
      else
        @dataset.publication_state = Databank::PublicationState::RELEASED
      end

      if old_publication_state != Databank::PublicationState::RELEASED && @dataset.publication_state == Databank::PublicationState::RELEASED
        @dataset.release_date = Date.current
      end

    else
      @dataset.complete = false
    end

    respond_to do |format|
      if @dataset.complete?

        # ensure identifier, update publication_state, interact with DataCite and Medusa
        if ((old_publication_state != Databank::PublicationState::DRAFT) && (!@dataset.identifier || @dataset.identifier == ''))
          raise "Missing identifier for dataset that is not a draft. Dataset: #{@dataset.key}"

        elsif old_publication_state == Databank::PublicationState::DRAFT && !@dataset.is_import

          #remove deck directory, if it exists
          if File.exists?(@dataset.deck_location)
            FileUtils.rm_rf(@dataset.deck_location)
          end

          # the create_doi method uses a given identifier if it has been specified
          @dataset.identifier = Dataset.create_doi(@dataset, current_user)
          MedusaIngest.send_dataset_to_medusa(@dataset, old_publication_state)

          # strange double-save is because publication changes the dataset, but should not trigger change flag
          # there is probably a better way to do this, and alternatives would be welcome
          if @dataset.save

            if IDB_CONFIG[:local_mode] && IDB_CONFIG[:local_mode] == true
              Rails.logger.warn "Dataset #{@dataset.key} succesfully deposited."
            else
              begin
                notification = DatabankMailer.confirm_deposit(@dataset.key)
                notification.deliver_now
              rescue Exception::StandardError => err
                Rails.logger.warn "Confirmation email not sent for #{@dataset.key}"
                Rails.logger.warn err.to_yaml
                notification = DatabankMailer.confirmation_not_sent(@dataset.key, err)
                notification.deliver_now
              end

            end
            @dataset.save
            format.html { redirect_to dataset_path(@dataset.key), notice: Dataset.deposit_confirmation_notice(old_publication_state, @dataset) }
            format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
          else
            Rails.logger.warn "Error in saving dataset: #{@dataset.key}:"
            Rails.logger.warn "Identifier created, but not saved: #{@dataset.identifier}. Messages sent to Medusa."
            Rails.logger.warn @dataset.errors
            format.html { redirect_to dataset_path(@dataset.key), notice: 'Error in saving dataset has been logged by the Research Data Service.' }
            format.json { render json: @dataset.errors, status: :unprocessable_entity }
          end

          # at this point, we are dealing with a published or imported dataset
        else

          if Dataset.update_datacite_metadata(@dataset, current_user)
            MedusaIngest.send_dataset_to_medusa(@dataset, old_publication_state)

            # strange double-save is because publication changes the dataset, but should not trigger change flag
            # there is probably a better way to do this, and alternatives would be welcome
            if @dataset.save
              if IDB_CONFIG[:local_mode] && IDB_CONFIG[:local_mode] == true
                Rails.logger.warn "Dataset #{@dataset.key} succesfully deposited."
              elsif old_publication_state == Databank::PublicationState::DRAFT && @dataset.is_import
                begin
                  notification = DatabankMailer.confirm_deposit(@dataset.key)
                  notification.deliver_now
                rescue Exception::StandardError => err
                  Rails.logger.warn "Confirmation email not sent for #{@dataset.key}"
                  Rails.logger.warn err.to_yaml
                  notification = DatabankMailer.confirmation_not_sent(@dataset.key, err)
                  notification.deliver_now
                end
              else
                notification = DatabankMailer.confirm_deposit_update(@dataset.key)
                notification.deliver_now
              end
              @dataset.save
              format.html { redirect_to dataset_path(@dataset.key), notice: Dataset.deposit_confirmation_notice(old_publication_state, @dataset) }
              format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
            else
              Rails.logger.warn "Error in saving dataset: #{@dataset.key}:"
              Rails.logger.warn "DataCite record updated, but change in publication state not saved in IDB"
              Rails.logger.warn @dataset.errors
              format.html { redirect_to dataset_path(@dataset.key), notice: 'Error in saving dataset has been logged by the Research Data Service.' }
              format.json { render json: @dataset.errors, status: :unprocessable_entity }
            end

          else
            Rails.logger.warn "Error in publishing import dataset: #{@dataset.key}:"
            format.html { redirect_to dataset_path(@dataset.key), notice: 'Error in publishing dataset has been logged by the Research Data Service.' }
            format.json { render json: @dataset.errors, status: :unprocessable_entity }
          end
        end

      else
        format.html { redirect_to edit_dataset_path(@dataset.key), notice: Dataset.completion_check(@dataset, current_user) }
        format.json { render json: Dataset.completion_check(@dataset, current_user), status: :unprocessable_entity }
      end
    end

  end

  def review_deposit_agreement
    if params.has_key?(:id)
      set_dataset
    end
  end

  def zip_and_download_selected

    if @dataset.identifier && !@dataset.identifier.empty?
      @dataset.datafiles.each do |datafile|
        datafile.record_download(request.remote_ip)
      end

      file_name = "DOI-#{@dataset.identifier}".parameterize + ".zip"
    else
      file_name = "datafiles.zip"
    end

    temp_zipfile = Tempfile.new("#{@dataset.key}.zip")

    begin

      web_ids = params[:selected_files]


      Zip::Archive.open(temp_zipfile.path, Zip::CREATE, Zip::BEST_SPEED) do |ar|

        web_ids.each do |web_id|

          df = Datafile.find_by_web_id(web_id)
          if df
            ar.add_file(df.bytestream_path) # add file to zip archive
          end

        end

      end

      zip_data = File.read(temp_zipfile.path)

      send_data(zip_data, :type => 'application/zip', :filename => file_name)

    ensure
      temp_zipfile.close
      temp_zipfile.unlink
    end

  end

  # precondition: all valid web_ids in medusa
  def download_link

    return_hash = Hash.new

    if params.has_key?('web_ids')
      web_ids_str = params['web_ids']
      web_ids = web_ids_str.split('~')

      if !web_ids.respond_to?(:count) || web_ids.count < 1
        return_hash["status"]="error"
        return_hash["error"]="no web_ids after split"
        render(json: return_hash.to_json, content_type: request.format, :layout => false)
      end

      web_ids.each(&:strip!)


      download_hash = DownloaderClient.get_download_hash(web_ids, "DOI-#{@dataset.identifier}".parameterize)
      if download_hash
        if download_hash['status']== 'ok'
          web_ids.each do |web_id|
            datafile = Datafile.find_by_web_id(web_id)
            if datafile
              #Rails.logger.warn "recording datafile download for web_id #{web_id}"
              datafile.record_download(request.remote_ip)
            else
              #Rails.logger.warn "did not find datafile for web_id #{web_id}"
            end
          end

          return_hash["status"]="ok"
          return_hash["url"]=download_hash['download_url']
          return_hash["total_size"]=download_hash['total_size']
        else
          return_hash["status"]="error"
          return_hash["error"]=download_hash["error"]
        end
      else
        return_hash["status"]="error"
        return_hash["error"]="nil zip link returned"
      end
      render(json: return_hash.to_json, content_type: request.format, :layout => false)
    else
      return_hash["status"]="error"
      return_hash["error"]="no web_ids in request"
      render(json: return_hash.to_json, content_type: request.format, :layout => false)
    end

  end

  def confirmation_message()

    Rails.logger.warn "params inside confirmation messaage: #{params.to_yaml}"

    proposed_dataset = @dataset
    old_embargo_state = @dataset.embargo || Databank::PublicationState::Embargo::NONE
    new_embargo_state = @dataset.embargo || Databank::PublicationState::Embargo::NONE
    #old_publication_state = @dataset.publication_state
    #new_publication_state = @dataset.publication_state

    if params.has_key?('new_embargo_state')

      Rails.logger.warn "new_embargo state detected: #{params['new_embargo_state']}"

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

    Rails.logger.warn "proposed dataset just before detection"
    Rails.logger.warn proposed_dataset.to_yaml
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
      urlNode.content = "https://doi.org/#{@dataset.identifier}"
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

    t.write(%Q[DO  - #{@dataset.identifier}\nPY  - #{@dataset.publication_year}\nUR  - https://doi.org/#{@dataset.identifier}\nPB  - #{@dataset.publisher}\nER  - ])

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

    t.write("@data{#{citekey},\ndoi = {#{@dataset.identifier}},\nurl = {https://doi.org/#{@dataset.identifier}},\nauthor = {#{@dataset.creator_list}},\npublisher = {#{@dataset.publisher}},\ntitle = {#{@dataset.title} ﻿},\nyear = {#{@dataset.publication_year}}
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
    Rails.logger.warn params.to_yaml
    render :edit
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_dataset
    @dataset = Dataset.find_by_key(params[:id])
    raise ActiveRecord::RecordNotFound unless @dataset
  end

  def set_license(dataset)

    @license_link = ""

    @license = LicenseInfo.where(:code => dataset.license).first
    case dataset.license
      when "CC01", "CCBY4"
        @license_link = @license.external_info_url

      when "license.txt"
        @dataset.datafiles.each do |datafile|
          if datafile.bytestream_name && ((datafile.bytestream_name).downcase == "license.txt")
            @license_link = "#{request.base_url}/datafiles/#{datafile.web_id}/download"
          end
        end

      else
        @license_expanded = dataset.license
    end
  end

  def set_file_mode
    Databank::Application.file_mode = Databank::FileMode::WRITE_READ

    mount_path = (Pathname.new(IDB_CONFIG[:storage_mount]).realpath).to_s.strip
    read_only_path = (IDB_CONFIG[:read_only_realpath]).to_s.strip

    if (mount_path.casecmp(read_only_path) == 0 )
      Databank::Application.file_mode = Databank::FileMode::READ_ONLY
    end

  end


  # Never trust parameters from the scary internet, only allow the white list through.
  # def dataset_params

  def dataset_params
    params.require(:dataset).permit(:title, :identifier, :publisher, :license, :key, :description, :keywords, :depositor_email, :depositor_name, :corresponding_creator_name, :corresponding_creator_email, :embargo, :complete, :search, :dataset_version, :release_date, :is_test, :is_import, :audit_id, :removed_private, :have_permission, :agree, :web_ids, datafiles_attributes: [:datafile, :description, :attachment, :dataset_id, :id, :_destroy, :_update, :audit_id], creators_attributes: [:dataset_id, :family_name, :given_name, :institution_name, :identifier, :identifier_scheme, :type_of, :row_position, :is_contact, :email, :id, :_destroy, :_update, :audit_id], funders_attributes: [:dataset_id, :code, :name, :identifier, :identifier_scheme, :grant, :id, :_destroy, :_update, :audit_id], related_materials_attributes: [:material_type, :selected_type, :availability, :link, :uri, :uri_type, :citation, :datacite_list, :dataset_id, :_destroy, :id, :_update, :audit_id], deckfiles_attributes: [:disposition, :remove, :path, :dataset_id, :id])
  end


end
