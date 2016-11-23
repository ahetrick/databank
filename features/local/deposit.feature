Feature: Deposit
  To publish my dataset
  As a depositor
  I want to deposit a dataset

  Scenario: Display pre-deposit considerations
    Given I visit the home page
    When I click Deposit Dataset from the navbar
    Then I see all of:
      | select a license | select a long-term primary contact | delay publication | data publishing experts | Continue |

  Scenario: Require valid login before deposit
    Given I visit the home page
    And I am logged out
    And I click Deposit Dataset from the navbar
    And I click on 'Continue'
    Then I see all of:
      | Log in required |

   Scenario: Deposit agreement presented and looks right
     Given I am logged out
     And I log in
     And I switch role to depositor
     And I click Deposit Dataset from the navbar
     And I click on 'Continue'
     Then I see all of:
      | Illinois Data Bank Deposit Agreement | creator of this dataset | removed any private | you agree |

   Scenario: Deposit a dataset
     Given I am logged out
     When I log in
     And I switch role to depositor
     And I click Deposit Dataset from the navbar
     And I click on 'Continue'
     And I agree to deposit agreement
     And I fill in required dataset metadata
     And I attach a file
     And I click on 'Continue'
     And I click on 'Confirm'
     And I click on 'Publish'
     Then I see all of:
      | Dataset was successfully published |

