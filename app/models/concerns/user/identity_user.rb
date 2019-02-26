module IdentityUser
  extend ActiveSupport::Concern

  class_methods do

    def from_identity(auth)

      #TODO: check activation

      if auth && auth[:uid]
        user = find_by_provider_and_uid(auth["provider"], auth["uid"])

        if user
          return user
        else
          user = User.create_with_omniauth(auth)
        end

        return user

      else
        return nil
      end
    end

  end

end
