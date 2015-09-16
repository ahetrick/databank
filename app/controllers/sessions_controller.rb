class SessionsController < ApplicationController

  skip_before_action :verify_authenticity_token

  def new
    session[:login_return_referer] = request.env['HTTP_REFERER']
    # redirect_to('/auth/identity')
    redirect_to(shibboleth_login_path(Databank::Application.shibboleth_host))
  end
  def create
    #raise request.env["omniauth.auth"].to_yaml
    auth = request.env["omniauth.auth"]

    if auth && auth[:uid]

      return_url = clear_and_return_return_path
      user = User.find_by_provider_and_uid(auth["provider"], auth["uid"]) || User.create_with_omniauth(auth)
      session[:user_id] = user.id
      redirect_to return_url

    else
      unauthorized
    end


  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url
  end

  def unauthorized
    redirect_to root_url, notice: "The supplied credentials could not be authenciated."
  end

  protected

  def clear_and_return_return_path
    return_url = session[:login_return_uri] || session[:login_return_referer] || root_path
    session[:login_return_uri] = session[:login_return_referer] = nil
    reset_session
    return_url
  end

  def shibboleth_login_path(host)
    "/Shibboleth.sso/Login?target=https://#{host}/auth/shibboleth/callback"
  end

end
