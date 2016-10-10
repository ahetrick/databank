Given(/^Draft datasets exist titled:$/) do |table|
  table.headers.each do |header|
    dataset = FactoryGirl.create(:dataset, title: header)
    creator = FactoryGirl.create(:creator, given_name: "Daisy", dataset_id: dataset.id)
  end
end

Given(/^Published datasets exist titled:$/) do |table|
  table.headers.each do |header|
    dataset = FactoryGirl.create(:dataset, title: header, publication_state: "released")
    dataset.identifier =  "10.5027/FK2#{dataset.key}_V1"
    dataset.save
    creator = FactoryGirl.create(:creator, dataset_id: dataset.id)
  end
end

Given(/^I enter search phrase: (.*)$/) do |search_string|

  fill_in("Search", with: search_string)

end