Feature: Help
  To get help with Illinois Data Bank
  As a guest
  I want to be able to see Help content for Illinois Data Bank

  Scenario: View page and looks right
    When I visit the help page
    Then I see all of:
      | How can we help you? | Getting Started Guide |

  Scenario: Guest clicks the Help link in navbar
    When I visit the home page
    And I click the help link
    Then I see all of:
      | How can we help you? | Getting Started Guide |
