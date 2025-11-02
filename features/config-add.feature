Feature: Add a constant or variable to wp-config.php file

  Scenario: Add a new constant to wp-config.php
    Given a WP install

    When I run `wp config add NEW_CONSTANT constant_value`
    Then STDOUT should be:
      """
      Success: Added the constant 'NEW_CONSTANT' to the 'wp-config.php' file with the value 'constant_value'.
      """

    When I run `wp config get NEW_CONSTANT`
    Then STDOUT should be:
      """
      constant_value
      """

  Scenario: Add a new variable to wp-config.php
    Given a WP install

    When I run `wp config add new_variable variable_value --type=variable`
    Then STDOUT should be:
      """
      Success: Added the variable 'new_variable' to the 'wp-config.php' file with the value 'variable_value'.
      """

    When I run `wp config get new_variable`
    Then STDOUT should be:
      """
      variable_value
      """

  Scenario: Add a raw constant to wp-config.php
    Given a WP install

    When I run `wp config add WP_DEBUG true --raw`
    Then STDOUT should be:
      """
      Success: Added the constant 'WP_DEBUG' to the 'wp-config.php' file with the raw value 'true'.
      """

    When I run `wp config list WP_DEBUG --strict --format=json`
    Then STDOUT should contain:
      """
      {"name":"WP_DEBUG","value":true,"type":"constant"}
      """

  Scenario: Fail when trying to add an existing constant
    Given a WP install

    When I run `wp config add TEST_CONSTANT test_value`
    Then STDOUT should be:
      """
      Success: Added the constant 'TEST_CONSTANT' to the 'wp-config.php' file with the value 'test_value'.
      """

    When I try `wp config add TEST_CONSTANT another_value`
    Then STDERR should be:
      """
      Error: The constant 'TEST_CONSTANT' already exists in the 'wp-config.php' file.
      """

  Scenario: Fail when trying to add an existing variable
    Given a WP install

    When I run `wp config add test_variable test_value --type=variable`
    Then STDOUT should be:
      """
      Success: Added the variable 'test_variable' to the 'wp-config.php' file with the value 'test_value'.
      """

    When I try `wp config add test_variable another_value --type=variable`
    Then STDERR should be:
      """
      Error: The variable 'test_variable' already exists in the 'wp-config.php' file.
      """

  @custom-config-file
  Scenario: Add a new constant to wp-custom-config.php
    Given an empty directory
    And WP files

    When I run `wp config create {CORE_CONFIG_SETTINGS} --skip-check --config-file='wp-custom-config.php'`
    Then STDOUT should contain:
      """
      Generated 'wp-custom-config.php' file.
      """

    When I run `wp config add NEW_CONSTANT constant_value --config-file='wp-custom-config.php'`
    Then STDOUT should be:
      """
      Success: Added the constant 'NEW_CONSTANT' to the 'wp-custom-config.php' file with the value 'constant_value'.
      """

    When I run `wp config get NEW_CONSTANT --config-file='wp-custom-config.php'`
    Then STDOUT should be:
      """
      constant_value
      """

  Scenario: Additions can be properly placed in wp-config.php
    Given a WP install
    And a wp-config.php file:
      """
      define( 'CONST_A', 'val-a' );
      /** ANCHOR */
      define( 'CONST_B', 'val-b' );
      require_once( ABSPATH . 'wp-settings.php' );
      """

    When I run `wp config add SOME_NAME some_value --anchor="/** ANCHOR */" --placement=before --separator="\n"`
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

    When I run `wp config add ANOTHER_NAME another_value --anchor="/** ANCHOR */" --placement=after --separator="\n"`
    Then STDOUT should be:
      """
      Success: Added the constant 'ANOTHER_NAME' to the 'wp-config.php' file with the value 'another_value'.
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
