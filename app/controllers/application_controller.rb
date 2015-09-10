class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  helper_method :current_user

  include CanCan::ControllerAdditions

  rescue_from Exception::StandardError, with: :error_occurred

  protected

  def error_occurred(exception)

    if exception.class == CanCan::AccessDenied

      alert_message = exception.message

      if exception.subject.class == Dataset && exception.action == :new
        alert_message = "Log in to deposit data."
      end

      redirect_to main_app.root_url, :alert => alert_message

    else

      Rails.logger.error "\n***---***"
      Rails.logger.error exception.class
      Rails.logger.error exception.message
      exception.backtrace.each { |line| Rails.logger.error line }

      render :file => File.join(Rails.root, 'public', '500.html')
    end

  end


  private

  def current_user

    begin
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    rescue ActiveRecord::RecordNotFound
      session[:user_id] = nil
    end

  end
end
