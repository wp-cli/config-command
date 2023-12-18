Feature: Create a wp-config file

  # Skipped for SQLite because `wp db create` does not yet support SQLite.
  # See https://github.com/wp-cli/db-command/issues/234
  # and https://github.com/wp-cli/config-command/issues/167
  @require-mysql
  Scenario: No wp-config.php
    Given an empty directory
    And WP files

    When I try `wp core is-installed`
    Then the return code should be 1
    And STDERR should not be empty

    When I run `wp core version`
    Then STDOUT should not be empty

    When I try `wp core install`
    Then the return code should be 1
    And STDERR should be:
      """
      Error: 'wp-config.php' not found.
      Either create one manually or use `wp config create`.
      """

    Given a wp-config-extra.php file:
      """
      define( 'WP_DEBUG_LOG', true );
      """

    When I run `wp config create {CORE_CONFIG_SETTINGS} --skip-check --extra-php < wp-config-extra.php`
    Then the wp-config.php file should contain:
      """
      'AUTH_SALT',
      """
    And the wp-config.php file should contain:
      """
      define( 'WP_DEBUG_LOG', true );
      """

    When I try the previous command again
    Then the return code should be 1
    And STDERR should not be empty

    Given a wp-config-extra.php file:
      """
      define( 'WP_DEBUG_LOG', true );
      """

    When I run `wp config create {CORE_CONFIG_SETTINGS} --skip-check --config-file='wp-custom-config.php' --extra-php < wp-config-extra.php`
    Then the wp-custom-config.php file should contain:
      """
      'AUTH_SALT',
      """
    And the wp-custom-config.php file should contain:
      """
      define( 'WP_DEBUG_LOG', true );
      """

    When I try the previous command again
    Then the return code should be 1
    And STDERR should not be empty

    When I run `wp db create`
    Then STDOUT should not be empty

    When I try `wp option get option home`
    Then STDERR should contain:
      """
      Error: The site you have requested is not installed
      """

    When I run `rm wp-custom-config.php`
    Then the wp-custom-config.php file should not exist

    Given a wp-config-extra.php file:
      """
      define( 'WP_DEBUG', true );
      """

    When I run `wp config create {CORE_CONFIG_SETTINGS} --config-file='wp-custom-config.php' --extra-php < wp-config-extra.php`
    Then the wp-custom-config.php file should contain:
      """
      define( 'WP_DEBUG', true );
      """
    And the wp-custom-config.php file should contain:
      """
      define( 'WP_DEBUG', false );
      """

    When I try `wp version`
    Then STDERR should not contain:
    """
    Constant WP_DEBUG already defined
    """

  @require-wp-4.0
  Scenario: No wp-config.php and WPLANG
    Given an empty directory
    And WP files
    And a wp-config-extra.php file:
      """
      define( 'WP_DEBUG_LOG', true );
      """

    When I run `wp config create {CORE_CONFIG_SETTINGS} --skip-check --extra-php < wp-config-extra.php`
    Then the wp-config.php file should not contain:
      """
      define( 'WPLANG', '' );
      """

  Scenario: Configure with existing salts
    Given an empty directory
    And WP files

    When I run `wp config create {CORE_CONFIG_SETTINGS} --skip-check --skip-salts --extra-php < /dev/null`
    Then the wp-config.php file should not contain:
      """
      define('AUTH_SALT',
      """
    And the wp-config.php file should not contain:
      """
      define( 'AUTH_SALT',
      """

  Scenario: Configure with invalid table prefix
    Given an empty directory
    And WP files

    When I try `wp config create --skip-check --dbname=somedb --dbuser=someuser --dbpass=somepassword --dbprefix=""`
    Then the return code should be 1
    And STDERR should contain:
      """
      Error: --dbprefix cannot be empty
      """

    When I try `wp config create --skip-check --dbname=somedb --dbuser=someuser --dbpass=somepassword --dbprefix=" "`
    Then the return code should be 1
    And STDERR should contain:
      """
      Error: --dbprefix can only contain numbers, letters, and underscores.
      """

    When I try `wp config create --skip-check --dbname=somedb --dbuser=someuser --dbpass=somepassword --dbprefix="wp-"`
    Then the return code should be 1
    And STDERR should contain:
      """
      Error: --dbprefix can only contain numbers, letters, and underscores.
      """

  @require-mysql
  Scenario: Configure with invalid database credentials
    Given an empty directory
    And WP files

    When I try `wp config create --dbname=somedb --dbuser=someuser --dbpass=somepassword`
    Then the return code should be 1
    And STDERR should contain:
      """
      Error: Database connection error
      """

  @require-mysql
  Scenario: Configure with database credentials using socket path
    Given an empty directory
    And WP files
    And a find-socket.php file:
      """
      <?php
      if ( file_exists( '/var/run/mysqld/mysqld.sock' ) ) {
        echo '/var/run/mysqld/mysqld.sock';
      } else if ( file_exists( '/tmp/mysql.sock' ) ) {
        echo '/tmp/mysql.sock';
      } else {
        echo 'No socket found';
        exit(1);
      }
      """

    When I run `php find-socket.php`
    Then save STDOUT as {SOCKET}
    And STDOUT should not be empty

    When I try `wget -O {RUN_DIR}/install-package-tests https://raw.githubusercontent.com/wp-cli/wp-cli-tests/main/bin/install-package-tests`
    Then STDERR should contain:
      """
      install-package-tests' saved
      """

    When I run `chmod +x {RUN_DIR}/install-package-tests`
    Then STDERR should be empty

    When I run `WP_CLI_TEST_DBHOST={SOCKET} {RUN_DIR}/install-package-tests`
    Then STDOUT should contain:
      """
      Detected MySQL
      """

    When I run `wp config create --dbname='{DB_NAME}' --dbuser='{DB_USER}' --dbpass='{DB_PASSWORD}' --dbhost='localhost:{SOCKET}'`
    Then the wp-config.php file should contain:
      """
      define( 'DB_HOST', 'localhost:{SOCKET}' );
      """

  @require-php-7.0
  Scenario: Configure with salts generated
    Given an empty directory
    And WP files

    When I run `wp config create {CORE_CONFIG_SETTINGS} --skip-check`
    Then the wp-config.php file should contain:
      """
      define( 'AUTH_SALT',
      """

  @less-than-php-7.0
  Scenario: Configure with salts fetched from WordPress.org
    Given an empty directory
    And WP files

    When I run `wp config create {CORE_CONFIG_SETTINGS}`
    Then the wp-config.php file should contain:
      """
      define( 'AUTH_SALT',
      """

  Scenario: Define WPLANG when running WP < 4.0
    Given an empty directory
    And I run `wp core download --version=3.9 --force`

    When I run `wp config create {CORE_CONFIG_SETTINGS} --skip-check`
    Then the wp-config.php file should contain:
      """
      define( 'WPLANG', '' );
      """

    When I try `wp config create {CORE_CONFIG_SETTINGS}`
    Then the return code should be 1
    And STDERR should contain:
      """
      Error: The 'wp-config.php' file already exists.
      """

    When I run `wp config create {CORE_CONFIG_SETTINGS} --skip-check --locale=ja --force`
    Then the return code should be 0
    And STDOUT should contain:
      """
      Success: Generated 'wp-config.php' file.
      """
    And the wp-config.php file should contain:
      """
      define( 'WPLANG', 'ja' );
      """

    When I run `wp config create {CORE_CONFIG_SETTINGS} --skip-check --config-file=wp-custom-config.php --locale=ja --force`
    Then the return code should be 0
    And STDOUT should contain:
      """
      Success: Generated 'wp-custom-config.php' file.
      """
    And the wp-custom-config.php file should contain:
      """
      define( 'WPLANG', 'ja' );
      """

  Scenario: Values are properly escaped to avoid creating invalid config files
    Given an empty directory
    And WP files

    When I run `wp config create --skip-check --dbname=somedb --dbuser=someuser --dbpass="PasswordWith'SingleQuotes'"`
    Then the wp-config.php file should contain:
      """
      define( 'DB_PASSWORD', 'PasswordWith\'SingleQuotes\'' )
      """

    When I run `wp config get DB_PASSWORD`
    Then STDOUT should be:
      """
      PasswordWith'SingleQuotes'
      """

