json.array!(@datafiles) do |datafile|
  json.extract! datafile, "dataset" => "", "download_link" => "datafile/#{datafile.web_id}/download"
  json.url datafile_url(datafile, format: :json)
end
