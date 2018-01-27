Feature: Delete a constant or variable from the wp-config.php file

  Background:
    Given a WP install

  Scenario: Delete an existing wp-config.php constant
    When I run `wp config delete DB_PASSWORD`
    Then STDOUT should be:
      """
      Success: Deleted the 'DB_PASSWORD' entry from the 'wp-config.php' file.
      """

    When I try `wp config get DB_PASSWORD`
    Then STDERR should be:
      """
      Error: The 'DB_PASSWORD' constant or variable is not defined in the 'wp-config.php' file.
      """
    And STDOUT should be empty

    When I run `wp config delete DB_HOST --type=constant`
    Then STDOUT should be:
      """
      Success: Deleted the 'DB_HOST' entry from the 'wp-config.php' file.
      """

    When I try `wp config get DB_HOST --type=constant`
    Then STDERR should be:
      """
      Error: The 'DB_HOST' constant is not defined in the 'wp-config.php' file.
      """
    And STDOUT should be empty

    When I run `wp config delete table_prefix --type=variable`
    Then STDOUT should be:
      """
      Success: Deleted the 'table_prefix' entry from the 'wp-config.php' file.
      """

    When I try `wp config get table_prefix --type=variable`
    Then STDERR should be:
      """
      Error: The 'table_prefix' variable is not defined in the 'wp-config.php' file.
      """
    And STDOUT should be empty

  Scenario: Delete a non-existent constant or variable
    When I try `wp config delete NEW_CONSTANT`
    Then STDERR should be:
      """
      Error: The 'NEW_CONSTANT' constant or variable is not defined in the 'wp-config.php' file.
      """

    When I try `wp config delete NEW_CONSTANT --type=constant`
    Then STDERR should be:
      """
      Error: The 'NEW_CONSTANT' constant is not defined in the 'wp-config.php' file.
      """

    When I try `wp config delete NEW_CONSTANT --type=variable`
    Then STDERR should be:
      """
      Error: The 'NEW_CONSTANT' variable is not defined in the 'wp-config.php' file.
      """

  Scenario: Ambiguous delete requests throw errors
    When I run `wp config set SOME_NAME some_value --type=constant`
    Then STDOUT should be:
      """
      Success: Added the 'SOME_NAME' constant in the 'wp-config.php' file with the value 'some_value'.
      """

    When I run `wp config set SOME_NAME some_value --type=variable`
    Then STDOUT should be:
      """
      Success: Added the 'SOME_NAME' variable in the 'wp-config.php' file with the value 'some_value'.
      """

    When I run `wp config list --fields=name,type SOME_NAME --strict`
    Then STDOUT should be a table containing rows:
      | name      | type     |
      | SOME_NAME | constant |
      | SOME_NAME | variable |

    When I try `wp config delete SOME_NAME`
    Then STDERR should be:
      """
      Error: Found both a constant and a variable 'SOME_NAME' in the 'wp-config.php' file. Use --type=<type> to disambiguate.
      """
