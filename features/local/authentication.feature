Feature: Authentication
  In order to control access to Illinois Data Bank
  As anyone
  I want to provide an authentication mechanism

  Scenario: Log out
    When I log out
    Then I am on the site home page
    And I see "Log in" on the page

  Scenario: Log in as admin
    When I am logged in as "admin"
    And I go to the site home
    Then I see "Log out" on the page
    And I see "Switch Role" on the page
