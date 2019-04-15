Feature: Portal
  In order to support access to Illinois Data Bank by external groups
  As anyone
  I want to provide group portals

  Scenario: Invite Data Curation Network curator
    When I am logged in as "admin"
    And I go to the data curation network portal accounts page
    And I click on Data Curation Network Add New Account button
    Then I am on Data Curation Network account add page
