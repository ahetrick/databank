require "browser"

module DatafilesHelper
  module_function

  def text_preview(datafile)
    datafile.with_input_io do |io|
      io.readline(nil, 500)
    end
  end

  #In this and datafile_view_link if possible we give a direct link to the content,
  # otherwise we direct through a controller action to get it. The difference in our
  # case is storage in S3 versus storage on the filesystem
  def datafile_download_link(datafile)
    case datafile.current_root.root_type
    when :filesystem
      download_datafile_path(datafile.web_id)
    when :s3
      datafile.current_root.presigned_get_url(datafile.storage_key, response_content_disposition: disposition('attachment', datafile),
                                              response_content_type: safe_content_type(datafile))
    else
      raise "Unrecognized storage root type #{datafile.storage_root.type}"
    end
  end

  def datafile_view_link(datafile)
    case datafile.current_root.root_type
    when :filesystem
      view_datafile_path(datafile)
    when :s3
      datafile.current_root.presigned_get_url(datafile.storage_key, response_content_disposition: disposition('inline', datafile),
                                              response_content_type: safe_content_type(datafile))
    else
      raise "Unrecognized storage root type #{datafile.current_root.type}"
    end
  end

  def datafile_content_preview_link(datafile)
    case datafile.current_root.root_type
    when :filesystem
      preview_content_datafile_path(datafile)
    when :s3
      datafile.current_root.presigned_get_url(datafile.storage_key, response_content_disposition: disposition('inline', datafile),
                                              response_content_type: safe_content_type(datafile))
    else
      raise "Unrecognized storage root type #{datafile.current_root.type}"
    end
  end

  def disposition(type, datafile)

    if browser.chrome? or browser.safari?
      %Q(#{type}; filename="#{datafile.name}"; filename*=utf-8"#{URI.encode(datafile.name)}")
    elsif browser.firefox?
      %Q(#{type}; filename="#{datafile.name}")
    else
      %Q(#{type}; filename="#{datafile.name}"; filename*=utf-8"#{URI.encode(datafile.name)}")
    end
  end

  def safe_content_type(datafile)
    datafile.mime_type || 'application/octet-stream'
  end


end
