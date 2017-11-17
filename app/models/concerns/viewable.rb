module Viewable
  extend ActiveSupport::Concern

  def preview
    if is_txt?

      filestring = File.read(self.bytestream_path)

      if filestring
        chardet = CharDet.detect(filestring)
        if chardet
          detected_encoding = chardet['encoding']

          #Rails.logger.warn "\n***\n#{detected_encoding}\n***\n"

          if detected_encoding == "UTF-8"
            return filestring
          else
            return filestring.encode('utf-8', detected_encoding, :invalid => :replace, :undef => :replace, :replace => '')
          end
        else
          return "no text detected in file"
        end
      else
        return "no content detected"
      end

    elsif is_archive?
      return archive_listview(self.bytestream_name.split(".").last)

    else
      "no text preview available"
    end
  end


  def archive_listview(extension)
    case extension

      when 'zip'
        entry_list_text = `unzip -l "#{self.bytestream_path}"`
        filepaths_arr = Array.new

        entry_list_array = entry_list_text.split("\n")

        entry_list_array.each_with_index do |raw_entry, index|
          if index > 2  && index < (entry_list_array.length - 2) # first three lines are headers, last two lines are summary
            entry_array = raw_entry.strip.split " "
            filepaths_arr.push(entry_array[-1])
          end
        end

        return filepaths_arr_to_html(filepaths_arr)

      when '7z'

        entry_list_text = `7za l "#{self.bytestream_path}"`

        filepaths_arr = Array.new

        entry_list_array = entry_list_text.split("\n")

        entry_list_array.each_with_index do |raw_entry, index|
          if index > 19  && index < (entry_list_array.length - 2) # first twenty lines are headers, last two lines are summary
            entry_array = raw_entry.strip.split " "
            filepaths_arr.push(entry_array[-1]) if entry_array[-1]
          end
        end

        return filepaths_arr_to_html(filepaths_arr)

      when 'gz'

        inside_extension = ''
        filename_arr = self.bytestream_name.split(".")
        if filename_arr.length > 1
          inside_extension = filename_arr[-2]
        end

        case inside_extension

          when 'tar'

            entry_list_text = `tar -tf "#{self.bytestream_path}"`

            return filepaths_arr_to_html(entry_list_text.split("\n"))

          else
            return filepaths_arr_to_html([self.bytestream_name.chomp('.gz')])
        end


      #return 'listing of gz files not yet implemented'

      when 'tar'
        entry_list_text = `tar -tf "#{self.bytestream_path}"`
        return filepaths_arr_to_html(entry_list_text.split("\n"))

      else
        return "no listing available for this format"

    end
  end

  def filepaths_arr_to_html(filepaths_arr)

    return_string = '<span class="glyphicon glyphicon-folder-open"></span> '

    return_string << self.bytestream_name

    filepaths_arr.each do |filepath|

      if filepath.exclude?('__MACOSX/')

        name_arr = filepath.split("/")

        name_arr.length.times do
          return_string << "<div class='indent'>"
        end

        if filepath[-1] == "/" # means directory
          return_string << '<span class="glyphicon glyphicon-folder-open"></span> '

        else
          return_string << '<span class="glyphicon glyphicon-file"></span> '
        end

        return_string << name_arr.last
        name_arr.length.times do
          return_string << "</div>"
        end
      end

    end

    return return_string

  end

  def is_archive?
    name_arr = self.bytestream_name.split(".")
    # wish_list = ["gz", "tar", 'zip', '7z', 'bz', 'bz2', 'bzip2']
    ['gz', 'tar', 'zip', '7z'].include?(name_arr.last.downcase)
  end


  def is_txt?
    if self.bytestream_name == ""
      return false
    else
      filename_split = self.bytestream_name.split(".")
      extension = filename_split.last
      return ['txt', 'csv', 'tsv', 'rb', 'xml', 'json', 'py'].include?(extension.downcase)
    end

  end

  def is_image?
    if self.bytestream_name == ""
      return false
    else
      filename_split = self.bytestream_name.split(".")
      extension = filename_split.last
      return ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'jpg2', 'tif', 'tiff'].include?(extension.downcase)
    end
  end

  def is_microsoft?
    if self.bytestream_name == ""
      return false
    else
      filename_split = self.bytestream_name.split(".")
      extension = filename_split.last
      return ['doc', 'docx', 'xls', 'xslx', '.ppt', 'pptx' ].include?(extension.downcase)
    end
  end

  def microsoft_preview_url
    if self.is_microsoft?

      dataset = Dataset.find(self.dataset_id)

      return "https://view.officeapps.live.com/op/view.aspx?src=https%3A%2F%2Fdatabank.illinois.edu%2Fdatasets%2F#{dataset.key}%2Fdatafiles%2F#{self.web_id}%2Fdisplay"

    else
      raise "Microsoft preview url requested for non-Microsoft file."

    end
  end

  def mime_type
    if self.bytestream_name == ""
      return nil
    else
      filename_split = self.bytestream_name.split(".")
      extension = filename_split.last
      case extension
        when 'png'
          return 'image/png'
        when 'jpg', 'jpeg', 'jpg2'
          return 'image/jpeg'
        when 'bmp'
          return 'image/bmp'
        when 'gif'
          return 'image/gif'
        when 'pdf'
          return 'application/pdf'
        else
          return 'application/octet-stream'
      end
    end
  end


end
