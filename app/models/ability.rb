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

    elsif user.is?(Databank::UserRole::REVIEWER)


    # else
    #   can :peek_text, Datafile
    #   can :bucket_and_key, Datafile
    #   can :filepath, Datafile
    #   can :iiif_filepath, Datafile
    #   can :download_citation_report, :all
    #   can :read, :all
    #   can :download_link, Dataset
    #   can :stream_file, Dataset
    #   can :download_datafiles, Dataset
    #   can :download_endNote_XML, Dataset
    #   can :download_plaintext_citation, Dataset
    #   can :download_BibTeX, Dataset
    #   can :download_RIS, Dataset
    #   can :show, Dataset
    #   can :splash_url, Dataset
    #   can :pre_deposit, Dataset
    #   can :search, Dataset
    #   can :recordtext, Dataset
    #   can :temporary_error, Dataset
    #   can :show, FeaturedResearcher
    #   can :view, Datafile

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
