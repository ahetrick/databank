Feature: Authentication
  In order to support Illinois Experts importing datasets from Illinois Data Bank
  As anyone
  I want to provide appropriately structured xml page

  Scenario: Illinois Experts xml page serves valid xml
    When I log out
    And I go to the Illinois Experts xml page
    Then I am on the Illinois Experts xml page
    And I see valid xml on the page
