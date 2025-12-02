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
      // The WP_CLI_TEST_DBSOCKET variable can be set in the environment to
      // override the default locations and will take precedence.
      if ( ! empty( getenv( 'WP_CLI_TEST_DBSOCKET' ) ) ) {
        echo getenv( 'WP_CLI_TEST_DBSOCKET' );
        exit(0);
      }
      // From within Behat, the WP_CLI_TEST_DBSOCKET will be mapped to the internal
      // DB_SOCKET variable, as Behat pushes a new environment context.
      $locations = [
        '{DB_SOCKET}',
        '/var/run/mysqld/mysqld.sock',
        '/tmp/mysql.sock',
      ];
      foreach ( $locations as $location ) {
        if ( ! empty( $location ) && file_exists( $location ) ) {
          echo $location;
          exit(0);
        }
      }
      echo 'No socket found';
      exit(1);
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

    # We try to account for the warnings we get for passing the password on the command line.
    When I try `MYSQL_HOST=localhost WP_CLI_TEST_DBHOST='localhost:{SOCKET}' WP_CLI_TEST_DBROOTPASS='root' {RUN_DIR}/install-package-tests`
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

  Scenario: Passwords with special characters and double quotes
    Given an empty directory
    And WP files

    When I run `wp config create --skip-check --dbname=somedb --dbuser=someuser --dbpass='p@(ss){w0r?d><}"!With"DoubleQuotes'`
    Then the wp-config.php file should contain:
      """
      define( 'DB_PASSWORD', 'p@(ss){w0r?d><}"!With"DoubleQuotes' )
      """

    When I run `wp config get DB_PASSWORD`
    Then STDOUT should be:
      """
      p@(ss){w0r?d><}"!With"DoubleQuotes
      """

  Scenario: Passwords with backslash should properly escaped
    Given an empty directory
    And WP files
  
    When I run `wp config create --skip-check --dbname=somedb --dbuser=someuser --dbpass='my\\password'`
    Then the wp-config.php file should contain:
      """
      define( 'DB_PASSWORD', 'my\\\\password' )
      """
    
    When I run `wp config get DB_PASSWORD`
    Then STDOUT should be:
      """
      my\\password
      """

  @require-mysql @require-mysql-5.7
  Scenario: Configure with required SSL connection
    Given an empty directory
    And WP files
    And I run `MYSQL_PWD='{DB_ROOT_PASSWORD}' MYSQL_HOST='{MYSQL_HOST}' MYSQL_TCP_PORT='{MYSQL_PORT}' mysql -u root -e "CREATE USER IF NOT EXISTS 'wp_cli_test_ssl'@'%' IDENTIFIED BY 'password2' REQUIRE SSL;"`

    When I try `wp config create --dbhost=127.0.0.1 --dbname=wp_cli_test --dbuser=wp_cli_test_ssl --dbpass=password2 --ssl`
    Then the return code should be 0
    And the wp-config.php file should contain:
      """
      define( 'DB_USER', 'wp_cli_test_ssl' )
      """
