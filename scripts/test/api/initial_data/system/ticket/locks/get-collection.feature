 Feature: GET request to the /system/ticket/locks resource

  Background: 
    Given the API URL is __BACKEND_API_URL__
    Given the API schema files are located at __API_SCHEMA_LOCATION__
    Given I am logged in as agent user "admin" with password "Passw0rd"

  Scenario: get the list of existing ticket locks
    When I query the collection of ticket locks
    Then the response code is 200
    Then the response contains 2 items of type "Lock"
    Then the response contains the following items of type Lock
      | Name     |
      | unlock   |
      | lock     |



