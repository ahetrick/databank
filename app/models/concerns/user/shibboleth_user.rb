module ShibbolethUser
  extend ActiveSupport::Concern

  class_methods do

    def from_shibboleth(auth)
      if auth && auth[:uid]
        user = find_by_provider_and_uid(auth["provider"], auth["uid"])

        if user
          user.update_with_omniauth(auth)
          user.save
        else
          user = User.create_with_omniauth(auth)
        end

        return user

      else
        return nil
      end
    end

    def shibboleth_role(auth)
      
      role = "guest"

      if uid.respond_to?(:split)

        netid = uid.split('@').first

        if netid.respond_to?(:length) && netid.length > 0

          admins = IDB_CONFIG[:admin_list].split(", ")

          if admins.include?(netid)
            role = "admin"
          elsif can_deposit(netid)
            role = "depositor"
          else
            role = "no_deposit"
          end
        end

      end

      role

    end

  end

end
