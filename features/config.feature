Feature: Manage wp-config.php file

  Scenario: Getting config should produce error when no config is found
    Given an empty directory

    When I try `wp config list`
    Then STDERR should be:
      """
      Error: 'wp-config.php' not found.
      """

    When I try `wp config get`
    Then STDERR should be:
      """
      Error: 'wp-config.php' not found.
      """

    When I try `wp config set`
    Then STDERR should be:
      """
      Error: 'wp-config.php' not found.
      """

    When I try `wp config path`
    Then STDERR should be:
      """
      Error: 'wp-config.php' not found.
      """

  Scenario: Get a wp-config.php file path
    Given a WP install
    When I try `wp config path`
    And STDOUT should contain:
      """
      wp-config.php
      """
    And STDERR should be empty
