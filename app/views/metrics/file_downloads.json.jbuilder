json.file_downloads @file_download_tallies do |row|
  json.doi row.doi
  json.file row.filename
  json.date row.download_date
  json.tally  row.tally
end