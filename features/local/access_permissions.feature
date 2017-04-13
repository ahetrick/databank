Feature: Access Permissions
  To correctly use Illinois Data Bank appropriately to my role
  As a curator, depositor, or undergrad
  I want to be to access appropriate elements

  Scenario: Deposit form looks right for curator
    Given I am logged out
    When I log in as a curator
    And I click Deposit Dataset from the navbar
    And I click on 'Continue'
    And I agree to deposit agreement
    Then I see all of:
      | Imported DOI | Test DOI |
    And I see shaded background on curator elements

  Scenario: Deposit form looks right for depositor
    Given I am logged out
    When I log in as a curator
    And I switch role to depositor
    And I click Deposit Dataset from the navbar
    And I click on 'Continue'
    And I agree to deposit agreement
    Then I see none of:
      | Imported DOI | Test DOI |

  Scenario: Deposit form unavailable for undergrad
    Given I am logged out
    When I log in as a curator
    And I switch role to undergrad
    And I click Deposit Dataset from the navbar
    And I click on 'Continue'
    Then I see all of:
      | ACCOUNT NOT ELIGIBLE TO DEPOSIT DATA. | Faculty, staff, and graduate students are eligible to deposit data in Illinois Data Bank. |
