Feature: Switch role
  To use more features of Illinois Data Bank
  As a curator
  I want to be able to swith roles to depositor or undergrad

  Scenario: Swith role to depositor
    Given I am logged out
    When I log in
    And I switch role to depositor
    Then I see switch to depositor confirmation message

  Scenario: Swith role to undergrad
    Given I am logged out
    When I log in
    And I switch role to undergrad
    Then I see switch to undergrad confirmation message
