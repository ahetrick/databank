# frozen_string_literal: true

class IllinoisExpertsClient
  include ActiveModel::Conversion
  include ActiveModel::Naming

  ENDPOINT = IDB_CONFIG[:illinois_experts][:endpoint]
  KEY = IDB_CONFIG[:illinois_experts][:key]
  private_constant :ENDPOINT
  private_constant :KEY

  def self.persons(email)
    return nil unless email

    uri = URI.parse("#{ENDPOINT}/persons/#{email}")

    return nil unless uri.respond_to?(:request_uri)

    request = Net::HTTP::Get.new(uri.request_uri)
    request.add_field("api-key", KEY)

    sock = Net::HTTP.new(uri.host, uri.port)
    sock.set_debug_output $stderr
    sock.use_ssl = true


    begin

      response = sock.start {|http| http.request(request) }
    rescue Net::HTTPBadResponse, Net::HTTPServerError
      return nil
    end

    case response
    when Net::HTTPSuccess, Net::HTTPCreated, Net::HTTPRedirection
      return response.body
    else
      return nil
    end
  end

  def self.example
    uri = URI.parse("#{ENDPOINT}/datasets")

    request = Net::HTTP::Get.new(uri.request_uri)
    request.add_field("api-key", KEY)

    sock = Net::HTTP.new(uri.host, uri.port)
    sock.set_debug_output $stderr
    sock.use_ssl = true

    begin
      response = sock.start {|http| http.request(request) }
    rescue Net::HTTPBadResponse, Net::HTTPServerError
      return nil
    end

    case response
    when Net::HTTPSuccess, Net::HTTPCreated, Net::HTTPRedirection
      return response.body
    else
      return nil
    end
  end

  def self.email_exist?(email)
    !IllinoisExpertsClient.persons(email).nil?
  end

end
