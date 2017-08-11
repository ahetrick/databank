json.dataset_downloads @dataset_download_tallies do |row|
  json.doi row.doi
  json.date row.download_date
  json.tally  row.tally
end