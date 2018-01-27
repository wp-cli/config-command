Feature: Check whether the wp-config.php file has a certain variable or constant

  Background:
    Given a WP install

  Scenario: Check the existence of an existing wp-config.php constant or variable
    When I run `wp config has DB_NAME`
    Then STDOUT should be empty
    And the return code should be 0

    When I run `wp config has DB_USER --type=constant`
    Then STDOUT should be empty
    And the return code should be 0

    When I run `wp config has table_prefix --type=variable`
    Then STDOUT should be empty
    And the return code should be 0

  Scenario: Check the existence of a non-existing wp-config.php constant or variable
    When I try `wp config has FOO`
    Then STDOUT should be empty
    And STDERR should be empty
    And the return code should be 1

    When I try `wp config has FOO --type=constant`
    Then STDOUT should be empty
    And STDERR should be empty
    And the return code should be 1

    When I try `wp config has FOO --type=variable`
    Then STDOUT should be empty
    And STDERR should be empty
    And the return code should be 1

    When I try `wp config has DB_HOST --type=variable`
    Then STDOUT should be empty
    And STDERR should be empty
    And the return code should be 1

    When I try `wp config has table_prefix --type=constant`
    Then STDOUT should be empty
    And STDERR should be empty
    And the return code should be 1

  Scenario: Ambiguous check throw errors
    When I run `wp config set SOME_KEY some_value --type=constant`
    Then STDOUT should be:
      """
      Success: Added the key 'SOME_KEY' in the 'wp-config.php' file with the value 'some_value'.
      """

    When I run `wp config set SOME_KEY some_value --type=variable`
    Then STDOUT should be:
      """
      Success: Added the key 'SOME_KEY' in the 'wp-config.php' file with the value 'some_value'.
      """

    When I run `wp config list --fields=key,type SOME_KEY --strict`
    Then STDOUT should be a table containing rows:
      | key      | type     |
      | SOME_KEY | constant |
      | SOME_KEY | variable |

    When I try `wp config has SOME_KEY`
    Then STDERR should be:
      """
      Error: Found both a constant and a variable 'SOME_KEY' in the 'wp-config.php' file. Use --type=<type> to disambiguate.
      """
