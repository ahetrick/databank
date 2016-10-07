Feature: Policies
  To learn about the policies of the Illinois Data Bank
  As a guest
  I want to be able to see policy content for Illinois Data Bank

  Scenario: View page and looks right
    When I visit the policies page
    Then I see all of:
      | Policy Framework | Illinois Data Bank Policies |

  Scenario: Guest clicks the Policies link in navbar
    When I visit the home page
    And I click the policies link
    Then I see all of:
      | Policy Framework | Illinois Data Bank Policies |
