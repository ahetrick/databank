Feature: Login
  To use more features of Illinois Data Bank
  As a curator
  I want to be able to log in

  Scenario: Log in
    Given I have an activated identity with an admin role
    When I log in
    Then I see logged in links