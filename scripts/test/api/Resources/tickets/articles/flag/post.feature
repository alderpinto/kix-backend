Feature: POST request to the /tickets/:TicketID/articles/:ArticleID/flags resource

  Background: 
    Given the API URL is __BACKEND_API_URL__
    Given the API schema files are located at __API_SCHEMA_LOCATION__
    Given I am logged in as agent user "admin" with password "Passw0rd"
    
  Scenario: create a article flag
    Given a ticket
    Given a article
    When I create a article flag
      Then the response code is 201
    When I delete this ticket
    Then the response code is 204
    And the response has no content
