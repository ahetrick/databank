class SessionsController < ApplicationController

  skip_before_action :verify_authenticity_token

  def new
    session[:login_return_referer] = request.env['HTTP_REFERER']
    if IDB_CONFIG.has_key?(:local_mode) && IDB_CONFIG[:local_mode]
      redirect_to('/auth/identity')
    else
      redirect_to(shibboleth_login_path(Databank::Application.shibboleth_host))
    end
  end

  def create
    #raise request.env["omniauth.auth"].to_yaml
    auth = request.env["omniauth.auth"]

    if auth && auth[:uid]

      return_url = clear_and_return_return_path
      user = User.find_by_provider_and_uid(auth["provider"], auth["uid"])

      if user
        user.update_with_omniauth(auth)
        user.save
      else
        user = User.create_with_omniauth(auth)
      end


      if user.id
        session[:user_id] = user.id
      else
        unauthorized
      end

      if user.role == 'no_deposit'
        redirect_to root_url, notice: "ACCOUNT NOT ELIGABLE TO DEPOSIT DATA.<br/>Faculty, staff, and graduate students are eligable to deposit data in Illinois Data Bank.<br/>Please <a href='/help'>contact the Research Data Service</a> if this determination is in error, or if you have any questions."
      else
        redirect_to return_url
      end

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

  def role_switch
    new_role = params['role']
    if ['depositor', 'guest', 'no_deposit'].include?(new_role)
      current_user.role = new_role
      current_user.save
      new_role_text = "new role"
      case new_role
        when 'depositor'
          new_role_text = "depositor"
        when 'guest'
          new_role_text = "guest"
        when 'no_deposit'
          new_role_text = "undergrad, or other authenticated but not authorized agent"
      end

      redirect_to root_url, notice: "Successfully switched role to #{new_role_text}."
    else
      redirect_to root_url, notice: "Unable to switch roles."
    end


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
