class User < ActiveRecord::Base

  ROLES = %w[admin depositor guest]

  def is? (requested_role)
    self.role == requested_role.to_s
  end

  def self.user_role(email)

    role = "guest"

    if email.respond_to?(:split)

      netid = email.split('@')[0]

      if netid.respond_to?(:length) && netid.length > 0

        admins = IDB_CONFIG[:admin_list].split(", ")

        if admins.include?(netid)
          role = "admin"
        else
          role = "depositor"
        end
      end

    end

    role

  end

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.name = auth["info"]["name"]
      user.email = auth["info"]["email"]
      user.role = user_role(auth["info"]["email"])
    end
  end


end
