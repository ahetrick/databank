require 'open-uri'

class DatasetsController < ApplicationController

  load_and_authorize_resource

  before_action :set_dataset, only: [:show, :edit, :update, :destroy, :download_datafiles, :download_endNote_XML, :download_plaintext_citation, :download_BibTeX, :download_RIS, :addDatafile]

  # enable streaming responses
  include ActionController::Streaming
  # enable zipline
  include Zipline

  # GET /datasets
  # GET /datasets.json
  def index
    @datasets = Dataset.order(updated_at: :desc)
  end

  # GET /datasets/1
  # GET /datasets/1.json
  def show
    if params.keys.include?("selected_files")
      download_datafiles
    end
    @binaries = @dataset.binaries.all
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
       
        format.html { redirect_to @dataset, notice: 'Dataset was successfully created.' }
        format.json { render :show, status: :created, location: @dataset }
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
        format.html { redirect_to @dataset, notice: 'Dataset was successfully updated.' }
        format.json { render :show, status: :ok, location: @dataset }
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

  def destroy_file
    item = Repository::Item.find_by_web_id(params[:web_id])
    raise ActiveRecord::RecordNotFound, 'Item not found' unless item
    item.destroy
    redirect_to action: "edit", id: [params[:id]]
  end

  def stream_file

    bs = Repository::Bytestream.find(params[:file_id])
    raise ActiveRecord::RecordNotFound, 'Bytestream not found' unless bs

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

    t = Tempfile.new("#{@dataset.mainTitle}_endNote")

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

    @dataset.creators.each do |creator|
      authorNode = doc.create_element('author')
      authorNode.content = creator.creatorName
      authorNode.parent = authorsNode
    end

    titlesNode = doc.create_element('titles')
    titlesNode.parent = recordNode

    titleNode = doc.create_element('title')
    titleNode.parent = titlesNode
    titleNode.content = @dataset.mainTitle

    datesNode = doc.create_element('dates')
    datesNode.parent = recordNode

    yearNode = doc.create_element('year')
    yearNode.content = @dataset.publicationYear
    yearNode.parent = datesNode

    publisherNode = doc.create_element('publisher')
    publisherNode.parent = recordNode
    publisherNode.content = @dataset.publisher

    urlsNode = doc.create_element('urls')
    urlsNode.parent = recordNode

    relatedurlsNode = doc.create_element('related-urls')
    relatedurlsNode.parent = urlsNode

    urlNode = doc.create_element('url')
    urlNode.parent = relatedurlsNode
    urlNode.content = "http://dx.doi.org/#{@dataset.identifier}"

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

    t = Tempfile.new("#{@dataset.identifier}_datafiles")

    t.write(%Q[Provider: Illinois Data Bank\nContent: text/plain; charset=%Q[us-ascii]\nTY  - DATA\nT1  - #{@dataset.mainTitle}\n])

    @dataset.creators.each do |creator|
      t.write("AU  - #{creator.creatorName.strip}\n")
    end

    t.write(%Q[DO  - #{@dataset.identifier}\nPY  - #{@dataset.publicationYear}\nUR  - http://dx.doi.org/#{@dataset.identifier}\nPB  - #{@dataset.publisher}\nER  - ])

    send_file t.path, :type => 'application/x-Research-Info-Systems',
              :disposition => 'attachment',
              :filename => "DOI-#{@dataset.mainTitle}.ris"
    t.close
  end

  def download_plaintext_citation

    t = Tempfile.new("#{@dataset.mainTitle}_citation")

    t.write(%Q[#{@dataset.plainTextCitation}\n])

    send_file t.path, :type => 'text/plain',
              :disposition => 'attachment',
              :filename => "DOI-#{@dataset.mainTitle}.txt"

    t.close

  end


  def download_BibTeX
    t = Tempfile.new("#{@dataset.identifier}_endNote")
    citekey = SecureRandom.uuid

    t.write("@data{#{citekey},\ndoi = {#{@dataset.identifier}},\nurl = {http://dx.doi.org/#{@dataset.identifier}},\nauthor = {#{@dataset.creatorList}},\npublisher = {#{@dataset.publisher}},\ntitle = {#{@dataset.mainTitle} ﻿},\nyear = {#{@dataset.publicationYear}}
}")

    send_file t.path, :type => 'application/application/x-bibtex',
              :disposition => 'attachment',
              :filename => "DOI-#{@dataset.identifier}.bib"

    t.close

  end

  private


  # Use callbacks to share common setup or constraints between actions.
  def set_dataset
    @dataset = Dataset.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  # def dataset_params
  #   params.require(:dataset).permit(:input_title, :input_identifier, :input_publication_year, :input_license, :input_description, :input_creator_name_list, :file_id, :selected_files, binaries_attributes: [:datafile, :dataset_id])
  # end

  def dataset_params
    params.require(:dataset).permit(:title, :identifier, :publisher, :publication_year, :license, :key, :description, :creator_text, :depositor_email, :depositor_name, binaries_attributes: [:datafile, :description, :dataset_id, :id, :_destory ])
  end

end
