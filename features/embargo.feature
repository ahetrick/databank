Feature:
  To delay publication
  As a curator or depositor
  I want to manage publication delay

  Scenario: As a curator, deposit dataset as file & metadata publication delay (set 1+ years)
    Given I am logged out
    When I log in as a curator
    And I click Deposit Dataset from the navbar
    And I click on 'Continue'
    And I agree to deposit agreement
    And I fill in required dataset metadata
    And I select file & metadata publication delay
    And I select release date delay (1+ years)
    And I attach a file
    And I click on 'Continue'
    And I click on 'Confirm'
    Then I see all of:
      | DOI link will fail | the record and files for your dataset will be publicly visible |
    And I click on 'Publish'
    Then I see all of:
      | successfully reserved | Metadata and Files Publication Delayed (Embargoed) |

  Scenario: As a curator, manage publication delay
    Given I am logged out
    And I log in as a curator
    And I have a published dataset with a file & metadata publication delay
    When I visit the dataset edit page
    And I select file only publication delay
    And I click on 'Confirm'
    And I pause for 2 seconds
    Then I see all of:
      | record will be publicly visible | your data files will not be made available until|

    When I click on 'Publish'
    Then I see all of:
      | successfully updated | Metadata Published, Files Publication Delayed (Embargoed) |

    When I visit the dataset edit page
    And I select no publication delay
    And I click on 'Confirm'
    And I pause for 2 seconds
    Then I see all of:
      | record will be publicly visible | files will be publicly available |

    When I click on 'Publish'
    Then I see all of:
      | successfully updated | Metadata and Files Published |

    When I visit the dataset edit page
    And I select file only publication delay
    And I select release date delay (2+ years)
    And I click on 'Confirm'
    And I pause for 2 seconds
    Then I see all of:
      | record will be publicly visible | files will not be made available until |

    When I click on 'Publish'
    Then I see all of:
      | successfully updated | Metadata Published, Files Publication Delayed (Embargoed) |

    When I visit the dataset edit page
    And I select file & metadata publication delay
    And I click on 'Confirm'
    And I pause for 2 seconds
    Then I see all of:
      | The DOI link will resolve to an EZID tombestone page until | record for your dataset is not visible, nor are your data files available until |

    When I click on 'Publish'
    Then I see all of:
      | successfully updated | Metadata and Files Publication Delayed (Embargoed) |

  ####################
  #
  # Depositor
  #
  ###################

  Scenario: As a depositor, deposit dataset as file & metadata publication delay (set 1+ years)
    Given I am logged out
    When I log in as a curator
    And I switch role to depositor
    And I click Deposit Dataset from the navbar
    And I click on 'Continue'
    And I agree to deposit agreement
    And I fill in required dataset metadata
    And I select file & metadata publication delay
    And I select release date delay (1+ years)
    And I attach a file
    And I click on 'Continue'
    And I click on 'Confirm'
    Then I see all of:
      | DOI link will fail | the record and files for your dataset will be publicly visible |
    And I click on 'Publish'
    Then I see all of:
      | successfully reserved | Metadata and Files Publication Delayed (Embargoed) |

  Scenario: As a depositor, manage publication delay
    Given I am logged out
    And I log in as a curator
    And I switch role to depositor
    And I have a published dataset with a file & metadata publication delay
    When I visit the dataset edit page
    And I select file only publication delay
    And I click on 'Confirm'
    And I pause for 2 seconds
    Then I see all of:
      | record will be publicly visible | your data files will not be made available until|

    When I click on 'Publish'
    Then I see all of:
      | successfully updated | Metadata Published, Files Publication Delayed (Embargoed) |

    When I visit the dataset edit page
    And I select no publication delay
    And I click on 'Confirm'
    And I pause for 2 seconds
    Then I see all of:
      | record will be publicly visible | files will be publicly available |

    When I click on 'Publish'
    Then I see all of:
      | successfully updated | Metadata and Files Published |

    # END of what depositor should be able to do - the rest are making sure depositor can't do something.

    When I visit the dataset edit page
    Then I see only No Publication Delay option

  Scenario: As a depositor, blocked from publication delay more than +1 year
    Given I am logged out
    When I log in as a curator
    And I switch role to depositor
    And I click Deposit Dataset from the navbar
    And I click on 'Continue'
    And I agree to deposit agreement
    And I fill in required dataset metadata
    And I attach a file
    And I select file & metadata publication delay
    And I select release date delay (2+ years)
    And I leave release date field
    And I pause for 5 seconds
    Then I see an alert "The maximum amount of time that data can be delayed for publication is is 1 year."
    And I see the release date set to one year from now