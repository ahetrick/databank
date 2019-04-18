xml.instruct!
xml.datasets do
  @datasets.each do |dataset|
    xml.title dataset.title
    xml.description dataset.description
  end
end