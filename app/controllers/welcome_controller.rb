class WelcomeController < ApplicationController
  def index
    @featured_researcher = FeaturedResearcher.get_featured_researcher
  end
  def sitemap
    sitemap_path = Rails.root.join('public', 'sitemaps', 'sitemap.xml.gz')
    send_file sitemap_path, type: 'application/x-gzip'
  end
end
