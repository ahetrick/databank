class WelcomeController < ApplicationController
  def index
  end
  def sitemap
    sitemap_path = Rails.root.join('public', 'sitemap', 'sitemap.xml.gz')
    send_file sitemap_path, type: 'application/x-gzip'
  end
end
