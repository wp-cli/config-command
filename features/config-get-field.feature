Feature: Get the value of a constant or variable defined in wp-config.php file

  Background:
    Given a WP install

  Scenario: Get the value of an existing wp-config.php constant
    When I run `wp config get DB_NAME --type=constant`
    Then STDOUT should be:
      """
      wp_cli_test
      """

  Scenario: Get the value of an existing wp-config.php constant without explicit type
    When I run `wp config get DB_NAME`
    Then STDOUT should be:
      """
      wp_cli_test
      """

  Scenario: Get the value of an existing wp-config.php variable
    When I run `wp config get table_prefix --type=variable`
    Then STDOUT should be:
      """
      wp_
      """

  Scenario: Get the value of an existing wp-config.php variable without explicit type
    When I run `wp config get table_prefix`
    Then STDOUT should be:
      """
      wp_
      """

  Scenario: Get the value of a non existing wp-config.php key
    When I try `wp config get FOO`
    Then STDERR should be:
      """
      Error: The 'FOO' variable or constant is not defined in the 'wp-config.php' file.
      """
    And STDOUT should be empty

  Scenario: Get the value of a non existing wp-config.php constant
    When I try `wp config get FOO --type=constant`
    Then STDERR should be:
      """
      Error: The 'FOO' constant is not defined in the 'wp-config.php' file.
      """
    And STDOUT should be empty

  Scenario: Get the value of a non existing wp-config.php variable
    When I try `wp config get foo --type=variable`
    Then STDERR should be:
      """
      Error: The 'foo' variable is not defined in the 'wp-config.php' file.
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php constant with wrong case should yield an error
    When I try `wp config get db_name --type=constant`
    Then STDERR should be:
      """
      Error: The 'db_name' constant is not defined in the 'wp-config.php' file.
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php variable with wrong case should yield an error
    When I try `wp config get TABLE_PREFIX --type=variable`
    Then STDERR should be:
      """
      Error: The 'TABLE_PREFIX' variable is not defined in the 'wp-config.php' file.
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php key with wrong case should yield an error
    When I try `wp config get TABLE_PREFIX`
    Then STDERR should be:
      """
      Error: The 'TABLE_PREFIX' variable or constant is not defined in the 'wp-config.php' file.
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php constant with some similarity should yield a helpful error
    When I try `wp config get DB_NOME --type=constant`
    Then STDERR should be:
      """
      Error: The 'DB_NOME' constant is not defined in the 'wp-config.php' file.
      Did you mean 'DB_NAME'?
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php constant with some similarity should yield a helpful error
    When I try `wp config get table_perfix --type=variable`
    Then STDERR should be:
      """
      Error: The 'table_perfix' variable is not defined in the 'wp-config.php' file.
      Did you mean 'table_prefix'?
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php key with some similarity should yield a helpful error
    When I try `wp config get DB_NOME`
    Then STDERR should be:
      """
      Error: The 'DB_NOME' variable or constant is not defined in the 'wp-config.php' file.
      Did you mean 'DB_NAME'?
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php constant with remote similarity should yield just an error
    When I try `wp config get DB_NOOOOZLE --type=constant`
    Then STDERR should be:
      """
      Error: The 'DB_NOOOOZLE' constant is not defined in the 'wp-config.php' file.
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php variable with remote similarity should yield just an error
    When I try `wp config get tabre_peffix --type=variable`
    Then STDERR should be:
      """
      Error: The 'tabre_peffix' variable is not defined in the 'wp-config.php' file.
      """
    And STDOUT should be empty

  Scenario: Get the value of an existing wp-config.php key with remote similarity should yield just an error
    When I try `wp config get DB_NOOOOZLE`
    Then STDERR should be:
      """
      Error: The 'DB_NOOOOZLE' variable or constant is not defined in the 'wp-config.php' file.
      """
    And STDOUT should be empty

  Scenario: Get the value of a key that exists as both a variable and a constant should yield a helpful error
    Given a wp-config.php file:
      """
      $SOMEKEY = 'value-a';
      define( 'SOMEKEY', 'value-b' );
      require_once( ABSPATH . 'wp-settings.php' );
      """

    When I run `wp config list --format=table`
    Then STDOUT should be a table containing rows:
      | key     | value   | type     |
      | SOMEKEY | value-a | variable |
      | SOMEKEY | value-b | constant |

    When I try `wp config get SOMEKEY`
    Then STDERR should be:
      """
      Error: Found both a constant and a variable 'SOMEKEY' in the 'wp-config.php' file. Use --type=<type> to disambiguate.
      """

    When I run `wp config get SOMEKEY --type=variable`
    Then STDOUT should be:
      """
      value-a
      """

    When I run `wp config get SOMEKEY --type=constant`
    Then STDOUT should be:
      """
      value-b
      """
