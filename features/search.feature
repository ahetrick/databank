Feature: Search
  In order to find datasets
  As a curator, depositor, undergrad, or guest
  I want to be able to enter search terms and find datasets

  Scenario: As guest, view page and looks right
    Given I am logged out
    When I visit the find page
    Then I see all of:
      | Search  | Log In |


  Scenario: As curator, view page and looks right
    Given I am logged out
    When I log in
    And I visit the find page
    Then I see all of:
      | Search  | Status |


  Scenario: As depositor, view page and looks right
    Given I am logged out
    When I log in
    And I visit the home page
    And I switch role to depositor
    And I visit the find page
    Then I see all of:
      | Search  | this bar to list |


  Scenario: As an undergrad, view page and looks right
    Given I am logged out
    When I log in
    And I visit the home page
    And I switch role to undergrad
    And I visit the find page
    Then I see all of:
      | Search  |
    And I see none of:
      | this bar to list | Status |


  # curator
  Scenario: Search for datasets
    Given I am logged out
    And I log in
    And Draft datasets exist titled:
      | Numbers | Words | Temperatures | Heights |
    And Published datasets exist titled:
      | Measurements | Observations | Simple Facts | Fancy Facts |
    And I visit the find page
    Then I see all of:
      | Numbers | Words | Temperatures | Heights | Measurements | Observations | Simple Facts | Fancy Facts |

    When I enter search phrase: fact
    And I pause for 2 seconds
    Then I see all of:
      | Simple Facts| Fancy Facts |
    And I see none of:
      | Numbers | Words | Temperatures | Heights | Measurements | Observations |

    # depositor
    When I visit the home page
    And I switch role to depositor
    And I visit the find page
    Then I see all of:
      | Numbers | Words | Temperatures | Heights | Measurements | Observations | Simple Facts | Fancy Facts |

    When I enter search phrase: fact
    And I pause for 2 seconds
    Then I see all of:
      | Simple Facts| Fancy Facts |
    And I see none of:
      | Numbers | Words | Temperatures | Heights | Measurements | Observations |

    # undergrad
    When I am logged out
    And I visit the login page
    And I visit the home page
    And I switch role to undergrad
    And I visit the find page
    Then I see all of:
      | Measurements | Observations | Simple Facts | Fancy Facts |
    And I see none of:
      | Numbers | Words | Temperatures | Heights |

    When I enter search phrase: fact
    And I pause for 2 seconds
    Then I see all of:
      | Simple Facts| Fancy Facts |
    And I see none of:
      | Numbers | Words | Temperatures | Heights | Measurements | Observations |


    # guest / logged out
    When I am logged out
    And I visit the find page
    Then I see all of:
      | Measurements | Observations | Simple Facts | Fancy Facts |
    And I see none of:
      | Numbers | Words | Temperatures | Heights |

    When I enter search phrase: fact
    And I pause for 2 seconds
    Then I see all of:
      | Simple Facts| Fancy Facts |
    And I see none of:
      | Numbers | Words | Temperatures | Heights | Measurements | Observations |
