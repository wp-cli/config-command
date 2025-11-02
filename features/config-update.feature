Feature: Update or add a constant or variable in wp-config.php file

  Scenario: Update an existing constant in wp-config.php
    Given a WP install

    When I run `wp config update DB_HOST db.example.com`
    Then STDOUT should be:
      """
      Success: Updated the constant 'DB_HOST' in the 'wp-config.php' file with the value 'db.example.com'.
      """

    When I run `wp config get DB_HOST`
    Then STDOUT should be:
      """
      db.example.com
      """

  Scenario: Add a new constant when it doesn't exist
    Given a WP install

    When I run `wp config update NEW_CONSTANT constant_value`
    Then STDOUT should be:
      """
      Success: Added the constant 'NEW_CONSTANT' to the 'wp-config.php' file with the value 'constant_value'.
      """

    When I run `wp config get NEW_CONSTANT`
    Then STDOUT should be:
      """
      constant_value
      """

  Scenario: Update an existing constant then add it again
    Given a WP install

    When I run `wp config update TEST_CONSTANT first_value`
    Then STDOUT should be:
      """
      Success: Added the constant 'TEST_CONSTANT' to the 'wp-config.php' file with the value 'first_value'.
      """

    When I run `wp config update TEST_CONSTANT second_value`
    Then STDOUT should be:
      """
      Success: Updated the constant 'TEST_CONSTANT' in the 'wp-config.php' file with the value 'second_value'.
      """

    When I run `wp config get TEST_CONSTANT`
    Then STDOUT should be:
      """
      second_value
      """

  Scenario: Update a variable with --type=variable
    Given a WP install

    When I run `wp config update new_variable variable_value --type=variable`
    Then STDOUT should be:
      """
      Success: Added the variable 'new_variable' to the 'wp-config.php' file with the value 'variable_value'.
      """

    When I run `wp config update new_variable updated_value --type=variable`
    Then STDOUT should be:
      """
      Success: Updated the variable 'new_variable' in the 'wp-config.php' file with the value 'updated_value'.
      """

    When I run `wp config get new_variable`
    Then STDOUT should be:
      """
      updated_value
      """

  Scenario: Update raw values in wp-config.php
    Given a WP install

    When I run `wp config update WP_DEBUG true --raw`
    Then STDOUT should be:
      """
      Success: Updated the constant 'WP_DEBUG' in the 'wp-config.php' file with the raw value 'true'.
      """

    When I run `wp config list WP_DEBUG --strict --format=json`
    Then STDOUT should contain:
      """
      {"name":"WP_DEBUG","value":true,"type":"constant"}
      """

    When I run `wp config update WP_DEBUG false --raw`
    Then STDOUT should be:
      """
      Success: Updated the constant 'WP_DEBUG' in the 'wp-config.php' file with the raw value 'false'.
      """

    When I run `wp config list WP_DEBUG --strict --format=json`
    Then STDOUT should contain:
      """
      {"name":"WP_DEBUG","value":false,"type":"constant"}
      """

  @custom-config-file
  Scenario: Update a constant in wp-custom-config.php
    Given an empty directory
    And WP files

    When I run `wp config create {CORE_CONFIG_SETTINGS} --skip-check --config-file='wp-custom-config.php'`
    Then STDOUT should contain:
      """
      Generated 'wp-custom-config.php' file.
      """

    When I run `wp config update DB_HOST db.example.com --config-file='wp-custom-config.php'`
    Then STDOUT should be:
      """
      Success: Updated the constant 'DB_HOST' in the 'wp-custom-config.php' file with the value 'db.example.com'.
      """

    When I run `wp config get DB_HOST --config-file='wp-custom-config.php'`
    Then STDOUT should be:
      """
      db.example.com
      """

  Scenario: Ambiguous update requests throw errors
    Given a WP install

    When I run `wp config update SOME_NAME some_value --type=constant`
    Then STDOUT should be:
      """
      Success: Added the constant 'SOME_NAME' to the 'wp-config.php' file with the value 'some_value'.
      """

    When I run `wp config update SOME_NAME some_value --type=variable`
    Then STDOUT should be:
      """
      Success: Added the variable 'SOME_NAME' to the 'wp-config.php' file with the value 'some_value'.
      """

    When I run `wp config list --fields=name,type SOME_NAME --strict`
    Then STDOUT should be a table containing rows:
      | name      | type     |
      | SOME_NAME | constant |
      | SOME_NAME | variable |

    When I try `wp config update SOME_NAME some_value`
    Then STDERR should be:
      """
      Error: Found both a constant and a variable 'SOME_NAME' in the 'wp-config.php' file. Use --type=<type> to disambiguate.
      """

  Scenario: Update with placement options for new constants
    Given a WP install
    And a wp-config.php file:
      """
      define( 'CONST_A', 'val-a' );
      /** ANCHOR */
      define( 'CONST_B', 'val-b' );
      require_once( ABSPATH . 'wp-settings.php' );
      """

    When I run `wp config update SOME_NAME some_value --anchor="/** ANCHOR */" --placement=before --separator="\n"`
    Then STDOUT should be:
      """
      Success: Added the constant 'SOME_NAME' to the 'wp-config.php' file with the value 'some_value'.
      """
    And the wp-config.php file should be:
      """
      define( 'CONST_A', 'val-a' );
      define( 'SOME_NAME', 'some_value' );
      /** ANCHOR */
      define( 'CONST_B', 'val-b' );
      require_once( ABSPATH . 'wp-settings.php' );
      """

    When I run `wp config update SOME_NAME updated_value --anchor="/** ANCHOR */" --placement=before --separator="\n"`
    Then STDOUT should be:
      """
      Success: Updated the constant 'SOME_NAME' in the 'wp-config.php' file with the value 'updated_value'.
      """
    And the wp-config.php file should be:
      """
      define( 'CONST_A', 'val-a' );
      define( 'SOME_NAME', 'updated_value' );
      /** ANCHOR */
      define( 'CONST_B', 'val-b' );
      require_once( ABSPATH . 'wp-settings.php' );
      """
