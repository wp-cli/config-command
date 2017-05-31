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

  Scenario: List configurations defined in a wp-config.php file
    When I try `wp config list`
    Then STDOUT should be a table containing rows:
      | key | value | type |

    When I try `wp config list --fields=key,type`
    Then STDOUT should be a table containing rows:
      | key         | type     |
      | DB_NAME     | constant |
      | DB_USER     | constant |
      | DB_PASSWORD | constant |
      | DB_HOST     | constant |

  Scenario: Get a specific value as defined in a wp-config.php file
    When I try `wp config get table_prefix`
    Then STDOUT should be:
      """
      wp_
      """
    And STDERR should be empty

    When I try `wp config get non-existent-key`
    Then STDOUT should be empty
    And the return code should be 1
