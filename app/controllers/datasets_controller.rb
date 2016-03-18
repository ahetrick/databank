require 'open-uri'
require 'net/http'
require 'boxr'
require 'zipruby'

class DatasetsController < ApplicationController
  include Datasets::PublicationStateMethods

  protect_from_forgery except: :cancel_box_upload

  load_resource :find_by => :key
  authorize_resource
  skip_load_and_authorize_resource :only => :download_datafiles
  skip_load_and_authorize_resource :only => :download_endNote_XML
  skip_load_and_authorize_resource :only => :download_plaintext_citation
  skip_load_and_authorize_resource :only => :download_BibTeX
  skip_load_and_authorize_resource :only => :download_RIS
  skip_load_and_authorize_resource :only => :stream_file
  skip_load_and_authorize_resource :only => :show_agreement
  skip_load_and_authorize_resource :only => :review_deposit_agreement
  skip_load_and_authorize_resource :only => :datacite_record

  before_action :set_dataset, only: [:show, :edit, :update, :destroy, :download_datafiles, :download_endNote_XML, :download_plaintext_citation, :download_BibTeX, :download_RIS, :deposit, :datacite_record, :update_datacite_metadata, :zip_and_download_selected, :cancel_box_upload, :citation_text, :completion_check, :delete_datacite_id, :change_publication_state, :is_datacite_changed, :tombstone, :idb_datacite_xml]

  @@num_box_ingest_deamons = 10

  # enable streaming responses
  include ActionController::Streaming
  # enable zipline
  # include Zipline

  # GET /datasets
  # GET /datasets.json
  def index

    @datasets = Dataset.where(publication_state: [Databank::PublicationState::RELEASED, Databank::PublicationState::FILE_EMBARGO]).order(updated_at: :desc)
    @datatable = Effective::Datatables::GuestDatasets.new

    if current_user && current_user.role
      case current_user.role
        when "admin"
          @datasets = Dataset.order(updated_at: :desc)
          @datatable = Effective::Datatables::CuratorDatasets.new
        when "depositor"
          if params.has_key?('depositor')
            @datasets = Dataset.where.not(publication_state: Databank::PublicationState::DESTROYED).where("depositor_email = ?", current_user.email).order(updated_at: :desc)
            @datatable = Effective::Datatables::MyDatasets.new(current_email: current_user.email)
          else
            @datasets = Dataset.where.not(publication_state: Databank::PublicationState::DESTROYED).where("publication_state = ? OR publication_state = ? OR depositor_email = ?", Databank::PublicationState::FILE_EMBARGO, Databank::PublicationState::RELEASED, current_user.email).order(updated_at: :desc)
            @datatable = Effective::Datatables::DepositorDatasets.new(current_email: current_user.email, current_name: current_user.name)
          end

      end

    end

  end

  # GET /datasets/1
  # GET /datasets/1.json
  def show
    # @datacite_record = datacite_record_hash
    @completion_check = self.completion_check
    if params.has_key?(:selected_files)
      zip_and_download_selected
    end
    @changetable = nil

    if @dataset.publication_state != Databank::PublicationState::DRAFT
      @changetable = Effective::Datatables::DatasetChanges.new(dataset_id: @dataset.id)
    end

    @publish_modal_msg = publish_modal_msg(@dataset)

    # # clean up incomplete datasfiles
    # @dataset.datafiles.each do |datafile|
    #   datafile.destroy unless (datafile.binary && datafile.binary.file && datafile.binary.file.filename)
    # end

    # @license_header = ""
    # @license_expanded = ""
    @license_link = ""

    @license = LicenseInfo.where(:code => @dataset.license).first
    case @dataset.license
      when "CC01", "CCBY4"
        # @license_header = @license.name
        # File.open(@license.full_text_url){ |f| f.each_line {|row| @license_expanded << row } }
        @license_link = @license.external_info_url

      when "license.txt"
        # @license_header = "See license.txt file in dataset"
        @dataset.datafiles.each do |datafile|
          if datafile.bytestream_name && ((datafile.bytestream_name).downcase == "license.txt")
            @license_link = "#{request.base_url}/datafiles/#{datafile.web_id}/download"
          end
        end

      else
        @license_expanded = @dataset.license
    end

  end

  def idb_datacite_xml
  end

  def cancel_box_upload

    @job_id_string = "0"
    Rails.logger.warn "params: #{params.to_yaml}"

    @datafile = Datafile.find_by_web_id(params[:web_id])

    if @datafile
      if @datafile.job_id
        @job_id_string = @datafile.job_id.to_s
        job = Delayed::Job.where(id: @datafile.job_id).first
        if job && job.locked_by && !job.locked_by.empty?
          locked_by_text = job.locked_by.to_s

          Rails.logger.warn "***\n   locked_by_text #{locked_by_text}"

          pid = locked_by_text.split(":").last

          Rails.logger.warn "***\n    pid: #{pid}"

          if !pid.empty?

            begin

              Process.kill('QUIT', Integer(pid))
              Dir.foreach(IDB_CONFIG[:delayed_job_pid_dir]) do |item|
                Rails.logger.warn("item: #{item}")
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
    @completion_check = self.completion_check
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

    # Rails.logger.warn "inside update dataset"

    if has_nested_param_change?
      @dataset.has_datacite_change = true

      if (@dataset.publication_state != Databank::PublicationState::DRAFT) && !@dataset.is_test?
        # for non-test published datasets, check for added datafiles to send to medusa
        @dataset.datafiles.each do |datafile|
          if datafile.binary && datafile.binary.path

            full_path = datafile.binary.path
            full_path_arr = full_path.split("/")
            staging_path = "#{full_path_arr[5]}/#{full_path_arr[6]}/#{full_path_arr[7]}"

            existing_medusa_ingest = MedusaIngest.where(staging_path: staging_path)

            if !existing_medusa_ingest || existing_medusa_ingest.count == 0

              datafile.binary_name = datafile.binary.file.filename
              datafile.binary_size = datafile.binary.size
              medusa_ingest = MedusaIngest.new
              medusa_ingest.staging_path = staging_path
              medusa_ingest.idb_class = 'datafile'
              medusa_ingest.idb_identifier = datafile.web_id
              medusa_ingest.send_medusa_ingest_message(staging_path)
              medusa_ingest.save
            end
          end
        end

      end

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

  def nuke
    old_state = @dataset.publication_state
    @dataset.publication_state = Databank::PublicationState::DESTROYED
    @dataset.has_datacite_change = false
    @dataset.tombstone_date = Date.current.iso8601
    notice_msg = ""

    if old_state == Databank::PublicationState::METADATA_EMBARGO
      respond_to do |format|
        @dataset.has_datacite_change = false
        if @dataset.save && delete_datacite_id
          format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Reserved DOI has been deleted and all files have been hidden.] }
          format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
        else
          @dataset.publication_state = old_state
          @dataset.tombstone_date = nil
          @dataset.has_datacite_change = false
          @dataset.save
          format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.] }
          format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }

        end
      end
    else
      respond_to do |format|
        @dataset.has_datacite_change = false
        if @dataset.save && update_datacite_metadata
          format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset metadata has been replaced with minimal placeholder values and all files have been hidden.] }
          format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
        else
          @dataset.publication_state = old_state
          @dataset.tombstone_date = nil
          @dataset.has_datacite_change = false
          @dataset.save
          format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.] }
          format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }

        end
      end
    end
  end

  def tombstone

    old_state = @dataset.publication_state

    @dataset.publication_state = Databank::PublicationState::TOMBSTONE
    @dataset.tombstone_date = Date.current

    respond_to do |format|
      @dataset.has_datacite_change = false
      if @dataset.save && update_datacite_metadata
        format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset has been successfully tombstoned.] }
        format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
      else
        @dataset.publication_state = old_state
        @dataset.tombstone_date = nil
        @dataset.has_datacite_change = false
        @dataset.save
        format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Error - see log.] }
        format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }

      end
    end

  end

  def deposit

    old_state = @dataset.publication_state

    if completion_check == 'ok'
      @dataset.complete = true

      if [Databank::PublicationState::DRAFT, Databank::PublicationState::FILE_EMBARGO, Databank::PublicationState::METADATA_EMBARGO].include?(old_state)
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
        if !@dataset.identifier || @dataset.identifier.empty? || (@dataset.publication_state == Databank::PublicationState::DRAFT && !@dataset.is_import?)
          @dataset.identifier = create_doi(@dataset)
        end

        if @dataset.is_import?
          update_datacite_metadata
        end

        if old_state == Databank::PublicationState::DRAFT && !@dataset.is_test?

          @dataset.datafiles.each do |datafile|
            datafile.binary_name = datafile.binary.file.filename
            datafile.binary_size = datafile.binary.size
            medusa_ingest = MedusaIngest.new
            full_path = datafile.binary.path
            full_path_arr = full_path.split("/")
            staging_path = "#{full_path_arr[5]}/#{full_path_arr[6]}/#{full_path_arr[7]}"
            medusa_ingest.staging_path = staging_path
            medusa_ingest.idb_class = 'datafile'
            medusa_ingest.idb_identifier = datafile.web_id
            medusa_ingest.send_medusa_ingest_message(staging_path)
            medusa_ingest.save
          end
          if File.exist?("#{IDB_CONFIG[:agreements_root_path]}/#{@dataset.key}/deposit_agreement.txt")
            medusa_ingest = MedusaIngest.new
            full_path = "#{IDB_CONFIG[:agreements_root_path]}/#{@dataset.key}/deposit_agreement.txt"
            full_path_arr = full_path.split("/")
            staging_path = "#{full_path_arr[5]}/#{full_path_arr[6]}/#{full_path_arr[7]}"
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
              if current_user.role == 'depositor'
                send_deposit_confirmation_email(old_state, @dataset)
                confirmation = DatabankMailer.confirm_deposit(@dataset.key)
                # Rails.logger.warn "confirmation: #{confirmation}"
                confirmation.deliver_now
              end
            end

            format.html { redirect_to dataset_path(@dataset.key), notice: deposit_confirmation_notice(old_state, @dataset) }
            format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
          else
            format.html { redirect_to dataset_path(@dataset.key), notice: 'Error in publishing dataset has been logged by the Research Data Service.' }
            format.json { render json: @dataset.errors, status: :unprocessable_entity }
          end
        else
          if @dataset.save && update_datacite_metadata
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
              # Rails.logger.warn "confirmation: #{confirmation}"
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
        format.html { redirect_to edit_dataset_path(@dataset.key), notice: completion_check }
        format.json { render json: completion_check, status: :unprocessable_entity }
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
          # Rails.logger.warn 'removed related material'
          return true
        end
      else
        # Rails.logger.warn 'added related material'
        return true
      end
    end

    params[:dataset][:creators_attributes].each do |key, creator_attributes|
      if creator_attributes.has_key?(:_destroy)
        if creator_attributes[:_destroy] == true
          # Rails.logger.warn 'removed creator'
          return true
        end
      else
        # Rails.logger.warn 'added creator'
        return true
      end
    end

    params[:dataset][:funders_attributes].each do |key, funder_attributes|
      if funder_attributes.has_key?(:_destroy)
        if funder_attributes[:_destroy] == true
          # Rails.logger.warn 'removed funder'
          return true
        end
      elsif funder_attributes[:name] != ''
        # Rails.logger.warn 'added funder'
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
          ar.add_file(df.binary.path) # add file to zip archive

        end

      end

      zip_data = File.read(temp_zipfile.path)

      send_data(zip_data, :type => 'application/zip', :filename => file_name)


    ensure
      temp_zipfile.close
      temp_zipfile.unlink
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
    return {"status" => "DOI Reserved Only"} if @dataset.publication_state == Databank::PublicationState::FILE_EMBARGO


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

  def completion_check
    response = 'ok'
    validation_error_messages = Array.new
    validation_error_message = ""

    if !@dataset.title || @dataset.title.empty?
      validation_error_messages << "title"
    end

    if @dataset.creator_list.empty?
      validation_error_messages << "at least one creator"
    end

    if !@dataset.license || @dataset.license.empty?
      validation_error_messages << "license"
    end

    contact = nil
    @dataset.creators.each do |creator|
      if creator.is_contact?
        contact = creator
      end
    end

    unless contact
      validation_error_messages << "select primary contact (from Description section author list)"
    end

    if contact.nil? || !contact.email || contact.email == ""
      validation_error_messages << "email address for primary long term contact"
    end

    if current_user
      if ((current_user.role != 'admin') && (@dataset.release_date && (@dataset.release_date > (Date.current + 1.years))))
        validation_error_messages << "a release date no more than one year in the future"
      end
    end

    if @dataset.license && @dataset.license == "license.txt"
      has_file = false
      if @dataset.datafiles
        @dataset.datafiles.each do |datafile|
          if datafile.bytestream_name && ((datafile.bytestream_name).downcase == "license.txt")
            has_file = true
          end
        end
      end

      if !has_file
        validation_error_messages << "a license file named license.txt or a different license selection"
      end

    end

    if @dataset.identifier && @dataset.identifier != ''
      dupcheck = Dataset.where(identifier: @dataset.identifier)
      if dupcheck.count > 1
        validation_error_messages << "a unique DOI"
      end
    end

    if @dataset.datafiles.count < 1
      validation_error_messages << "at least one file"
    end

    if @dataset.embargo && [Databank::PublicationState::FILE_EMBARGO, Databank::PublicationState::METADATA_EMBARGO].include?(@dataset.embargo)
      if !@dataset.release_date || @dataset.release_date <= Date.current
        validation_error_messages << "a future release date for delayed publication (embargo) selection"
      end
    end

    if validation_error_messages.length > 0
      validation_error_message << "Required elements for a complete dataset missing: "
      validation_error_messages.each_with_index do |m, i|
        if i > 0
          validation_error_message << ", "
        end
        validation_error_message << m
      end
      validation_error_message << "."

      response = validation_error_message
    end
    response
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_dataset
    @dataset = Dataset.find_by_key(params[:id])
    raise ActiveRecord::RecordNotFound unless @dataset
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  # def dataset_params

  def dataset_params
    params.require(:dataset).permit(:title, :identifier, :publisher, :publication_year, :license, :key, :description, :keywords, :depositor_email, :depositor_name, :corresponding_creator_name, :corresponding_creator_email, :embargo, :complete, :search, :version, :release_date, :is_test, :is_import, :curator_hold, :audit_id, :removed_private, :have_permission, :agree, datafiles_attributes: [:datafile, :description, :attachment, :dataset_id, :id, :_destory, :_update, :audit_id], creators_attributes: [:dataset_id, :family_name, :given_name, :institution_name, :identifier, :identifier_scheme, :type_of, :row_position, :is_contact, :email, :id, :_destroy, :_update, :audit_id], funders_attributes: [:dataset_id, :code, :name, :identifier, :identifier_scheme, :grant, :id, :_destroy, :_update, :audit_id], related_materials_attributes: [:material_type, :selected_type, :availability, :link, :uri, :uri_type, :citation, :datacite_list, :dataset_id, :_destroy, :id, :_update, :audit_id])
  end

  def ezid_metadata_response

    if @dataset.complete?

      host = IDB_CONFIG[:ezid_host]

      uri = URI.parse("http://#{host}/id/doi:#{@dataset.identifier}")
      response = Net::HTTP.get_response(uri)

      Rails.logger.warn response.to_yaml

      case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          return response

        else
          Rails.logger.warn response.to_yaml
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

  def update_datacite_metadata

    if completion_check == 'ok'

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

      target = "#{request.base_url}#{dataset_path(@dataset.key)}"

      metadata = {}
      if [Databank::PublicationState::FILE_EMBARGO, Databank::PublicationState::RELEASED].include?(@dataset.publication_state)
        metadata['_status'] = 'public'
      elsif [Databank::PublicationState::TOMBSTONE, Databank::PublicationState::DESTROYED].include?(@dataset.publication_state)
        metadata['_status'] = 'unavailable'
      end

      metadata['_target'] = target

      if [Databank::PublicationState::FILE_EMBARGO, Databank::PublicationState::RELEASED, Databank::PublicationState::TOMBSTONE].include?(@dataset.publication_state)
        metadata['datacite'] = @dataset.to_datacite_xml
      elsif @dataset.publication_state == Databank::PublicationState::DESTROYED
        metadata['datacite'] = @dataset.placeholder_metadata
      end


      # Rails.logger.warn metadata.to_yaml

      uri = URI.parse("https://#{host}/id/doi:#{@dataset.identifier}")

      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(user, password)
      request.content_type = "text/plain;charset=UTF-8"
      request.body = make_anvl(metadata)
      request.body.encode(Encoding::UTF_8)

      Rails.logger.warn "***** REQUEST START *****"
      Rails.logger.warn request.to_yaml
      Rails.logger.warn "***** REQUEST STOP *****"

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
    else
      Rails.logger.warn "dataset not detected as complete - #{completion_check}"
      return false
    end

  end

  def make_anvl(metadata)
    def escape(s)
      URI.escape(s, /[%:\n\r]/)
    end

    anvl = ""
    metadata_count = metadata.count
    metadata.each_with_index do |(n, v), i|
      anvl << escape(n.to_s) << ": " << escape(v.to_s)
      if ((i+1) < metadata_count)
        anvl << "\n"
      end
      anvl.force_encoding("UTF-8")
      Rails.logger.warn anvl
      anvl
    end
  end

end
