class WelcomeController < ApplicationController
  def index
    @featured_dataset = Dataset.find_by_key(IDB_CONFIG["featured"]["key"])
  end
  def sitemap
    sitemap_path = Rails.root.join('public', 'sitemaps', 'sitemap.xml.gz')
    send_file sitemap_path, type: 'application/x-gzip'
  end
end
