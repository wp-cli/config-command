Feature: Manage wp-config.php file

  Scenario: Get a wp-config.php file path
    Given a WP install

    When I try `wp config path`
    And STDOUT should contain:
      """
      wp-config.php
      """
    And STDERR should be empty
