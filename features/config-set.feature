Feature: Set the value of a constant or variable defined in wp-config.php file

  Background:
    Given a WP install

  Scenario: Update the value of an existing wp-config.php constant
    When I run `wp config set DB_HOST db.example.com`
    Then STDOUT should be:
      """
      Success: Updated the 'DB_HOST' entry in the 'wp-config.php' file with the value 'db.example.com'.
      """

    When I run `wp config get DB_HOST`
    Then STDOUT should be:
      """
      db.example.com
      """

  Scenario: Add a new value to wp-config.php
    When I run `wp config set NEW_CONSTANT constant_value`
    Then STDOUT should be:
      """
      Success: Added the 'NEW_CONSTANT' entry in the 'wp-config.php' file with the value 'constant_value'.
      """

    When I run `wp config get NEW_CONSTANT`
    Then STDOUT should be:
      """
      constant_value
      """

  Scenario: Updating a non-existent value without --add
    When I try `wp config set NEW_CONSTANT constant_value --no-add`
    Then STDERR should be:
      """
      Error: The 'NEW_CONSTANT' constant or variable is not defined in the 'wp-config.php' file.
      """

    When I try `wp config set NEW_CONSTANT constant_value --type=constant --no-add`
    Then STDERR should be:
      """
      Error: The 'NEW_CONSTANT' constant is not defined in the 'wp-config.php' file.
      """

    When I try `wp config set NEW_CONSTANT constant_value --type=variable --no-add`
    Then STDERR should be:
      """
      Error: The 'NEW_CONSTANT' variable is not defined in the 'wp-config.php' file.
      """

    When I try `wp config set table_prefix new_prefix --type=constant --no-add`
    Then STDERR should be:
      """
      Error: The 'table_prefix' constant is not defined in the 'wp-config.php' file.
      """

    When I run `wp config set table_prefix new_prefix --type=variable --no-add`
    Then STDOUT should be:
      """
      Success: Updated the 'table_prefix' entry in the 'wp-config.php' file with the value 'new_prefix'.
      """

    When I try `wp config set DB_HOST db.example.com --type=variable --no-add`
    Then STDERR should be:
      """
      Error: The 'DB_HOST' variable is not defined in the 'wp-config.php' file.
      """

    When I run `wp config set DB_HOST db.example.com --type=constant --no-add`
    Then STDOUT should be:
      """
      Success: Updated the 'DB_HOST' entry in the 'wp-config.php' file with the value 'db.example.com'.
      """

  Scenario: Update raw values
    When I run `wp config set WP_DEBUG true`
    Then STDOUT should be:
      """
      Success: Added the 'WP_DEBUG' entry in the 'wp-config.php' file with the value 'true'.
      """

    When I run `wp config list WP_DEBUG --strict --format=json`
    Then STDOUT should contain:
      """
      {"name":"WP_DEBUG","value":"true","type":"constant"}
      """

    When I run `wp config set WP_DEBUG true --raw`
    Then STDOUT should be:
      """
      Success: Updated the 'WP_DEBUG' entry in the 'wp-config.php' file with the raw value 'true'.
      """

    When I run `wp config list WP_DEBUG --strict --format=json`
    Then STDOUT should contain:
      """
      {"name":"WP_DEBUG","value":true,"type":"constant"}
      """

  Scenario: Ambiguous change requests throw errors
    When I run `wp config set SOME_NAME some_value --type=constant`
    Then STDOUT should be:
      """
      Success: Added the 'SOME_NAME' entry in the 'wp-config.php' file with the value 'some_value'.
      """

    When I run `wp config set SOME_NAME some_value --type=variable`
    Then STDOUT should be:
      """
      Success: Added the 'SOME_NAME' entry in the 'wp-config.php' file with the value 'some_value'.
      """

    When I run `wp config list --fields=name,type SOME_NAME --strict`
    Then STDOUT should be a table containing rows:
      | name      | type     |
      | SOME_NAME | constant |
      | SOME_NAME | variable |

    When I try `wp config set SOME_NAME some_value`
    Then STDERR should be:
      """
      Error: Found both a constant and a variable 'SOME_NAME' in the 'wp-config.php' file. Use --type=<type> to disambiguate.
      """

  Scenario: Additions can be properly placed
    Given a wp-config.php file:
      """
      define( 'CONST_A', 'val-a' );
      /** ANCHOR */
      define( 'CONST_B', 'val-b' );
      require_once( ABSPATH . 'wp-settings.php' );
      """

    When I run `wp config set SOME_NAME some_value --anchor="/** ANCHOR */" --placement=before --separator="\n"`
    Then STDOUT should be:
      """
      Success: Added the 'SOME_NAME' entry in the 'wp-config.php' file with the value 'some_value'.
      """
    And the wp-config.php file should be:
      """
      define( 'CONST_A', 'val-a' );
      define( 'SOME_NAME', 'some_value' );
      /** ANCHOR */
      define( 'CONST_B', 'val-b' );
      require_once( ABSPATH . 'wp-settings.php' );
      """

    When I run `wp config set ANOTHER_NAME another_value --anchor="/** ANCHOR */" --placement=after --separator="\n"`
    Then STDOUT should be:
      """
      Success: Added the 'ANOTHER_NAME' entry in the 'wp-config.php' file with the value 'another_value'.
      """
    And the wp-config.php file should be:
      """
      define( 'CONST_A', 'val-a' );
      define( 'SOME_NAME', 'some_value' );
      /** ANCHOR */
      define( 'ANOTHER_NAME', 'another_value' );
      define( 'CONST_B', 'val-b' );
      require_once( ABSPATH . 'wp-settings.php' );
      """
