class WelcomeController < ApplicationController
  def index
    active_featured_researchers = FeaturedResearcher.where(is_active: true)
    if active_featured_researchers.count > 0
      @featured_researcher = active_featured_researchers.order("RANDOM()").first
    end
  end

  def check_token
    if params.has_key?('token')

      identified_tokens = Token.where("identifier = ? AND expires > ?", params['token'], DateTime.now)

      if identified_tokens.count > 0
        render :json => {'isValid': true, 'token': params['token']}
      else
        render :json => {'isValid': false, 'error': 'current token not found'}
      end


    else
      render :json => {'isValid': false, 'error': 'no token provided'}
    end
  end
end
