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
  fill_in("Indexable", with: search_string)
end

Given(/^Draft datasets by someone else exist titled:$/) do |table|
  table.headers.each do |header|
    dataset = FactoryGirl.create(:dataset, title: header, depositor_name: "Victor Cendarstaff", depositor_email: "other@mailinator.com")
    creator = FactoryGirl.create(:creator, given_name: "Victor", family_name: "Cedarstaff", email: "other@mailinator.com", dataset_id: dataset.id)
  end
end

Given(/^Datasets published by someone else exist titled:$/) do |table|
  table.headers.each do |header|
    dataset = FactoryGirl.create(:dataset, title: header, publication_state: "released", depositor_name: "Victor Cendarstaff", depositor_email: "other@mailinator.com")
    dataset.identifier =  "10.5027/FK2#{dataset.key}_V1"
    dataset.save
    creator = FactoryGirl.create(:creator, dataset_id: dataset.id)
  end
end