Feature: Portal
  In order to support access to Illinois Data Bank by external groups
  As anyone
  I want to provide group portals

  Scenario: Invite Data Curation Network curator
    Given I am logged in as "admin"
    And I go to the Data Curation Network Portal accounts page
    When I add "portal@example.com" as an invitee
    Then I am on the Data Curation Network Portal accounts page
    And I see "Invitee was successfully created" on the page
    And I see "portal@example.com" on the page
    