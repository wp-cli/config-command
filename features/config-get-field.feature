Feature: Get the value of a constant or global defined in wp-config.php file

  Background:
    Given a WP install

  Scenario: Get the value of an existing wp-config.php constant
    When I try `wp config get --constant=DB_NAME`
    Then STDOUT should be:
      """
      wp_cli_test
      """
    And STDERR should be empty

  Scenario: Get the value of an existing wp-config.php global
    When I try `wp config get --global=table_prefix`
    Then STDOUT should be:
      """
      wp_
      """
    And STDERR should be empty

  Scenario: Get the value of a non existing wp-config.php constant
    When I try `wp config get --constant=FOO`
    Then STDERR should be:
      """
      Error: the FOO constant is not defined in the wp-config.php file.
      """
    And STDOUT should be empty

  Scenario: Get the value of a non existing wp-config.php global
    When I try `wp config get --global=foo`
    Then STDERR should be:
      """
      Error: the foo global is not defined in the wp-config.php file.
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php constant with wrong case should yield an error
    When I try `wp config get --constant=db_name`
    Then STDERR should be:
      """
      Error: the db_name constant is not defined in the wp-config.php file.
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php global with wrong case should yield an error
    When I try `wp config get --global=TABLE_PREFIX`
    Then STDERR should be:
      """
      Error: the TABLE_PREFIX global is not defined in the wp-config.php file.
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php constant with some similarity should yield a helpful error
    When I try `wp config get --constant=DB_NOME`
    Then STDERR should be:
      """
      Error: the DB_NOME constant is not defined in the wp-config.php file; were you looking for DB_NAME?
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php constant with some similarity should yield a helpful error
    When I try `wp config get --global=table_perfix`
    Then STDERR should be:
      """
      Error: the table_perfix global is not defined in the wp-config.php file; were you looking for table_prefix?
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php constant with remote similarity should yield just an error
    When I try `wp config get --constant=DB_NOOOOZLE`
    Then STDERR should be:
      """
      Error: the DB_NOOOOZLE constant is not defined in the wp-config.php file.
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php global with remote similarity should yield just an error
    When I try `wp config get --global=tabre_peffix`
    Then STDERR should be:
      """
      Error: the tabre_peffix global is not defined in the wp-config.php file.
      """
    And STDOUT should be empty
