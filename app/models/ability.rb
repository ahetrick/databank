class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #

    user ||= User.new # guest user (not logged in)
    if user.is?(:admin)
      can :manage, :all
    elsif user.is?(:depositor)

      can :download_citation_report, :all
      can :read, :all
      can :create, :all
      can :confirmation_message, Dataset do |dataset|
        dataset.try(:depositor_email) == user.email
      end
      can :get_new_token, Dataset do |dataset|
        dataset.try(:depositor_email) == user.email
      end
      can :validiate_change2published, :all
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

      can :get_new_token, Dataset do |dataset|
        dataset.try(:depositor_email) == user.email
      end

      can :get_current_token, Dataset do |dataset|
        dataset.try(:depositor_email) == user.email
      end

      can :reserve_doi, Dataset do |dataset|
        dataset.try(:depositor_email) == user.email
      end

      can :request_review, Dataset do |dataset|
        dataset.try(:depositor_email) == user.email
      end

      can :peek_text, Datafile
      can :filepath, Datafile
      can :bucket_and_key, Datafile
      can :iiif_filepath, Datafile
      can :download_link, Dataset
      can :stream_file, Dataset
      can :download_datafiles, Dataset
      can :download_endNote_XML, Dataset
      can :download_plaintext_citation, Dataset
      can :download_BibTeX, Dataset
      can :download_RIS, Dataset
      can :show, Dataset
      can :splash_url, Dataset
      can :review_deposit_agreement, Dataset
      can :pre_deposit, Dataset
      can :validiate_change2published, :all
      can :search, Dataset
      can :recordtext, Dataset
      can :temporary_error, Dataset
      can :show, FeaturedResearcher
      can :index, FeaturedResearcher

    else
      can :peek_text, Datafile
      can :bucket_and_key, Datafile
      can :filepath, Datafile
      can :iiif_filepath, Datafile
      can :download_citation_report, :all
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
      can :pre_deposit, Dataset
      can :validiate_change2published, :all
      can :search, Dataset
      can :recordtext, Dataset
      can :temporary_error, Dataset
      can :show, FeaturedResearcher


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
