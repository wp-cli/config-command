Feature: Determine whether the value of a constant or variable defined in wp-config.php is true.
  Background:
    Given an empty directory
    And a wp-includes/version.php file:
      """
      <?php
      $wp_version = '6.3';
      """
    And a wp-config.php file:
      """
      <?php
      /* Truth tests. */
      define( 'WP_TRUTH', true );
      define( 'WP_STR_TRUTH', 'true' );
      define( 'WP_STR_MISC', 'foobar' );
      define( 'WP_STR_FALSE', 'false' );
      $wp_str_var_truth = 'true';
      $wp_str_var_false = 'false';
      $wp_str_var_misc = 'foobar';

      /* False tests. */
      define( 'WP_FALSE', false );
      define( 'WP_STR_ZERO', '0' );
      define( 'WP_NUM_ZERO', 0 );
      $wp_variable_bool_false = false;

      require_once ABSPATH . 'wp-settings.php';
      require_once ABSPATH . 'includes-file.php';
      """
    And a includes-file.php file:
      """
      <?php
      define( 'WP_INC_TRUTH', true );
      define( 'WP_INC_FALSE', false );
      """

  Scenario Outline: Get the value of a variable whose value is true
    When I try `wp config is-true <variable>`
    Then STDOUT should be empty
    Then STDERR should be empty
    And the return code should be 0

    Examples:
      | variable          |
      | WP_TRUTH          |
      | WP_STR_TRUTH      |
      | WP_STR_MISC       |
      | WP_STR_FALSE      |
      | wp_str_var_truth  |
      | wp_str_var_false  |
      | wp_str_var_misc   |

  Scenario Outline: Get the value of a variable whose value is not true
    When I try `wp config is-true <variable>`
    Then STDOUT should be empty
    And the return code should be 1

    Examples:
      | variable               |
      | WP_FALSE               |
      | WP_STRZERO             |
      | WP_NUMZERO             |
      | wp_variable_bool_false |

  Scenario Outline: Test for values which do not exist
    When I try `wp config is-true <variable> --type=<type>`
    Then STDOUT should be empty
    And the return code should be 1

    Examples:
      | variable             | type     |
      | WP_TEST_CONSTANT_DNE | all      |
      | wp_test_variable_dne | variable |

  Scenario: Test for correct functionality with included PHP files.
    When I try `wp config is-true WP_INC_TRUTH`
    Then STDOUT should be empty
    Then STDERR should be empty
    And the return code should be 0

    When I try `wp config is-true WP_INC_FALSE`
    Then STDOUT should be empty
    And the return code should be 1

