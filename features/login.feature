Feature: Login
  In order to use more features of Illinois Data Bank
  As a curator
  I want to be able to log in as a curator or switch role to developer

  Scenario: Login page exists and looks right
    When I visit the login page
    Then I should see all of:
      | You must log in | Enter your Active Directory (AD) password: |
    And I should see none of:
      | Find Data | Log out |

  Scenario: Log in as curator with Shibboleth
    When I log in via shibboleth
    Then I should see logged in links