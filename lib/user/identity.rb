# This type of user comes from the identity authentication strategy

require_relative '../user'

class User::Identity < User::User

  def self.from_omniauth(auth)
    if auth && auth[:uid]
      identity = Identity.find_by_email(auth["info"]["email"])
      if identity&.activated
        user = User::Identity.find_by_provider_and_uid(auth["provider"], auth["uid"])
        if user
          user.update_with_omniauth(auth)
        else
          user = User::Identity.create_with_omniauth(auth)
        end
        return user
      else
        return nil
      end
    else
      return nil
    end
  end

  def self.create_with_omniauth(auth)
    invitee = Invitee.find_by_email(auth["info"]["email"])
    if invitee&.expires_at >= Time.current
      create! do |user|
        user.provider = auth["provider"]
        user.uid = auth["uid"]
        user.email = auth["info"]["email"]
        user.name = auth["info"]["name"]
        user.username = user.email
        user.role = user_role(user.email)
      end
    else
      return nil
    end
  end

  def update_with_omniauth(auth)
    update_attribute(:provider, auth["provider"])
    update_attribute(:uid, auth["uid"])
    update_attribute(:email, auth["info"]["email"])
    update_attribute(:username, self.email.split('@').first)
    update_attribute(:name, auth["info"]["name"])
    update_attribute(:role, User::Identity.user_role(self.email))
    self
  end

  def self.user_role(email)
    invitee = Invitee.find_by_email(email)
    if invitee
      return invitee.role
    else
      return Databank::UserRole::GUEST
    end
  end

  def self.can_deposit(email)
    # Depositing is only for current members of the University, who could log in with Shibboleth
    false
  end

  def self.user_info_string(email)
    email
  end

  def self.user_display_name(email)
    identity = Identity.find_by_email(email)
    if identity
      return identity.name
    else
      return email
    end
  end

end



