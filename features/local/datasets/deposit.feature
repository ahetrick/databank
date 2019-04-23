Feature: Dataset Deposit
  In order to control access to Illinois Data Bank
  As an authorized depositor
  I want to deposit a dataset

  Scenario: Draft
    Given I am logged in as "depositor"
    When I deposit a draft dataset
    Then I see a draft dataset
