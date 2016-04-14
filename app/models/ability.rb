class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #

    user ||= User.new # guest user (not logged in)
    if user.is?(:admin)
      can :manage, :all
    elsif user.is?(:depositor)
      can :read, :all
      can :create, :all
      can :update, Dataset do |dataset|
        dataset.try(:depositor_email) == user.email
      end
      can :publish, Dataset do |dataset|
        dataset.try(:depositor_email) == user.email
      end
      can :destroy_file, Dataset do |dataset|
        (dataset.try(:depositor_email) == user.email) && !dataset.complete?
      end
      can :destroy, Dataset do |dataset|
        dataset.try(:depositor_email) == user.email
      end

      can :stream_file, Dataset
      can :download_datafiles, Dataset
      can :download_endNote_XML, Dataset
      can :download_plaintext_citation, Dataset
      can :download_BibTeX, Dataset
      can :download_RIS, Dataset
      can :show, Dataset
      can :review_deposit_agreement, Dataset
    else
      can :read, :all
      can :download_link, Dataset
      can :stream_file, Dataset
      can :download_datafiles, Dataset
      can :download_endNote_XML, Dataset
      can :download_plaintext_citation, Dataset
      can :download_BibTeX, Dataset
      can :download_RIS, Dataset
      can :show, Dataset
      can :splash_url, Dataset

    end
    #
    # The first argument to `can` is the action you are giving the user 
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. 
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end

end
