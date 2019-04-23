class Invitee < ActiveRecord::Base
  before_destroy :destroy_identity

  def group
    "reviewer"
  end

  def destroy_identity
    identity = Identity.find_by_email(self.email)
    if identity
      identity.destroy!
    end
  end

end
