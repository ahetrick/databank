# frozen_string_literal: true

module Identifiable
  extend ActiveSupport::Concern

  URI_BASE = "#{IDB_CONFIG[:datacite_rest_base]}/dois"
  CLIENT_ID = IDB_CONFIG[:datacite_username]
  PASSWORD = IDB_CONFIG[:datacite_password]

  private_constant :URI_BASE
  private_constant :CLIENT_ID
  private_constant :PASSWORD

  class Event
    PUBLISH = "publish"
    REGISTER = "register"
    HIDE = "hide"
  end

  class Action
    CREATE = "create"
    DELETE = "delete"
  end

  def registered_doi?
    # all findable dois are also registered
    return false unless %w[findable registered].include?(datacite_state)

    true
  end

  def findable_doi?
    datacite_state == "findable"
  end

  def doi_state
    info = doi_infohash
    return nil unless info.has_key?(:data)
    return nil unless info[:data].has_key?(:attributes)
    return nil unless info[:data][:attributes].has_key?(:state)

    info[:data][:attributes][:state]
  end

  def default_identifier
    "#{IDB_CONFIG[:datacite_shoulder]}#{dataset.key}_V1"
  end

  def create_draft_doi
    # can only draft doi for existing dataset with existing identifier
    return nil unless dataset_identifer_exist?

    # should not draft doi if doi record already exists in DataCite
    return nil if doi_infohash.has_key(:data)

    # minimal json to create draft record
    draft_hash = {data: {type: "dois", attributes: {doi: dataset.identifier}}}
    draft_json = draft_hash.to_json
    response = Doi.post_to_datacite(dataset.identifier, draft_json)
    Rails.logger.warn response
  end

  # publish - Triggers a state move from draft or registered to findable
  def publish_doi(target_state); end

  # register - Triggers a state move from draft to registered
  def register_doi; end

  # hide - Triggers a state move from findable to registered
  def hide_doi; end

  def self.post_to_datacite(identifier, json_body)
    url = URI("#{URI_BASE}/#{identifier}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(url)
    request["accept"] = "application/vnd.api+json"
    request.basic_auth(CLIENT_ID, PASSWORD)
    request.body = json_body
    http.request(request)
  end

  private_class_method :post_to_datacite

  private

  def doi_infohash
    response = doi_info_from_datacite
    case response

    when Net::HTTPUnauthorized
      raise("credentials could not be verified")
    when Net::HTTPUnprocessableEntity
      raise("bad get_doi request for dataset: #{dataset.key}")
    when Net::HTTPNotFound
      return {}
    when Net::HTTPSuccess, Net::HTTPRedirection
      raise("response not valid JSON: #{response}") unless json?(response)

      return JSON.parse(response, symbolize_names: true)
    else
      raise("unexpected response from DataCite for #{doi}: #{response}")
    end
  end

  def doi_info_from_datacite
    raise("dataset identifier does not exist") unless dataset_identifer_exist?

    url = URI("#{URI_BASE}/#{dataset.identifier}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(url)
    request["accept"] = "application/vnd.api+json"
    request.basic_auth(CLIENT_ID, PASSWORD)
    http.request(request)
  end

  def dataset_identifer_exist?
    !dataset.nil? && !dataset.identifier.nil? && !dataset.identifer.empty?
  end

  def json?(string)
    JSON.parse(string)
    true
  rescue JSON::ParserError
    false
  end


  end

