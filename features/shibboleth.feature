Feature: Shibboleth
  To use more features of Illinois Data Bank
  As a UIUC AD account holder
  I want to be able to log in via Shibboleth

  Scenario: Login page exists and looks right
    When I visit the login page
    Then I see all of:
      | You must log in | Enter your Active Directory (AD) password: |

  Scenario: Log in
    When I log in via shibboleth
    Then I see logged in links