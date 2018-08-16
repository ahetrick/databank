require 'fileutils'
require 'digest/md5'

class ApiDatasetController < ApplicationController

  before_action :authenticate, only: [:datafile]

  skip_before_action :verify_authenticity_token, only: [:datafile]

  def datafile

    @dataset = Dataset.find_by_key(params['dataset_key'])

    raise ActiveRecord::RecordNotFound unless @dataset

    # Rails.logger.warn params.to_yaml

    if params.has_key?('binary')

      begin
          df = Datafile.create(dataset_id: @dataset.id)

          uploaded_io = params['binary']

          df.storage_root = Application.storage_manager.draft_root.name
          df.binary_name = uploaded_io.original_filename
          df.storage_key = File.join(df.web_id, df.binary_name)
          df.binary_size = uploaded_io.size
          df.mime_type = uploaded_io.content_type

          # Moving the file to some safe place; as tmp files will be flushed timely
          Application.storage_manager.draft_root.copy_io_to(df.storage_key, uploaded_io, nil, uploaded_io.size)

          df.save

          render json: "successfully uploaded #{df.binary_name}\nsee in dataset at #{IDB_CONFIG[:root_url_text]}/datasets/#{@dataset.key} \n", status: 200
        rescue Exception => ex
          Rails.logger.warn ex.message
          render json: "#{ex.message}\n", status: 500
      end

    elsif params.has_key?('tus_url') && params.has_key?('filename') && params.has_key?('size')

      begin
        df = Datafile.create(dataset_id: @dataset.id)
        tus_url = params[:tus_url]
        tus_url_arr = tus_url.split('/')
        tus_key = tus_url_arr[-1]

        df.storage_root = Application.storage_manager.draft_root.name
        df.binary_name = params[:filename]
        df.storage_key = tus_key
        df.binary_size = params[:size]

        df.save

        render json: "successfully uploaded #{df.binary_name}\nsee in dataset at #{IDB_CONFIG[:root_url_text]}/datasets/#{@dataset.key} \n", status: 200
      rescue Exception => ex
        Rails.logger.warn ex.message
        render json: "#{ex.message}\n", status: 500
      end

    elsif params.has_key?('phase')
      begin

        unless params.has_key?('phase')
          render json: "missing paramter: phase", status: 400
        end
        unless params.has_key?('filename')
          render json: "missing paramter: filename", status: 400
        end

        case params['phase']
          when 'setup'

            @dataset.ordered_datafiles.each do |datafile|
              if datafile.bytestream_name == params['filename']
                raise "File with the name #{params['filename']} already exists in this dataset."
              end
            end

            raise "missing paramter: filesize" unless params.has_key?('filesize')

            raise "File too large. Max file size: 2TB." if (params['filesize']).to_i > 2199023255552

            if File.directory?("#{IDB_CONFIG[:datafile_store_dir]}/api/#{@dataset.key}")
              FileUtils.rm_rf("#{IDB_CONFIG[:datafile_store_dir]}/api/#{@dataset.key}")
            end

            FileUtils::mkdir_p "#{IDB_CONFIG[:datafile_store_dir]}/api/#{@dataset.key}"
            FileUtils.touch("#{IDB_CONFIG[:datafile_store_dir]}/api/#{@dataset.key}/#{params['filename']}")
            if File.exists?("#{IDB_CONFIG[:datafile_store_dir]}/api/#{@dataset.key}/#{params['filename']}")
              render json: "successfully set up #{params['filename']}", status: 200
            else
              render json: "error setting up #{params['filename']}", status: 500
            end

          when 'transfer'

            begin

              raise "missing paramater: previous_size" unless params.has_key?('previous_size')

              raise "missing bytechunk" unless params.has_key?('bytechunk')

              writepath = "#{IDB_CONFIG[:datafile_store_dir]}/api/#{@dataset.key}/#{params['filename']}"

              written_size = File.size(writepath)

              raise "File too large. Max file size: 2TB." if written_size > 2199023255551

              unless(params['previous_size'].to_i == written_size.to_i)
                raise("Unexpected previous_size value.  Expected: #{written_size.to_s}, Recieved: #{params['previous_size']}")
              end

              File.open(writepath, "a") do |f|
                f.write(File.read(params['bytechunk'].open))
              end

              render json: "successfully added chunk to #{params['filename']}", status: 200
            rescue Exception::StandardError => ex
              Rails.logger.warn ex.message
              render json: {error: "#{ex.message}\n", progress: File.size(writepath), status: 500}
            end

          when 'verify'
            #raise "missing checksum" unless params.has_key?('checksum')

            writepath = "#{IDB_CONFIG[:datafile_store_dir]}/api/#{@dataset.key}/#{params['filename']}"

            #local_checksum = md5(writepath).to_s

            #if (params['checksum']).to_s.eql?(local_checksum)
            if true

              df = Datafile.create(dataset_id: @dataset.id)
              df.binary = Pathname.new(writepath).open
              df.save

              unless df && df.binary && df.binary.file && df.binary.file.size > 0
                raise 'Error uploading file. If error persists, please contact the Research Data Service.'
                df.destroy if df
              end

              render json: "#{params['filename']} successfully uploaded.  Refresh dataset page to see newly uploaded file. #{IDB_CONFIG[:root_url_text]}/datasets/#{@dataset.key}/edit", status: 200
            # else
            #   render json: {error: "upload error, checksum verification failed", checksum: local_checksum,  progress: File.size(writepath), status: 500}
            end

          else
            render json: "invalid phase parameter: #{params['phase']}", status: 400
        end


      rescue Exception::StandardError => ex
        Rails.logger.warn ex.message
        render json: "#{ex.message}\n", status: 500
      end
    else
      render json: "invalid request", status: 500

    end


  end

  protected

  def authenticate
    # Rails.logger.warn params
    if params.has_key?(:dataset_key)
      @dataset = Dataset.find_by_key(params[:dataset_key])
      if @dataset  && @dataset.publication_state == Databank::PublicationState::DRAFT
        authenticate_token || render_unauthorized
      else
        render_not_found
      end
    end
  end

  def authenticate_token
    authenticate_or_request_with_http_token do |token, options|
      identified_tokens = Token.where("identifier = ? AND dataset_key = ? AND expires > ?", token, @dataset.key, DateTime.now)
      if identified_tokens.count == 1
        return identified_tokens.first
      elsif identified_token > 1
        identified_tokens.destroy_all
        return nil
      else
        return nil
      end
    end
  end

  def render_unauthorized
    self.headers['WWW-Authenticate'] = 'Token realm="Application"'
    render json: 'Bad credentials', status: 401
  end

  def render_not_found
    render json: 'Dataset Not Found', status: 404
  end

  def md5(fname)
    md5 = Digest::MD5.new
    File.open(fname, 'rb') do |f|
      # Read in 2MB chunks to limit memory usage
      while chunk = f.read(2097152)
        md5.update chunk
      end
    end
     md5
  end

end
