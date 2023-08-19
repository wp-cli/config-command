Feature: Determine whether the value of a constant or variable defined in wp-config.php and wp-custom-config.php files is true.

  Scenario: Get the value of a variable whose value is true
    Given a WP install

    When I run `wp config set WP_TRUTH true`
    Then STDOUT should contain:
    """
    Success:
    """
    When I try `wp config is_true WP_TRUTH`
    Then STDOUT should be empty
    Then STDERR should be empty
    And the return code should be 1

    When I run `wp config set WP_TRUTH "true"`
    Then STDOUT should contain:
    """
    Success:
    """
    When I try `wp config is_true WP_TRUTH`
    Then STDOUT should be empty
    Then STDERR should be empty
    And the return code should be 1

    When I run `wp config set WP_FALSE_STRING "false"`
    Then STDOUT should contain:
    """
    Success:
    """
    When I try `wp config is_true WP_FALSE_STRING`
    Then STDOUT should be empty
    Then STDERR should be empty
    And the return code should be 1

    When I run `wp config set WP_STRING "foobar"`
    Then STDOUT should contain:
    """
    Success:
    """
    When I try `wp config is_true WP_STRING`
    Then STDOUT should be empty
    Then STDERR should be empty
    And the return code should be 1

  Scenario: Get the value of a variable whose value is not true
    Given a WP install

    When I run `wp config set WP_FALSE false --raw`
    Then STDOUT should contain:
    """
    Success:
    """
    When I try `wp config is_true WP_FALSE`
    Then STDOUT should be empty
    And the return code should be 0
