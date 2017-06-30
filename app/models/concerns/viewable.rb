module Viewable
  extend ActiveSupport::Concern

  def preview
    if self.bytestream_name != ""
      filename_split = self.bytestream_name.split(".")

      if filename_split.count > 1 # otherwise cannot determine extension

        case filename_split.last # extension

          when 'txt', 'csv', 'tsv', 'rb', 'xml', 'json', 'TXT', 'CSV', 'XML', 'py', 'XML', 'JSON'

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
                return "no preview available"
              end


            else
              return "no preview available"
            end

          when 'zip'
            entry_list_text = `unzip -l "#{self.bytestream_path}"`

            entry_list_array = entry_list_text.split("\n")

            return_string = '<span class="glyphicon glyphicon-folder-open"></span> '

            return_string << self.bytestream_name

            entry_list_array.each_with_index do |raw_entry, index|


              if index > 2  && index < (entry_list_array.length - 1) # first three lines are headers, last line is summary

                entry_array = raw_entry.strip.split " "

                filepath = entry_array[-1]
                entry_length = entry_array[0].to_i

                if filepath && entry_length > 0

                  if filepath.exclude?('__MACOSX/')
                    name_arr = filepath.split("/")

                    Rails.logger.warn name_arr.last

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


              end


            end

            return return_string

          when '7z'

            entry_list_text = `7za l "#{self.bytestream_path}"`

            Rails.logger.warn entry_list_text

            entry_list_array = entry_list_text.split("\n")

            return_string = '<span class="glyphicon glyphicon-folder-open"></span> '

            return_string << self.bytestream_name

            entry_list_array.each_with_index do |raw_entry, index|


              if index > 19  && index < (entry_list_array.length - 2) # first three lines are headers, last two lines are summary

                entry_array = raw_entry.strip.split " "

                filepath = entry_array[-1]

                if filepath

                  name_arr = filepath.split("/")

                  Rails.logger.warn name_arr.last

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


            end

            return return_string

          else
            return "no preview available"

        end

      else
        return "no preview available"
      end

    else
      return "no preview available"
    end
  end


  def has_preview?
    if self.bytestream_name == ""
      return false
    else
      filename_split = self.bytestream_name.split(".")
      extension = filename_split.last
      if ['txt', 'csv', 'tsv', 'rb', 'xml', 'json', 'zip', '7z', 'TXT', 'CSV', 'XML', 'py', 'XML', 'JSON'].include?(extension)
        return true
      else
        return false
      end
    end

  end

  def is_image?
    if self.bytestream_name == ""
      return false
    else
      filename_split = self.bytestream_name.split(".")
      extension = filename_split.last
      if ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'jpg2', 'tif', 'tiff'].include?(extension)
        return true
      else
        return false
      end
    end
  end

  def is_microsoft?
    if self.bytestream_name == ""
      return false
    else
      filename_split = self.bytestream_name.split(".")
      extension = filename_split.last
      return ['doc', 'docx', 'xls', 'xslx', '.ppt', 'pptx' ].include?(extension)
    end
  end

  def microsoft_preview_url
    if self.is_microsoft?

      dataset = Dataset.find(self.dataset_id)

      return "https://view.officeapps.live.com/op/view.aspx?src=https%3A%2F%2Fdatabank.illinois.edu%2Fdatasets%2FIDB-0341890%2F#{dataset.key}%2Fdatafiles%2#{self.web_id}%2Fdisplay"

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