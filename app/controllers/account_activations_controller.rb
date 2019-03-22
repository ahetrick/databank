class AccountActivationsController < ApplicationController
  def edit
    identity = Identity.find_by(email: params[:email])
    if identity && !identity.activated? && identity.authenticated?(:activation, params[:id])
      identity.update_attribute(:activated,    true)
      identity.update_attribute(:activated_at, Time.zone.now)
      if identity.group == Databank::IdentityGroup::NETWORK_CURATOR
        redirect_to '/data_curation_network', alert: "Account activated! Log in here."
      else
        redirect_to '/', alert: "Account activated!"
      end
    else
      redirect_to root_url, alert: "Invalid activation link"
    end
  end
end
