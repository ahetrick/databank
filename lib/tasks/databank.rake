require 'rake'

namespace :databank do

  desc 'delete all datasets'
  task :delete_all => :environment do
    Dataset.all.each do |dataset|
      dataset.destroy
    end
  end

  desc 'Clear datafiles'
  task :delete_files => :environment do
    Datafile.all.each do |datafile|
      datafile.destroy
    end
  end

  desc "Clear users"
  task clear_users: :environment do
    User.all.each do |user|
      user.destroy
    end
    Identity.all.each do |identity|
      identity.destroy
    end
  end

  desc "Clear Rails cache (sessions, views, etc.)"
  task clear: :environment do
    Rails.cache.clear
  end

  desc 'Create demo users'
  task :create_users => :environment do
    salt = BCrypt::Engine.generate_salt
    encrypted_password = BCrypt::Engine.hash_secret("demo", salt)

    num_accounts = 10

    (1..num_accounts).each do |i|
      identity =   Identity.find_or_create_by(email: "demo#{i}@example.edu" )
      identity.name = "Demo#{i} Depositor"
      identity.password_digest = encrypted_password
      identity.save!
    end

    # create rspec test user -- not just identity
    auth = OmniAuth.config.mock_auth[:identity]
    user = User.create_with_omniauth(auth)
    user.save!

  end

  desc 'test to_datacite_xml'
  task :testdc => :environment do
    creators_text = "Verfasser, Maria; Auteur, Henri"
    creators = creators_text.split(";")

    keywords_text = "truth; justice; the American way"
    keywords = keywords_text.split(";")

    doc = Nokogiri::XML::Document.parse(%Q(<?xml version="1.0"?><resource xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://datacite.org/schema/kernel-3" xsi:schemaLocation="http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd"></resource>))
    resourceNode = doc.first_element_child

    creatorsNode = doc.create_element('creators')
    creatorsNode.parent = resourceNode

    creators.each do |creator|
      creatorNode = doc.create_element('creator')
      creatorNode.content = creator.strip
      creatorNode.parent = creatorsNode
    end

    titlesNode = doc.create_element('titles')
    titlesNode.parent = resourceNode

    titleNode = doc.create_element('title')
    titleNode.content = "Test Dataset Title"
    titleNode.parent = titlesNode

    publisherNode = doc.create_element('publisher')
    publisherNode.content = "University of Illinois at Urbana-Champaign"
    publisherNode.parent = resourceNode

    publicationYearNode = doc.create_element('publicationYear')
    publicationYearNode.content = "2015"
    publicationYearNode.parent = resourceNode

    subjectsNode = doc.create_element('subjects')
    subjectsNode.parent = resourceNode

    keywords.each do |keyword|
      subjectNode = doc.create_element('subject')
      subjectNode.content = keyword.strip
      subjectNode.parent = subjectsNode
    end

    languageNode = doc.create_element('langauge')
    languageNode.content = "en-us"
    languageNode.parent = resourceNode

    rightsListNode = doc.create_element('rightsList')
    rightsListNode.parent = resourceNode

    rightsNode = doc.create_element('rights')
    rightsNode.content = "CC0 1.0 Universal"
    rightsNode.parent = rightsListNode

    descriptionsNode = doc.create_element('descriptions')
    descriptionsNode.parent = resourceNode

    descriptionNode = doc.create_element('description')
    descriptionNode.content = 'Test sample demo example dataset.'
    descriptionNode.parent = descriptionsNode

    resourceTypeNode = doc.create_element('resourceType')
    resourceTypeNode['resourceTypeGeneral'] = "Dataset"
    resourceTypeNode.content = "Dataset"
    resourceTypeNode.parent = resourceNode

    puts doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)

  end


end