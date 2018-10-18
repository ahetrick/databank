include ActionView::Helpers::NumberHelper # to pass a display value to a javascript function that adds characters to view
require 'tempfile'
require 'open-uri'
require 'fileutils'
require 'net/http'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class DatafilesController < ApplicationController

  before_action :set_datafile, only: [:show, :edit, :update, :destroy, :download, :record_download, :download_url,
                                      :upload, :do_upload, :reset_upload, :resume_upload, :update_status,
                                      :preview, :display, :peek_text, :filepath, :iiif_filepath]

  before_action :set_dataset, only: [:index, :show, :edit, :new, :add, :create, :destroy, :upload, :do_upload]

  # GET /datafiles
  # GET /datafiles.json
  def index
    @datafiles = @dataset.ordered_datafiles
    authorize! :edit, @dataset
  end

  # GET /datafiles/1
  # GET /datafiles/1.json
  def show
    authorize! :edit, @dataset
  end

  # GET /datafiles/new
  def new
    @datafile = Datafile.new
    @datafile.web_id ||= @datafile.generate_web_id
  end

  # GET /datafiles/1/edit
  def edit
    authorize! :edit, @dataset
  end

  def add
    @datafile = Datafile.create(dataset_id: @dataset.id)
    authorize! :edit, @dataset
    respond_to do |format|
      format.html {redirect_to "/datasets/#{@dataset.key}/datafiles/#{@datafile.web_id}/upload"}
      format.json {render :edit, status: :created, location: "/datasets/#{@dataset.key}/datafiles/#{@datafile.webi_id}/upload"}
    end
  end

  # POST /datafiles
  # POST /datafiles.json
  def create

    @datafile = Datafile.new(dataset_id: @dataset.id)

    @datafile.save

    if params.has_key?(:datafile) && params[:datafile].has_key?(:tus_url)

      tus_url = params[:datafile][:tus_url]
      tus_url_arr = tus_url.split('/')
      tus_key = tus_url_arr[-1]

      @datafile.storage_root = Application.storage_manager.draft_root.name
      @datafile.binary_name = params[:datafile][:filename]
      @datafile.storage_key = tus_key
      @datafile.binary_size = params[:datafile][:size]
      @datafile.mime_type = params[:datafile][:mime_type]


    end

    respond_to do |format|
      if @datafile.save
        format.html {redirect_to "/datasets/#{@dataset.key}/datafiles/#{@datafile.web_id}/upload"}
        format.json {render json: to_fileupload, content_type: request.format, :layout => false}
      else
        format.html {render :new}
        format.json {render json: @datafile.errors, status: :unprocessable_entity}
      end
    end

  end

  def preview
    @datafile.record_download(request.remote_ip)
    respond_to do |format|
      format.html {render :preview}
      format.json {render json: {filename: @datafile.bytestream_name, body: @datafile.preview, status: :ok}}
    end
  end

  def display
    @datafile.record_download(request.remote_ip)
    respond_to do |format|
      format.html {
        send_file(@datafile.bytestream_path,
                  :disposition => 'inline',
                  :type => @datafile.mime_type,
                  :x_sendfile => true)
      }
      format.json {render json: {filename: @datafile.bytestream_name, body: @datafile.preview, status: :ok}}
    end
  end

  # PATCH/PUT /datafiles/1
  # PATCH/PUT /datafiles/1.json
  def update

    @datafile.assign_attributes(status: 'new', upload: nil) if params[:delete_upload] == 'yes'

    respond_to do |format|
      if @datafile.update(datafile_params)
        format.html {redirect_to @datafile, notice: 'Datafile was successfully updated.'}
        format.json {render :show, status: :ok, location: @datafile}
      else
        format.html {render :edit}
        format.json {render json: @datafile.errors, status: :unprocessable_entity}
      end
    end
  end

  # DELETE /datafiles/1
  # DELETE /datafiles/1.json
  def destroy

    respond_to do |format|

      if @datafile.destroy && @dataset.save
        format.html {redirect_to edit_dataset_path(@dataset.key)}
        format.json {render json: {"confirmation" => "deleted"}, status: :ok}
      else
        format.html {redirect_to edit_dataset_path(@dataset.key)}
        format.json {render json: @datafile.errors, status: :unprocessable_entity}
      end

    end

  end

  def upload
  end

  def do_upload
    unpersisted_datafile = Datafile.new(upload_params)
    unpersisted_datafile.dataset_id = @dataset.id

    # If no file has been uploaded or the uploaded file has a different filename,
    # do a new upload from scratch

    if !@datafile.binary || !@datafile.binary.file || (@datafile.binary.file.filename != unpersisted_datafile.binary.file.filename)
      @datafile.assign_attributes(upload_params)
      @datafile.upload_status = 'uploading'
      @datafile.save!
      render json: to_fileupload and return

      # If the already uploaded file has the same filename, try to resume
    else
      current_size = @datafile.binary.size
      content_range = request.headers['CONTENT-RANGE']
      begin_of_chunk = content_range[/\ (.*?)-/, 1].to_i # "bytes 100-999999/1973660678" will return '100'

      # If the there is a mismatch between the size of the incomplete upload and the content-range in the
      # headers, then it's the wrong chunk!
      # In this case, start the upload from scratch
      unless begin_of_chunk == current_size
        @datafile.update!(upload_params)
        render json: to_fileupload and return
      end

      # Add the following chunk to the incomplete upload
      File.open(@datafile.binary.path, "ab") {|f| f.write(upload_params[:binary].read)}

      # Update the upload_file_size attribute
      @datafile.upload_file_size = @datafile.upload_file_size.nil? ? unpersisted_datafile.binary.file.size : @datafile.upload_file_size + unpersisted_datafile.binary.file.size
      @datafile.save!

      render json: to_fileupload and return

    end

  end

  def reset_upload
    @dataset = Dataset.find_by_key(params[:dataset_id])
    raise "Dataset not Found, params:#{params.to_yaml}" unless @dataset
    # Allow users to delete uploads only if they are incomplete
    raise StandardError, "Action not allowed" unless @datafile.upload_status == 'uploading'
    @datafile.update!(status: 'new', binary: nil)
    redirect_to "/datasets/#{@dataset.key}/datafiles/#{@datafile.web_id}/upload", notice: "Upload reset successfully. You can now start over"
  end

  def resume_upload
    @dataset = Dataset.find_by_key(params[:dataset_id])
    raise "Dataset not Found, params:#{params.to_yaml}" unless @dataset
    render json: {file: {name: "/datafiles/#{@dataset.key}/datafiles/#{@datafile.web_id}", size: @datafile.binary.size}} and return
    #render json: {file: {name: "#{@datafile.binary.file.filename}", size: @datafile.binary.size}} and return
  end

  def update_status
    raise ArgumentError, "Wrong status provided " + params[:status] unless @datafile.upload_status == 'uploading' && params[:status] == 'uploaded'
    @datafile.update!(upload_status: params[:status])
    head :ok
  end

  def download

    current_root = Application.storage_manager.root_set.at(@datafile.storage_root)

    if current_root.root_type == :filesystem
      path = current_root.path_to(@datafile.storage_key, check_path: true)
      send_file path, filename: @datafile.binary_name, type: @datafile.mime_type || ‘application/octet-stream’


    else

      url = Application.aws_signer.presigned_url(:get_object, bucket: @datafile.storage_bucket, key: @datafile.storage_key)

      redirect_to url

    end

  end

  def to_fileupload
    {
        files:
            [
                {
                    datafileId: @datafile.id,
                    webId: @datafile.web_id,
                    url: "datafiles/#{@datafile.web_id}",
                    delete_url: "datafiles/#{@datafile.web_id}",
                    delete_type: "DELETE",
                    name: "#{@datafile.binary_name}",
                    size: "#{number_to_human_size(@datafile.binary_size)}"
                }
            ]
    }

  end

  def record_download
    @datafile.record_download(request.remote_ip)
    render json: {status: :ok}
  end

  def filepath

    if IDB_CONFIG[:aws][:s3_mode]
      render json: {filepath: "",  error: "No filepath for object in s3 bucket."}, status: :bad_request
    else
      if @datafile.filepath
        render json: {filepath: @datafile.filepath}, status: ok
      else
        render json: {filepath: "",  error: "No binary object found."}, status: :not_found
      end
    end

  end

  def peek_text
    render json: {peek_text: @datafile.peek_text}
  end

  def iiif_filepath
    if IDB_CONFIG[:aws][:s3_mode]
      render json: {error: "No filepath for object in s3 bucket."}, status: :bad_request
    else
      if @datafile.filepath
        render json: {filepath: @datafile.iiif_bytestream_path}, status: :ok
      else
        render json: {error: "No binary object found."}, status: :not_found
      end
    end
  end

  def bucket_and_key
    if IDB_CONFIG[:aws][:s3_mode]
      render json: {bucket: @datafile.storage_root_bucket, key: @datafile.storage_key_with_prefix}, status: ok
    else
      render json: {error: "No bucket for datafile stored on filesystem."}, status: :bad_request
    end
  end

  def create_from_url

    # Rails.logger.warn "inside create from url"
    # Rails.logger.warn params.to_yaml

    @dataset ||= Dataset.find_by_key(params[:dataset_key])

    @filename ||= "not_specified"
    @filesize ||= 0

    if params.has_key?(:name)
      @filename = params[:name]
    end
    if params.has_key?(:size)
      @filesize = params[:size]
    end

    @filesize_display = "#{number_to_human_size(@filesize)}"

    @datafile ||= Datafile.create(dataset_id: @dataset.id)

    @job = Delayed::Job.enqueue CreateDatafileFromRemoteJob.new(@dataset.id, @datafile, params[:url], @filename, @filesize)

    @datafile.job_id = @job.id
    @datafile.box_filename = @filename
    @datafile.box_filesize_display = @filesize_display
    @datafile.save

  end

  def create_from_deckfile

    @datafile = Datafile.new
    @dataset = Dataset.find_by_key(params[:dataset_key])
    @deckfile = Deckfile.find(params[:deckfile_id])
    if @dataset && @deckfile
      @datafile.dataset_id = @dataset.id

      if File.file?(@deckfile.path)
        @datafile.binary = Pathname.new(@deckfile.path).open
      else
        raise "file not detected"
      end
      @datafile.save!
    end
    @deckfile.destroy!

    render(json: to_fileupload, content_type: request.format, :layout => false)


  end

  def remote_content_length

    response = nil

    @remote_url = params["remote_url"]

    uri = URI.parse(@remote_url)

    Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) {|http|
      response = http.request_head(uri.path)
    }

    # Rails.logger.warn "content length: #{response['content-length']}"

    if response['content-length']

      remote_content_length = Integer(response['content-length']) rescue nil

      if remote_content_length && remote_content_length > 0

        render(json: {"status": "ok", "remote_content_length": remote_content_length}, content_type: request.format, layout: false)

      else

        render(json: {"status": "error", "error": "error getting remote content length"}, content_type: request.format, layout: false)

      end

    else
      render(json: {"status": "error", "error": "error getting content length from url"}, content_type: request.format, layout: false)
    end
  end

  def create_from_url_unknown_size

    @datafile = Datafile.new
    @dataset = Dataset.find_by_key(params[:dataset_key])
    if @dataset
      @datafile.dataset_id = @dataset.id
      @remote_url = params["remote_url"]
      @filename = params["remote_filename"]

      dir_name = "#{Rails.root}/public/uploads/#{@dataset.id}"

      FileUtils.mkdir_p(dir_name) unless File.directory?(dir_name)

      filepath = "#{dir_name}/#{@filename}"

      File.open(filepath, 'wb+') do |outfile|
        uri = URI.parse(@remote_url)
        Rails.logger.warn(uri.to_yaml)

        Net::HTTP.start(uri.host, uri.port, :use_ssl => true) {|http|
          http.request_get(uri.path) {|res|
            res.read_body {|seg|

              if File.size(outfile) < 1000000000000
                Rails.logger.warn(seg)
                outfile << seg
              else
                @datafile.destroy
                render(json: {files: [{datafileId: 0, webId: "error", url: "error", name: "error: filesize exceeds 1TB", size: "0"}]}, content_type: request.format, :layout => false)
              end
            }
          }
        }

      end

      if File.file?(filepath)
        @datafile.binary = Rails.root.join("public/uploads/#{@dataset.id}/#{@filename}").open
      else
        raise "error in ingesting file from url"
      end
      @datafile.save!
    else
      raise "dataset not found for ingest from url"
    end

    render(json: to_fileupload, content_type: request.format, :layout => false)


  end


  private

  # Use callbacks to share common setup or constraints between actions.
  def set_datafile
    @datafile = Datafile.find_by_web_id(params[:id])

    raise ActiveRecord::RecordNotFound unless @datafile
  end

  def set_dataset

    @dataset = nil

    if !@datafile && params.has_key?(:id)
      set_datafile
    end

    if @datafile
      @dataset = Dataset.find(@datafile.dataset_id)
    elsif params.has_key?(:dataset_id)
      @dataset = Dataset.find_by_key(params[:dataset_id])
    end

    raise ActiveRecord::RecordNotFound unless @dataset

  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def datafile_params
    params.require(:datafile).permit(:description, :binary, :web_id, :dataset_id)
  end

  def upload_params
    params.require(:datafile).permit(:binary)
  end

end
