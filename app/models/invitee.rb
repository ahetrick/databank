class Invitee < ActiveRecord::Base
  has_one :identity, dependent: :destroy
end
