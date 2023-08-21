Feature: Determine whether the value of a constant or variable defined in wp-config.php and wp-custom-config.php files is true.
  Background:
    Given an empty directory
    And WP files
    And wp-config.php

  Scenario Outline: Get the value of a variable whose value is true
    When I run `wp config set <variable> <value> --type=<type> <raw>`
    Then STDOUT should contain:
    """
    Success:
    """
    When I try `wp config is-true <variable>`
    Then STDOUT should be empty
    Then STDERR should be empty
    And the return code should be 0

    Examples:
      | variable          | value     | type      | raw   |
      | WP_TRUTH          | true      | all       | --raw |
      | WP_STR_TRUTH      | 'true'    | all       |       |
      | WP_STRING_MISC    | 'foobar'  | all       |       |
      | WP_FALSE_STRING   | 'false'   | all       |       |
      | wp_str_var_truth  | 'true'    | variable  |       |
      | wp_str_var_false  | 'false'   | variable  |       |
      | wp_str_var_misc   | 'foobar'  | variable  |       |

  Scenario Outline: Get the value of a variable whose value is not true
    When I run `wp config set <variable> <value> --type=<type> <raw>`
    Then STDOUT should contain:
    """
    Success:
    """
    When I try `wp config is-true <variable>`
    Then STDOUT should be empty
    And the return code should be 1

    Examples:
      | variable               | value | type     | raw   |
      | WP_FALSE               | false | all      | --raw |
      | WP_STRZERO             | '0'   | all      |       |
      | WP_NUMZERO             | 0     | all      |       |
      | wp_variable_bool_false | false | variable | --raw |

  Scenario Outline: Test for values which do not exist
    When I try `wp config is-true <variable> --type=<type>`
    Then STDOUT should be empty
    And the return code should be 1

    Examples:
      | variable             | type     |
      | WP_TEST_CONSTANT_DNE | all      |
      | wp_test_variable_dne | variable |
