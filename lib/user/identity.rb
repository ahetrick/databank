# This type of user comes from the identity authentication strategy

require_relative '../user'

class User::Identity < User::User

  def self.from_omniauth(auth)
    if auth && auth[:uid]
      user = User::Identity.find_by_provider_and_uid('identity', auth['uid'])
      if user
        user.update_with_omniauth(auth)
        user.save
      else
        user = User::Identity.create_with_omniauth(auth)
      end
      return user
    else
      return nil
    end
  end

  def self.create_with_omniauth(auth)

    Rails.logger.warn auth.to_yaml

    invitee = Invitee.find_by_email(auth["info"]["email"])
    if invitee && invitee.expires_at >= Time.now
      create! do |user|
        user.provider = auth["provider"]
        user.uid = auth["uid"]
        user.email = auth["info"]["email"]
        user.name = auth["info"]["name"]
        user.username = user.email
        user.role = user_role(user.email)
      end
    else
      raise("Could not find current invitee: #{auth}")
    end

  end

  def update_with_omniauth(auth)
    Rails.logger.warn auth.to_yaml

    self.provider = auth["provider"]
    self.uid = auth["uid"]
    self.email = auth["info"]["email"]
    self.username = self.email.split('@').first
    self.name = auth["info"]["name"]
    self.role = User::Identity.user_role(self.email)
  end

  def self.user_role(email)
    invitee = Invitee.find_by_email(email)
    if invitee
      return invitee.role
    else
      raise("Unable to determine role for identity: #{email}")
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



