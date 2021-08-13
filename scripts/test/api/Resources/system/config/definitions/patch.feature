Feature: POST request /system/config/{option} resource

  Background:
    Given the API URL is __BACKEND_API_URL__
    Given the API schema files are located at __API_SCHEMA_LOCATION__
    Given I am logged in as agent user "admin" with password "Passw0rd"

  Scenario: patch a config option definition
    When I patch this config object definitions "API::Cache"
    Then the response code is 200
