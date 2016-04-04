require 'open-uri'
require 'net/http'
require 'boxr'
require 'zipruby'
require 'json'

class DatasetsController < ApplicationController
  include Datasets::PublicationStateMethods

  protect_from_forgery except: :cancel_box_upload

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

  before_action :set_dataset, only: [:show, :edit, :update, :destroy, :download_link, :download_endNote_XML, :download_plaintext_citation, :download_BibTeX, :download_RIS, :publish, :zip_and_download_selected, :cancel_box_upload, :citation_text, :idb_datacite_xml, :serialization]

  @@num_box_ingest_deamons = 10

  # enable streaming responses
  include ActionController::Streaming
  # enable zipline
  # include Zipline

  # GET /datasets
  # GET /datasets.json
  def index

    @datasets = Dataset.where(publication_state: [Databank::PublicationState::RELEASED, Databank::PublicationState::Embargo::FILE]).order(updated_at: :desc)
    @datatable = Effective::Datatables::GuestDatasets.new

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

      end

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
      end
    end


    @all_in_medusa = true
    @total_files_size = 0
    @local_zip_max_size = 750000000

    @dataset.datafiles.each do |df|

      @total_files_size = @total_files_size + df.bytestream_size
      if !df.medusa_path || df.medusa_path == ""
        # Rails.logger.warn "no path found for #{df.to_yaml}"
        @all_in_medusa = false
      end

    end

    @completion_check = Dataset.completion_check(@dataset, current_user)

    @changetable = nil

    changes = Audited::Adapters::ActiveRecord::Audit.where("(auditable_type=? AND auditable_id=?) OR (associated_id=?)", 'Dataset', @dataset.id, @dataset.id)

    if changes && changes.count > 0 && @dataset.publication_state != Databank::PublicationState::DRAFT
      @changetable = Effective::Datatables::DatasetChanges.new(dataset_id: @dataset.id)
    end

    @publish_modal_msg = publish_modal_msg(@dataset)

    set_license(@dataset)

  end

  def idb_datacite_xml
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
    @dataset.creators.build
    @dataset.funders.build
    @dataset.related_materials.build
  end

  # GET /datasets/1/edit
  def edit
    @dataset.creators.build unless @dataset.creators.count > 0
    @dataset.funders.build unless @dataset.funders.count > 0
    @dataset.related_materials.build unless @dataset.related_materials.count > 0
    @completion_check = Dataset.completion_check(@dataset, current_user)
    set_license(@dataset)
  end

  # POST /datasets
  # POST /datasets.json
  def create

    @dataset = Dataset.new(dataset_params)

    respond_to do |format|
      if @dataset.save

        if params.has_key?('exit')
          format.html { redirect_to dataset_path(@dataset.key) }
          format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
        else
          format.html { redirect_to edit_dataset_path(@dataset.key) }
          format.json { render :edit, status: :created, location: edit_dataset_path(@dataset.key) }
        end

      else
        format.html { render :new }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /datasets/1
  # PATCH/PUT /datasets/1.json
  def update

    if has_nested_param_change?
      @dataset.has_datacite_change = true
    end

    respond_to do |format|

      if @dataset.update(dataset_params)
        format.html { redirect_to dataset_path(@dataset.key) }
        format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
      else
        format.html { render :edit }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end

    end
  end

  # DELETE /datasets/1
  # DELETE /datasets/1.json
  def destroy
    @dataset.destroy
    respond_to do |format|
      format.html { redirect_to datasets_url, notice: 'Dataset was successfully destroyed.' }
      format.json { head :no_content }
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

        if @dataset.update_datacite_metadata(current_user)
          @dataset.has_datacite_change = false
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

        if @dataset.update_datacite_metadata(current_user)
          @dataset.has_datacite_change = false
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
          if delete_datacite_id
            @dataset.has_datacite_change = false
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
          if  @dataset.update_datacite_metadata(current_user)
            format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset metadata and all files have permanently supressed.] }
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

    old_state = @dataset.publication_state

    # only publish complete datsets
    if Dataset.completion_check(@dataset, current_user) == 'ok'
      @dataset.complete = true
      # set relase date
      if [Databank::PublicationState::DRAFT, Databank::PublicationState::Embargo::FILE, Databank::PublicationState::Embargo::METADATA].include?(old_state)
        if (@dataset.release_date && @dataset.release_date <= Date.current()) || !@dataset.embargo || @dataset.embargo == ""
          @dataset.release_date = Date.current()
        end
      end
      if !@dataset.release_date
        @dataset.release_date = Date.current()
      end
    else
      @dataset.complete = false
    end

    respond_to do |format|
      if @dataset.complete?

        # register with DataCite for new datasets, update for imports and changes to other previously published datasets
        if !@dataset.identifier || @dataset.identifier.empty? || (@dataset.publication_state == Databank::PublicationState::DRAFT && !@dataset.is_import?)
          @dataset.identifier = create_doi(@dataset)
        end

        if @dataset.is_import?
          @dataset.update_datacite_metadata(current_user)
        end

        # create or confirm dataset_staging directory for dataset
        dataset_dirname = "DOI-#{(@dataset.identifier).parameterize}"
        staging_dir = "#{IDB_CONFIG[:staging_root]}/#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}"
        FileUtils.mkdir_p "#{staging_dir}/dataset_files"
        FileUtils.mkdir_p "#{staging_dir}/system"
        FileUtils.chmod "u=wrx,go=rx", File.dirname(staging_dir)

        file_time = Time.now.strftime('%Y-%m-%d_%H-%M')
        description_xml = @dataset.to_datacite_xml
        File.open("#{staging_dir}/system/description.#{file_time}.xml", "w") do |description_file|
          description_file.puts(description_xml)
        end
        FileUtils.chmod 0755, "#{staging_dir}/system/description.#{file_time}.xml"

        medusa_ingest = MedusaIngest.new
        staging_path = "#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}/system/description.#{file_time}.xml"
        medusa_ingest.staging_path = staging_path
        medusa_ingest.idb_class = 'description'
        medusa_ingest.idb_identifier = @dataset.key
        medusa_ingest.send_medusa_ingest_message(staging_path)
        medusa_ingest.save

        if old_state == Databank::PublicationState::DRAFT && !@dataset.is_test?

          @dataset.datafiles.each do |datafile|

            datafile.binary_name = datafile.binary.file.filename
            datafile.binary_size = datafile.binary.size
            medusa_ingest = MedusaIngest.new
            full_path = datafile.binary.path
            full_path_arr = full_path.split("/")
            full_staging_path = "#{staging_dir}/dataset_files/#{full_path_arr[7]}"
            # make symlink
            FileUtils.symlink(full_path, full_staging_path)
            FileUtils.chmod "u=wrx,go=rx", full_staging_path
            # point to symlink for path
            # staging_path = "#{full_path_arr[5]}/#{full_path_arr[6]}/#{full_path_arr[7]}"
            staging_path = "#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}/dataset_files/#{full_path_arr[7]}"
            medusa_ingest.staging_path = staging_path
            medusa_ingest.idb_class = 'datafile'
            medusa_ingest.idb_identifier = datafile.web_id
            medusa_ingest.send_medusa_ingest_message(staging_path)
            medusa_ingest.save
          end
          if File.exist?("#{IDB_CONFIG[:agreements_root_path]}/#{@dataset.key}/deposit_agreement.txt")
            medusa_ingest = MedusaIngest.new
            full_path = "#{IDB_CONFIG[:agreements_root_path]}/#{@dataset.key}/deposit_agreement.txt"
            full_staging_path = "#{staging_dir}/system/deposit_agreement.txt"
            # make symlink
            FileUtils.symlink(full_path, full_staging_path)
            FileUtils.chmod "u=wrx,go=rx", full_staging_path
            # point to symlink for path
            #staging_path = "#{full_path_arr[5]}/#{full_path_arr[6]}/#{full_path_arr[7]}"
            staging_path = "#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}/system/deposit_agreement.txt"
            medusa_ingest.staging_path = staging_path
            medusa_ingest.idb_class = 'agreement'
            medusa_ingest.idb_identifier = @dataset.key
            medusa_ingest.send_medusa_ingest_message(staging_path)
            medusa_ingest.save
          else
            raise "deposit agreement file not found for #{@dataset.key}"
          end

        end

        @dataset.has_datacite_change = false
        serialization_json = (@dataset.recovery_serialization).to_json
        File.open("#{staging_dir}/system/serialization.#{file_time}.json", "w") do |serialization_file|
          serialization_file.puts(serialization_json)
        end
        FileUtils.chmod 0755, "#{staging_dir}/system/serialization.#{file_time}.json"

        medusa_ingest = MedusaIngest.new
        staging_path = "#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}/system/serialization.#{file_time}.json"
        medusa_ingest.staging_path = staging_path
        medusa_ingest.idb_class = 'serialization'
        medusa_ingest.idb_identifier = @dataset.key
        medusa_ingest.send_medusa_ingest_message(staging_path)
        medusa_ingest.save


        changelog_json = (@dataset.full_changelog).to_json
        File.open("#{staging_dir}/system/changelog.#{file_time}.json", "w") do |changelog_file|
          changelog_file.write(changelog_json)
        end
        FileUtils.chmod 0755, "#{staging_dir}/system/changelog.#{file_time}.json"
        medusa_ingest = MedusaIngest.new
        staging_path = "#{IDB_CONFIG[:dataset_staging]}/#{dataset_dirname}/system/changelog.#{file_time}.json"
        medusa_ingest.staging_path = staging_path
        medusa_ingest.idb_class = 'changelog'
        medusa_ingest.idb_identifier = @dataset.key
        medusa_ingest.send_medusa_ingest_message(staging_path)
        medusa_ingest.save

        if old_state == Databank::PublicationState::DRAFT

          if @dataset.save

            if (@dataset.release_date && @dataset.release_date <= Date.current()) || !@dataset.embargo || @dataset.embargo == ""
              @dataset.publication_state = Databank::PublicationState::RELEASED
            else
              @dataset.publication_state = @dataset.embargo
            end
            @dataset.has_datacite_change = false
            @dataset.save

            if IDB_CONFIG.has_key?(:local_mode) && IDB_CONFIG[:local_mode]
              Rails.logger.warn "deposit OK for #{@dataset.key}"
            else
              confirmation = DatabankMailer.confirm_deposit(@dataset.key)
              confirmation.deliver_now
            end

            format.html { redirect_to dataset_path(@dataset.key), notice: deposit_confirmation_notice(old_state, @dataset) }
            format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
          else
            format.html { redirect_to dataset_path(@dataset.key), notice: 'Error in publishing dataset has been logged by the Research Data Service.' }
            format.json { render json: @dataset.errors, status: :unprocessable_entity }
          end
        else
          if @dataset.save && @dataset.update_datacite_metadata(current_user)
            if (@dataset.release_date && @dataset.release_date <= Date.current()) || !@dataset.embargo || @dataset.embargo == ""
              @dataset.publication_state = Databank::PublicationState::RELEASED
            else
              @dataset.publication_state = @dataset.embargo
            end
            @dataset.has_datacite_change = false
            @dataset.save

            if IDB_CONFIG.has_key?(:local_mode) && IDB_CONFIG[:local_mode]
              Rails.logger.warn "deposit update OK for #{@dataset.key}"
            else
              confirmation = DatabankMailer.confirm_deposit_update(@dataset.key)
              confirmation.deliver_now
            end
            format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Changes have been successfully published.] }
            format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
          else
            format.html { redirect_to dataset_path(@dataset.key), notice: 'Error in publishing changes has been logged by the Research Data Service.' }
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

  def has_nested_param_change?

    params[:dataset][:related_materials_attributes].each do |key, material_attributes|
      if material_attributes.has_key?(:_destroy)
        if material_attributes[:_destroy] == true
          return true
        end
      else
        return true
      end
    end

    params[:dataset][:creators_attributes].each do |key, creator_attributes|
      if creator_attributes.has_key?(:_destroy)
        if creator_attributes[:_destroy] == true
          return true
        end
      else
        return true
      end
    end

    params[:dataset][:funders_attributes].each do |key, funder_attributes|
      if funder_attributes.has_key?(:_destroy)
        if funder_attributes[:_destroy] == true
          return true
        end
      elsif funder_attributes[:name] != ''
        return true
      end
    end

    # if we get here, no change has been detected
    return false
  end

  def zip_and_download_selected

    if @dataset.identifier && !@dataset.identifier.empty?
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
      urlNode.content = "http://dx.doi.org/#{@dataset.identifier}"
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

    t.write(%Q[DO  - #{@dataset.identifier}\nPY  - #{@dataset.publication_year}\nUR  - http://dx.doi.org/#{@dataset.identifier}\nPB  - #{@dataset.publisher}\nER  - ])

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

    t.write("@data{#{citekey},\ndoi = {#{@dataset.identifier}},\nurl = {http://dx.doi.org/#{@dataset.identifier}},\nauthor = {#{@dataset.creator_list}},\npublisher = {#{@dataset.publisher}},\ntitle = {#{@dataset.title} ﻿},\nyear = {#{@dataset.publication_year}}
}")

    send_file t.path, :type => 'application/application/x-bibtex',
              :disposition => 'attachment',
              :filename => "DOI-#{@dataset.identifier}.bib"

    t.close

  end

  def datacite_record_hash

    return {"status" => "dataset not published"} if @dataset.publication_state == Databank::PublicationState::DRAFT
    return {"status" => "DOI Reserved Only"} if @dataset.publication_state == Databank::PublicationState::Embargo::FILE


    response_hash = Hash.new

    begin

      response = ezid_metadata_response
      response_body_hash = Hash.new
      response_lines = response.body.to_s.split("\n")
      response_lines.each do |line|
        split_line = line.split(": ")
        response_body_hash["#{split_line[0]}"] = "#{split_line[1]}"
      end

      clean_metadata_xml_string = (response_body_hash["datacite"]).gsub("%0A", '')
      metadata_doc = Nokogiri::XML(clean_metadata_xml_string)

      response_hash["target"] = response_body_hash["_target"]
      response_hash["created"]= (Time.at(Integer(response_body_hash["_created"])).to_datetime).strftime("%Y-%m-%d at %I:%M%p")
      response_hash["updated"]= (Time.at(Integer(response_body_hash["_updated"])).to_datetime).strftime("%Y-%m-%d at %I:%M%p")
      response_hash["owner"] = response_body_hash["_owner"]
      response_hash["status"] = response_body_hash["_status"]
      response_hash["datacenter"] = response_body_hash["_datacenter"]
      response_hash["metadata"] = metadata_doc

      return response_hash


    rescue StandardError => error

      return {"error" => error.message}

    end

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

  # Never trust parameters from the scary internet, only allow the white list through.
  # def dataset_params

  def dataset_params
    params.require(:dataset).permit(:title, :identifier, :publisher, :publication_year, :license, :key, :description, :keywords, :depositor_email, :depositor_name, :corresponding_creator_name, :corresponding_creator_email, :embargo, :complete, :search, :version, :release_date, :is_test, :is_import, :audit_id, :removed_private, :have_permission, :agree, :web_ids, datafiles_attributes: [:datafile, :description, :attachment, :dataset_id, :id, :_destory, :_update, :audit_id], creators_attributes: [:dataset_id, :family_name, :given_name, :institution_name, :identifier, :identifier_scheme, :type_of, :row_position, :is_contact, :email, :id, :_destroy, :_update, :audit_id], funders_attributes: [:dataset_id, :code, :name, :identifier, :identifier_scheme, :grant, :id, :_destroy, :_update, :audit_id], related_materials_attributes: [:material_type, :selected_type, :availability, :link, :uri, :uri_type, :citation, :datacite_list, :dataset_id, :_destroy, :id, :_update, :audit_id])
  end

  def ezid_metadata_response

    if @dataset.complete?

      host = IDB_CONFIG[:ezid_host]

      uri = URI.parse("http://#{host}/id/doi:#{@dataset.identifier}")
      response = Net::HTTP.get_response(uri)

      case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          return response

        else
          raise "error getting DataCite metadata record from EZID"
      end

    else

      raise "incomplete dataset"

    end
  end

  def delete_datacite_id
    user = nil
    password = nil
    host = IDB_CONFIG[:ezid_host]

    if @dataset.is_test?
      user = 'apitest'
      password = 'apitest'
    else
      user = IDB_CONFIG[:ezid_username]
      password = IDB_CONFIG[:ezid_password]
    end

    uri = URI.parse("https://#{host}/id/doi:#{@dataset.identifier}")

    request = Net::HTTP::Delete.new(uri.request_uri)
    request.basic_auth(user, password)
    request.content_type = "text/plain"

    sock = Net::HTTP.new(uri.host, uri.port)
    # sock.set_debug_output $stderr

    if uri.scheme == 'https'
      sock.use_ssl = true
    end

    begin

      response = sock.start { |http| http.request(request) }

    rescue Net::HTTPBadResponse, Net::HTTPServerError => error
      Rails.logger.warn error.message
      Rails.logger.warn response.body
    end

    case response
      when Net::HTTPSuccess, Net::HTTPRedirection
        return true

      else
        Rails.logger.warn response.to_yaml
        return false
    end

  end


end
