Feature: Manage wp-config.php file

  Background:
    Given a WP install

  Scenario: Get a wp-config.php file path
    When I try `wp config path`
    And STDOUT should contain:
      """
      wp-config.php
      """
    And STDERR should be empty

  Scenario: Get configurations defined in a wp-config.php file
    When I try `wp config get`
    Then STDOUT should be a table containing rows:
      | key | value | type |

    When I try `wp config get --fields=key,type`
    Then STDOUT should be a table containing rows:
      | key         | type     |
      | DB_NAME     | constant |
      | DB_USER     | constant |
      | DB_PASSWORD | constant |
      | DB_HOST     | constant |
