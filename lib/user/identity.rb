# This type of user comes from the identity authentication strategy

require_relative '../user'

class User::Identity < User::User

  def self.from_omniauth(auth)
    raise "not yet implemented"
  end

  def self.create_with_omniauth(auth)
    raise "not yet implemented"
  end

  def update_with_omniauth(auth)
    raise "not yet implemented"
  end

  def self.user_role(email)
    raise "not yet implemented"
  end

  def self.can_deposit(email)
    # Depositing is only for current members of the University, who could log in with Shibboleth
    false
  end

  def self.user_info_string(email)
    raise "not yet implemented"
  end

  def self.user_display_name(email)
    raise "not yet implemented"
  end

end



