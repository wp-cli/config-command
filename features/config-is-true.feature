Feature: Determine whether the value of a constant or variable defined in wp-config.php and wp-custom-config.php files is true.

  Scenario: Get the value of a variable whose value is true
    Given a WP install

    When I run `wp config set WP_TRUTH true`
    When I run `wp config get_truth WP_TRUTH`
    Then STDOUT should be:
      """
      true
      """

    When I run `wp config set WP_TRUTH "true"`
    When I run `wp config get_truth WP_TRUTH`
    Then STDOUT should be:
      """
      true
      """

  Scenario: Get the value of a variable whose value is not true
    Given a WP install

    When I run `wp config set WP_FALSE false`
    When I run `wp config get_truth WP_FALSE`
    Then STDOUT should be:
      """
      false
      """

    When I run `wp config set WP_FALSE_STRING "false"`
    When I run `wp config get_truth WP_FALSE_STRING`
    Then STDOUT should be:
      """
      false
      """

    When I run `wp config set WP_STRING "foobar"`
    When I run `wp config get_truth WP_STRING`
    Then STDOUT should be:
      """
      false
      """
