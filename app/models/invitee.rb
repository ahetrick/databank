# frozen_string_literal: true

class Invitee < ActiveRecord::Base
  validates :email, presence: true, uniqueness: true
  before_destroy :destroy_identity
  before_destroy :destroy_user

  def group
    "reviewer"
  end

  def destroy_identity
    identity = Identity.find_by(email: email)
    identity&.destroy!
  end

  def destroy_user
    user = User::Identity.find_by(email: email)
    user&.destroy!
  end
end
