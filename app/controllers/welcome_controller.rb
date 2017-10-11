class WelcomeController < ApplicationController
  def index
    active_featured_researchers = FeaturedResearcher.where(is_active: true)
    if active_featured_researchers.count > 0
      @featured_researcher = active_featured_researchers.order("RANDOM()").first
    end

  end
  def sitemap
    sitemap_path = Rails.root.join('public', 'sitemaps', 'sitemap.xml.gz')
    send_file sitemap_path, type: 'application/x-gzip'
  end
end
