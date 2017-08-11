Feature: Download
  To use datasets
  As a guest, depositor, or curator
  I want to be able to download files


  Scenario: Splash page exists and looks right
    When I visit the example dataset page
    Then I see all of:
      | Get Custom Zip | cert_1.jpg | cert_4.jpg |

  Scenario: Download single file
    When I visit the example dataset page

  Scenario: Login page exists and looks right
    When I visit the login page
    Then I see all of:
      | You must log in | Enter your Active Directory (AD) password: |

  Scenario: Log in
    When I log in via shibboleth
    Then I see logged in links
