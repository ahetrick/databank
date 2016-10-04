Feature: Hello
  In order to orient myself to Illinois Data Bank
  As a guest
  I want to be able to see an overview about Illinois Data Bank

  Scenario: View page and looks right
    When I visit the home page
    Then I should see all of:
      | The Illinois Data Bank is a public access repository for publishing research data from the University of Illinois at Urbana-Champaign  | You are ready to deposit data if: |

