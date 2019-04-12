# frozen_string_literal: true

class Invitee < ActiveRecord::Base
  validates :email, presence: true, uniqueness: true
  before_destroy :destroy_identity
  before_destroy :destroy_user

  def destroy_identity
    identity = Identity.find_by(email: email)
    identity&.destroy!
  end

  def destroy_user
    user = Identity::User.find_by(email: email)
    user&.destroy!
  end
end
