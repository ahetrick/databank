class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #

    user ||= User::Shibboleth.new # guest user (not logged in)
    if user.is?(Databank::UserRole::ADMIN)
      can :manage, :all
      
    elsif user.is?(Databank::UserRole::DEPOSITOR)

      can [:read, :create], [Dataset, Datafile]

      can [:edit,
           :update,
           :destroy,
           :request_review,
           :get_new_token,
           :get_current_token,
           :validiate_change2published,
           :publish,:destroy_file ], Dataset do |dataset|
        dataset.try(:depositor_email) == user.email
      end
      can :view, Dataset do |dataset|
        dataset.try(:depositor_email) == user.email || dataset.metadata_public?
      end

    elsif user.is?(Databank::UserRole::REVIEWER) && user.group == Databank::IdentityGroup::NETWORK_CURATOR
      can [:view], Dataset do |dataset|
         dataset.try(:data_curation_network) == true || dataset.metadata_public?
      end
    else
      can :view, Dataset do |dataset|
        dataset.metadata_public?
      end
    end

  end

end
