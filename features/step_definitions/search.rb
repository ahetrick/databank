Given(/^Draft datasets exist titled:$/) do |table|
  table.headers.each do |header|
    dataset = FactoryBot.create(:dataset, title: header)
    creator = FactoryBot.create(:creator, given_name: "Daisy", dataset_id: dataset.id)
  end
end

Given(/^Published datasets exist titled:$/) do |table|
  table.headers.each do |header|
    dataset = FactoryBot.create(:dataset, title: header, publication_state: "released")
    dataset.identifier =  "10.5027/FK2#{dataset.key}_V1"
    dataset.save
    creator = FactoryBot.create(:creator, dataset_id: dataset.id)
  end
end

Given(/^I enter search phrase: (.*)$/) do |search_string|
  fill_in("q", with: search_string)
end

Given(/^Draft datasets by someone else exist titled:$/) do |table|
  table.headers.each do |header|
    dataset = FactoryBot.create(:dataset, title: header, depositor_name: "Victor Cedarstaff", depositor_email: "other@mailinator.com")
    creator = FactoryBot.create(:creator, given_name: "Victor", family_name: "Cedarstaff", email: "other@mailinator.com", dataset_id: dataset.id)
  end
end

Given(/^Datasets published by someone else exist titled:$/) do |table|
  table.headers.each do |header|
    dataset = FactoryBot.create(:dataset, title: header, publication_state: "released", depositor_name: "Victor Cedarstaff", depositor_email: "other@mailinator.com")
    dataset.identifier =  "10.5027/FK2#{dataset.key}_V1"
    dataset.save
    creator = FactoryBot.create(:creator, dataset_id: dataset.id)
  end
end
