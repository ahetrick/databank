require 'open-uri'
require 'net/http'
require 'boxr'
require 'zipruby'

class DatasetsController < ApplicationController

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

  before_action :set_dataset, only: [:show, :edit, :update, :destroy, :download_datafiles, :download_endNote_XML, :download_plaintext_citation, :download_BibTeX, :download_RIS, :deposit, :mint_doi, :datacite_record, :update_datacite_metadata, :zip_and_download_selected, :cancel_box_upload, :citation_text, :completion_check, :change_publication_state ]

  @@num_box_ingest_deamons = 10

  # enable streaming responses
  include ActionController::Streaming
  # enable zipline
  # include Zipline

  # GET /datasets
  # GET /datasets.json
  def index
    @datasets = Dataset.search(params[:search]).order(updated_at: :desc)

    if params[:depositor_email]
      @datasets = @datasets.where(depositor_email: params[:depositor_email])
    end

    @datasets = @datasets.page(params[:page]).per_page(10)

  end

  # GET /datasets/1
  # GET /datasets/1.json
  def show
    @datacite_record = datacite_record_hash
    @completion_check = self.completion_check
    if params.has_key?(:selected_files)
      zip_and_download_selected
    end

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
          if (datafile.binary.file.filename).downcase == "license.txt"
            @license_link = "#{request.base_url}/datafiles/#{datafile.web_id}/download"
          end
        end

      else
        @license_expanded = @dataset.license
    end

  end

  def cancel_box_upload

    @job_id_string = "0"
    Rails.logger.warn "params: #{params.to_yaml}"

    @datafile = Datafile.find_by_web_id(params[:web_id])

    if @datafile
      if @datafile.job_id
        @job_id_string = @datafile.job_id.to_s
        job = Delayed::Job.where(id: @datafile.job_id).first
        if job && job.locked_by  && !job.locked_by.empty?
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
  end

  # GET /datasets/1/edit
  def edit
    @dataset.creators.build unless @dataset.creators.count > 0
    @dataset.funders.build unless @dataset.funders.count > 0
    @completion_check = self.completion_check
  end

  # POST /datasets
  # POST /datasets.json
  def create

    Rails.logger.warn params

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
  end

  # PATCH/PUT /datasets/1
  # PATCH/PUT /datasets/1.json
  def update

    respond_to do |format|

      if @dataset.update(dataset_params)

        if @dataset.complete?
          update_datacite_metadata
        end

        format.html { redirect_to dataset_path(@dataset.key)}
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

  def deposit

    if completion_check == 'ok'
      @dataset.complete = true
      @dataset.publication_state = Databank::PublicationState::RELEASED
    else
      @dataset.complete = false
    end

    respond_to do |format|
      if @dataset.complete?
        if !@dataset.identifier || @dataset.identifier.empty?
          @dataset.identifier = mint_doi
        end

        @dataset.datafiles.each do |datafile|
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

        if @dataset.save
          format.html { redirect_to dataset_path(@dataset.key), notice: %Q[Dataset was successfully published and the DataCite DOI minted is #{@dataset.identifier}.<br/>The persistent link to this dataset is now <a href = "http://dx.doi.org/#{@dataset.identifier}">http://dx.doi.org/#{@dataset.identifier}</a>.<br/>There may be a delay before the persistent link will be in effect.  If this link does not redirect to the dataset immediately, try again in an hour.] }
          format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
        else
          format.html { render :edit }
          format.json { render json: @dataset.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to edit_dataset_path(@dataset.key), notice: completion_check }
        format.json {render json: completion_check, status: :unprocessable_entity}
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

    return {"status" => "dataset incomplete"} if !@dataset.complete?

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
    render json:{"citation": @dataset.plain_text_citation}
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
      validation_error_messages << "at least one primary long term contact"
    end

    if contact.nil? || !contact.email || contact.email == ""
      validation_error_messages << "email address for primary long term contact"
    end

    if @dataset.datafiles.count < 1
      validation_error_messages << "at least one file"
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
    params.require(:dataset).permit(:title, :identifier, :publisher, :publication_year, :license, :key, :description, :keywords, :depositor_email, :depositor_name, :corresponding_creator_name, :corresponding_creator_email, :complete, :search, :version, datafiles_attributes: [:datafile, :description, :attachment, :dataset_id, :id, :_destory, :_update ], creators_attributes: [:dataset_id, :family_name, :given_name, :institution_name, :identifier, :identifier_scheme, :type_of, :row_position, :is_contact, :email, :id, :_destroy], funders_attributes: [:dataset_id, :name, :identifier, :identifier_scheme, :grant, :id, :_destroy])
  end

  def ezid_metadata_response

    if @dataset.complete?

      host = IDB_CONFIG[:ezid_host]

      uri = URI.parse("http://#{host}/id/doi:#{@dataset.identifier}")
      response = Net::HTTP.get_response(uri)

      # Rails.logger.warn response.to_yaml

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

  # def change_publication_state(new_state)
  #   @dataset.publication_state |= PublicationState::DRAFT
  #   unless (new_state == @dataset.publication_state)
  #
  #     case new_state
  #       when PublicationState::DRAFT
  #         case @dataset.publication_state
  #
  #           when PublicationState::RELEASED
  #             #TODO
  #           when PublicationState::STANDARD_EMBARGO
  #             #TODO
  #           when PublicationState::INVISIBLE_EMBARGO
  #             #TODO
  #           when PublicationState::TOMBSTONE
  #             #TODO
  #         end
  #
  #       when PublicationState::RELEASED
  #         case @dataset.publication_state
  #           when PublicationState::DRAFT
  #             #TODO
  #           when PublicationState::STANDARD_EMBARGO
  #             #TODO
  #           when PublicationState::INVISIBLE_EMBARGO
  #             #TODO
  #           when PublicationState::TOMBSTONE
  #             #TODO
  #         end
  #
  #       when PublicationState::STANDARD_EMBARGO
  #         case @dataset.publication_state
  #           when PublicationState::DRAFT
  #             #TODO
  #           when PublicationState::RELEASED
  #             #TODO
  #           when PublicationState::INVISIBLE_EMBARGO
  #             #TODO
  #           when PublicationState::TOMBSTONE
  #             #TODO
  #         end
  #
  #       when PublicationState::INVISIBLE_EMBARGO
  #         case @dataset.publication_state
  #           when PublicationState::DRAFT
  #             #TODO
  #           when PublicationState::RELEASED
  #             #TODO
  #           when PublicationState::STANDARD_EMBARGO
  #             #TODO
  #           when PublicationState::TOMBSTONE
  #             #TODO
  #         end
  #
  #       when PublicationState::TOMBSTONE
  #         case @dataset.publication_state
  #           when PublicationState::DRAFT
  #             #TODO
  #           when PublicationState::RELEASED
  #             #TODO
  #           when PublicationState::STANDARD_EMBARGO
  #             #TODO
  #           when PublicationState::INVISIBLE_EMBARGO
  #             #TODO
  #
  #         end
  #       end
  #     end
  #   end
  # end

  def mint_doi

    host = IDB_CONFIG[:ezid_host]
    shoulder = IDB_CONFIG[:ezid_shoulder]
    user = IDB_CONFIG[:ezid_username]
    password = IDB_CONFIG[:ezid_password]

    target = "#{request.base_url}#{dataset_path(@dataset.key)}"

    metadata = {}
    metadata['_target'] = target
    metadata['datacite'] = @dataset.to_datacite_xml

    uri = URI.parse("https://#{host}/shoulder/#{shoulder}")

    request = Net::HTTP::Post.new(uri.request_uri)
    request.basic_auth(user, password)
    request.content_type = "text/plain"
    request.body = make_anvl(metadata)

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
        response_split = response.body.split(" ")
        Rails.logger.warn response_split
        response_split2 = response_split[1].split(":")
        Rails.logger.warn response_split2
        doi = response_split2[1]

      else
        Rails.logger.warn response.to_yaml
        raise "error minting DOI"
    end

  end

  def update_datacite_metadata

    if completion_check = 'ok'

      host = IDB_CONFIG[:ezid_host]
      user = IDB_CONFIG[:ezid_username]
      password = IDB_CONFIG[:ezid_password]

      target = "#{request.base_url}#{dataset_path(@dataset.key)}"

      metadata = {}
      metadata['_target'] = target
      metadata['datacite'] = @dataset.to_datacite_xml

      Rails.logger.warn metadata.to_yaml

      uri = URI.parse("https://#{host}/id/doi:#{@dataset.identifier}")

      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(user, password)
      request.content_type = "text/plain"
      request.body = make_anvl(metadata)

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
          #OK

        else
          Rails.logger.warn response.to_yaml
          raise "error updating DataCite metadata"
      end
    else
      Rails.logger.warn "dataset not detected as complete - #{completion_check}"
    end

  end

  def make_anvl(metadata)
    def escape(s)
      URI.escape(s, /[%:\n\r]/)
    end
    anvl = ''
    metadata.each do |n, v|
      anvl += escape(n.to_s) + ': ' + escape(v.to_s) + "\n"
    end
    # remove last newline. there is probably a really good way to
    # avoid adding it in the first place. if you know it, please fix.
    anvl.strip.encode!('UTF-8')
  end


end
