# frozen_string_literal: true

require 'rest-client'
require 'uri'

# represents a related material as defined in DataCite metadata schema
class RelatedMaterial < ActiveRecord::Base
  include ActiveModel::Serialization
  belongs_to :dataset
  audited associated_with: :dataset

  def as_json(*)
    super(only: %i[material_type
                   availability
                   link
                   uri
                   uri_type
                   citation
                   dataset_id
                   created_at
                   updated_at])
  end

  def relationship_arr
    if datacite_list && datacite_list != ''
      datacite_list.split(',')
    else
      []
    end
  end

  def nonversion_relationships
    relationship_arr - %w[IsPreviousVersionOf IsNewVersionOf]
  end

  def link_status
    unless nonversion_relationships.count.positive?
      return 'no non-version related materials'
    end

    return 'no link' unless link

    return 'invalid url' unless link =~ /\A#{URI.regexp(%w[http https])}\z/

    link_attempt_status
  end

  def report_row
    return '' unless nonversion_relationships.count.positive?

    "<tr><td>#{dataset.identifier}</td>\
<td>#{IDB_CONFIG[:root_url_text]}/datasets/#{dataset.key}</td>\
<td>#{selected_type}</td><td>#{nonversion_relationships}</td>\
<td>#{link}</td><td>#{link_status}</td></tr>"
  end

  # html string of link report table
  def self.link_report
    datasets = Dataset.where(is_test: false).select(&:metadata_public?)
    report = "<table border='1'><tr>\
<th>DOI</th><th>Dataset_URL</th><th>Material_Type</th><th>Relationship</th>\
<th>Material_URL</th><th>Status_Code</th></tr>"
    datasets.each do |dataset|
      dataset.related_materials.each do |material|
        report += material.report_row
      end
    end
    report += '</table>'
  end

  private

  # link status given a validly formatted link
  def link_attempt_status
    RestClient.get link
  rescue RestClient::Unauthorized, RestClient::Forbidden => err
    'access denied'
  rescue RestClient::RequestTimeout
    'timeout'
  rescue RestClient::SSLCertificateNotVerified
    'SSL certificate not verified'
  rescue RestClient::Exception
    'invalid or unresponsive'
  else
    'ok'
  end
end
