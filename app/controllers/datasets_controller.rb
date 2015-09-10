require 'open-uri'

class DatasetsController < ApplicationController

  load_resource :find_by => :key
  authorize_resource
  skip_load_and_authorize_resource :only => :download_datafiles
  skip_load_and_authorize_resource :only => :download_endNote_XML
  skip_load_and_authorize_resource :only => :download_plaintext_citation
  skip_load_and_authorize_resource :only => :download_BibTeX
  skip_load_and_authorize_resource :only => :download_RIS
  skip_load_and_authorize_resource :only => :stream_file
  skip_load_and_authorize_resource :only => :show_agreement

  before_action :set_dataset, only: [:show, :edit, :update, :destroy, :download_datafiles, :download_endNote_XML, :download_plaintext_citation, :download_BibTeX, :download_RIS, :deposit]

  # enable streaming responses
  include ActionController::Streaming
  # enable zipline
  include Zipline

  # GET /datasets
  # GET /datasets.json
  def index
    @datasets = Dataset.order(updated_at: :desc)
    if params[:depositor_email]
      @datasets = @datasets.where(depositor_email: params[:depositor_email])
    end
  end

  # GET /datasets/1
  # GET /datasets/1.json
  def show
    if params.keys.include?("selected_files")
      download_datafiles
    end
  end


  # GET /datasets/new
  def new
    @dataset = Dataset.new
    @binary = @dataset.binaries.build
  end

  # GET /datasets/1/edit
  def edit
    @binary = @dataset.binaries.build
  end

  # POST /datasets
  # POST /datasets.json
  def create
    @dataset = Dataset.new(dataset_params)

    respond_to do |format|
      if @dataset.save
        if @dataset.complete?
          success_msg = 'Dataset was successfully deposited.'
        else
          success_msg = 'Dataset was saved but not deposited.'
        end
       
        format.html { redirect_to dataset_path(@dataset.key), notice: success_msg }

        format.json { render :show, status: :created, location: dataset_path(@dataset.key) }
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
        format.html { redirect_to dataset_path(@dataset.key), notice: 'Dataset was successfully updated.' }
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
    @dataset.complete = true
    respond_to do |format|
      if @dataset.save
        format.html { redirect_to dataset_path(@dataset.key), notice: 'Dataset was successfully deposited.' }
        format.json { render :show, status: :ok, location: dataset_path(@dataset.key) }
      else
        format.html { render :edit }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end
  end

  def show_agreement
    #respond_to do # This line should be
    respond_to do |format|
      format.js { render :js => "show_agreement();" }
    end
  end

  def destroy_file
    datafile = Repository::Datafile.find_by_web_id(params[:web_id])
    raise ActiveRecord::RecordNotFound, 'Datafile not found' unless datafile
    datafile.destroy
    redirect_to action: "edit", id: [params[:id]]
  end

  def stream_file

    datafile = Repository::Datafile.find_by_web_id(params[:web_id])
    raise ActiveRecord::RecordNotFound, 'Datafile not found' unless datafile

    bs = datafile.master_bytestream

    if bs and bs.id
      repo_url = URI(bs.id)
      Net::HTTP.start(repo_url.host, repo_url.port) do |http|
        request = Net::HTTP::Get.new(repo_url)
        http.request(request) do |res|
          if res.kind_of?(Net::HTTPTemporaryRedirect)
            redirect_to res.header['Location']
          else
            response.content_type = bs.media_type if bs.media_type
            response.header['Content-Disposition'] =
                "attachment; filename=#{bs.filename || 'binary'}"
            res.read_body do |chunk|
              response.stream.write chunk
            end
          end
          response.stream.close
        end
      end

      # The following is simpler but may be less efficient due to open() not
      # streaming its input
      #options = {}
      #options[:type] = bs.media_type if bs.media_type
      #options[:filename] = bs.filename if bs.filename
      #send_file(open(bs.id), options)
    else
      render text: '404 Not Found', status: 404
    end
  end

  def download_datafiles

    (@dataset.identifier && !@dataset.identifier.empty?) ? filename = "DOI-#{@dataset.identifier}.zip" : filename = "datafiles.zip"

    datafiles = Array.new

    params[:selected_files].each do |file_id|

      bs = Repository::Bytestream.find(file_id)
      raise ActiveRecord::RecordNotFound, 'Bytestream not found' unless bs

      if bs and bs.id
        file_url = bs.id
        zip_path = bs.filename
        datafiles << [file_url, zip_path]
      end

    end

    file_mappings = datafiles
                        .lazy # Lazy allows us to begin sending the download immediately instead of waiting to download everything
                        .map { |url, path| [open(url), path] }

    zipline(file_mappings, filename)


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
    authorNode.content = @dataset.creator_text
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

    t.write("@data{#{citekey},\ndoi = {#{@dataset.identifier}},\nurl = {http://dx.doi.org/#{@dataset.identifier}},\nauthor = {#{@dataset.creator_text}},\npublisher = {#{@dataset.publisher}},\ntitle = {#{@dataset.title} ﻿},\nyear = {#{@dataset.publication_year}}
}")

    send_file t.path, :type => 'application/application/x-bibtex',
              :disposition => 'attachment',
              :filename => "DOI-#{@dataset.identifier}.bib"

    t.close

  end

  private


  # Use callbacks to share common setup or constraints between actions.
  def set_dataset
    @dataset = Dataset.find_by_key(params[:id])
    raise ActiveRecord::RecordNotFound unless @dataset
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  # def dataset_params
  #   params.require(:dataset).permit(:input_title, :input_identifier, :input_publication_year, :input_license, :input_description, :input_creator_name_list, :file_id, :selected_files, binaries_attributes: [:datafile, :dataset_id])
  # end

  def dataset_params
    params.require(:dataset).permit(:title, :identifier, :publisher, :publication_year, :license, :key, :description, :creator_text, :depositor_email, :depositor_name, :corresponding_creator_name, :corresponding_creator_email, :complete, binaries_attributes: [:attachment, :description, :dataset_id, :id, :_destory ])
  end

end
