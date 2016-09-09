require 'fileutils'
require 'digest/md5'

class ApiDatasetController < ApplicationController

  before_action :authenticate, except: [:index]
  skip_before_action :verify_authenticity_token, only: [:datafile, :upload]

  def index
  end

  def datafile
    Rails.logger.warn params.to_yaml

    if params.has_key?('binary')

      begin
          df = Datafile.create(dataset_id: @dataset.id, binary: params['binary'])

          unless df && df.binary && df.binary.file && df.binary.file.size > 0
            raise 'Error uploading file. If error persists, please contact the Research Data Service.'
            df.destroy if df
          end

          render json: "successfully uploaded #{df.binary.file.filename}\nsee in dataset at #{IDB_CONFIG[:root_url_text]}/datasets/#{@dataset.key} \n", status: 200
        rescue Exception::StandardError => ex
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

            raise "missing paramater: previous_size" unless params.has_key?('previous_size')
            raise "missing bytechunk" unless params.has_key?('bytechunk')

            writepath = "#{IDB_CONFIG[:datafile_store_dir]}/api/#{@dataset.key}/#{params['filename']}"
            begin
              File.open(writepath, "a") do |f|
                f.write(File.read(params['bytechunk'].open))
              end
              render json: "successfully added chunk to #{params['filename']}", status: 200
            rescue Exception::StandardError => ex
              Rails.logger.warn ex.message
              render json: "#{ex.message}\n", status: 500
            end

          when 'verify'
            raise "missing checksum" unless params.has_key?('checksum')

            writepath = "#{IDB_CONFIG[:datafile_store_dir]}/api/#{@dataset.key}/#{params['filename']}"

            Rails.logger.warn "#{params['checksum']}"
            Rails.logger.warn "#{md5(writepath)}"

            if (params['checksum']).to_s.eql?(md5(writepath).to_s)

              df = Datafile.create(dataset_id: @dataset.id)
              df.binary = Pathname.new(writepath).open
              df.save

              unless df && df.binary && df.binary.file && df.binary.file.size > 0
                raise 'Error uploading file. If error persists, please contact the Research Data Service.'
                df.destroy if df
              end

              render json: "#{params['filename']} successfully uploaded.  Refresh dataset page to see newly uploaded file. #{IDB_CONFIG[:root_url_text]}/datasets/#{@dataset.key}/edit", status: 200
            else
              render json: "upload error, checksum verification failed", status: 500
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
