require 'rubygems'
require 'sitemap_generator'

SitemapGenerator::Sitemap.default_host = IDB_CONFIG[:root_url_text]
SitemapGenerator::Sitemap.create do
  Dataset.all.each do |dataset|
    if [Databank::PublicationState::RELEASED, Databank::PublicationState::FILE_EMBARGO].include?(dataset.publication_state)
      add dataset_url(dataset, host: IDB_CONFIG[:root_url_text])
    end
  end
  add '/', :changefreq => ', monthly', :priority => 0.1
  add '/help', :changefreq => 'monthly', :priority => 0.1
  add '/policy', :changefreq => 'monthly', :priority => 0.1
end
SitemapGenerator::Sitemap.ping_search_engines # Not needed if you use the rake tasks