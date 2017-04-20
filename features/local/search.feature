Feature: Search
  In order to find datasets
  As a curator, depositor, undergrad, or guest
  I want to be able to enter search terms and find datasets

#  Scenario: As guest, view page and looks right
#    Given I am logged out
#    When I visit the find page
#    Then I see all of:
#      | Datasets  | Log in | Funder | License |
#
#  Scenario: As curator, view page and looks right
#    Given I am logged out
#    When I log in
#    And I visit the find page
#    Then I see all of:
#      | Datasets | Depositor  | Funder | License | Visibility |
#
#  Scenario: As depositor, view page and looks right
#    Given I am logged out
#    When I log in
#    And I visit the home page
#    And I switch role to depositor
#    And I visit the find page
#    Then I see all of:
#      | Datasets  | Log in | Funder | License | Just My Datasets |
#    And I see none of:
#      | Visibility | Depositor |
#
#  Scenario: As an undergrad, view page and looks right
#    Given I am logged out
#    When I log in
#    And I visit the home page
#    And I switch role to undergrad
#    And I visit the find page
#    Then I see all of:
#      | Datasets  | Funder | License |
#    And I see none of:
#      | Visibility | Depositor |

  # curator
  Scenario: Search for datasets
    Given I am logged out
    And I log in
    And Draft datasets exist titled:
      | Numbers | Words |
    And Draft datasets by someone else exist titled:
      |Temperatures | Heights |
    And Published datasets exist titled:
      | Simple Facts | Fancy Facts | Images | Recordings |
    And Datasets published by someone else exist titled:
      | Measurements | Observations |

    And I visit the find page

    Then I see all of:
      | Numbers | Words | Temperatures | Heights | Measurements | Observations | Simple Facts | Fancy Facts | Images | Recordings |

    When I enter search phrase: fact
    And I click on 'submitSearch'
    And I pause for 2 seconds
    Then I see all of:
      | Simple Facts| Fancy Facts |
    And I see none of:
      | Numbers | Words | Temperatures | Heights | Measurements | Observations | Images | Recordings |

    # depositor
    When I visit the home page
    And I switch role to depositor
    And I visit the find page
    And I check the box: justMine
    # see my drafts
    Then I see all of:
      | Numbers | Words |
    # see my published datasets
    And I see all of:
      | Simple Facts | Fancy Facts | Images | Recordings |
    # don't see other people's drafts
    And I see none of:
      | Temperatures | Heights |
    # don't see other people's published datasets
    And I see none of:
      | Measurements | Observations |

    And I uncheck the box: justMine
    # see my drafts
    Then I see all of:
      | Numbers | Words |
    # see all published datasets
    And I see all of:
      | Simple Facts | Fancy Facts | Images | Recordings | Measurements | Observations |
    # don't see other people's drafts
    And I see none of:
      | Temperatures | Heights |

    When I enter search phrase: fact
    And I click on 'submitSearch'
    And I pause for 2 seconds
    Then I see all of:
      | Simple Facts| Fancy Facts |
    And I see none of:
      | Numbers | Words | Temperatures | Heights | Images | Recordings | Measurements | Observations |

    # undergrad
    When I am logged out
    And I visit the login page
    And I visit the home page
    And I switch role to undergrad
    And I visit the find page
    Then I see all of:
      | Measurements | Observations | Simple Facts | Fancy Facts | Images | Recordings |
    And I see none of:
      | Numbers | Words | Temperatures | Heights |

    When I enter search phrase: fact
    And I click on 'submitSearch'
    And I pause for 2 seconds
    Then I see all of:
      | Simple Facts| Fancy Facts |
    And I see none of:
      | Numbers | Words | Temperatures | Heights | Measurements | Observations | Images | Recordings |

    # guest / logged out
    When I am logged out
    And I visit the find page
    # see published datasets
    Then I see all of:
      | Measurements | Observations | Simple Facts | Fancy Facts | Images | Recordings |
    # don't see drafts
    And I see none of:
      | Numbers | Words | Temperatures | Heights |

    When I enter search phrase: fact
    And I click on 'submitSearch'
    And I pause for 2 seconds
    Then I see all of:
      | Simple Facts| Fancy Facts |
    And I see none of:
      | Numbers | Words | Temperatures | Heights | Measurements | Observations |