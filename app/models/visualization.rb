class Visualization < ActiveRecord::Base
  def dataset
    Dataset.find_by(key: dataset_key)
  end
  def datafile
    Datafile.find_by(web_id: datafile_web_id)
  end
end
