<?php
use \WP_CLI\Utils;

/**
 * Generates and reads the wp-config.php file.
 */
class Config_Command extends WP_CLI_Command {

	private static function get_initial_locale() {
		include ABSPATH . '/wp-includes/version.php';

		// @codingStandardsIgnoreStart
		if ( isset( $wp_local_package ) )
			return $wp_local_package;
		// @codingStandardsIgnoreEnd

		return '';
	}

	/**
	 * Generates a wp-config.php file.
	 *
	 * Creates a new wp-config.php with database constants, and verifies that
	 * the database constants are correct.
	 *
	 * ## OPTIONS
	 *
	 * --dbname=<dbname>
	 * : Set the database name.
	 *
	 * --dbuser=<dbuser>
	 * : Set the database user.
	 *
	 * [--dbpass=<dbpass>]
	 * : Set the database user password.
	 *
	 * [--dbhost=<dbhost>]
	 * : Set the database host.
	 * ---
	 * default: localhost
	 * ---
	 *
	 * [--dbprefix=<dbprefix>]
	 * : Set the database table prefix.
	 * ---
	 * default: wp_
	 * ---
	 *
	 * [--dbcharset=<dbcharset>]
	 * : Set the database charset.
	 * ---
	 * default: utf8
	 * ---
	 *
	 * [--dbcollate=<dbcollate>]
	 * : Set the database collation.
	 * ---
	 * default:
	 * ---
	 *
	 * [--locale=<locale>]
	 * : Set the WPLANG constant. Defaults to $wp_local_package variable.
	 *
	 * [--extra-php]
	 * : If set, the command copies additional PHP code into wp-config.php from STDIN.
	 *
	 * [--skip-salts]
	 * : If set, keys and salts won't be generated, but should instead be passed via `--extra-php`.
	 *
	 * [--skip-check]
	 * : If set, the database connection is not checked.
	 *
	 * [--force]
	 * : Overwrites existing files, if present.
	 *
	 * ## EXAMPLES
	 *
	 *     # Standard wp-config.php file
	 *     $ wp config create --dbname=testing --dbuser=wp --dbpass=securepswd --locale=ro_RO
	 *     Success: Generated 'wp-config.php' file.
	 *
	 *     # Enable WP_DEBUG and WP_DEBUG_LOG
	 *     $ wp config create --dbname=testing --dbuser=wp --dbpass=securepswd --extra-php <<PHP
	 *     define( 'WP_DEBUG', true );
	 *     define( 'WP_DEBUG_LOG', true );
	 *     PHP
	 *     Success: Generated 'wp-config.php' file.
	 *
	 *     # Avoid disclosing password to bash history by reading from password.txt
	 *     # Using --prompt=dbpass will prompt for the 'dbpass' argument
	 *     $ wp config create --dbname=testing --dbuser=wp --prompt=dbpass < password.txt
	 *     Success: Generated 'wp-config.php' file.
	 */
	public function create( $_, $assoc_args ) {
		global $wp_version;
		if ( ! \WP_CLI\Utils\get_flag_value( $assoc_args, 'force' ) && Utils\locate_wp_config() ) {
			WP_CLI::error( "The 'wp-config.php' file already exists." );
		}

		$versions_path = ABSPATH . 'wp-includes/version.php';
		include $versions_path;

		$defaults = array(
			'dbhost' => 'localhost',
			'dbpass' => '',
			'dbprefix' => 'wp_',
			'dbcharset' => 'utf8',
			'dbcollate' => '',
			'locale' => self::get_initial_locale()
		);
		$assoc_args = array_merge( $defaults, $assoc_args );

		if ( preg_match( '|[^a-z0-9_]|i', $assoc_args['dbprefix'] ) )
			WP_CLI::error( '--dbprefix can only contain numbers, letters, and underscores.' );

		// Check DB connection
		if ( ! Utils\get_flag_value( $assoc_args, 'skip-check' ) ) {
			Utils\run_mysql_command( '/usr/bin/env mysql --no-defaults', array(
				'execute' => ';',
				'host' => $assoc_args['dbhost'],
				'user' => $assoc_args['dbuser'],
				'pass' => $assoc_args['dbpass'],
			) );
		}

		if ( Utils\get_flag_value( $assoc_args, 'extra-php' ) === true ) {
			$assoc_args['extra-php'] = file_get_contents( 'php://stdin' );
		}

		if ( ! Utils\get_flag_value( $assoc_args, 'skip-salts' ) ) {
			try {
				$assoc_args['keys-and-salts'] = true;
				$assoc_args['auth-key'] = self::unique_key();
				$assoc_args['secure-auth-key'] = self::unique_key();
				$assoc_args['logged-in-key'] = self::unique_key();
				$assoc_args['nonce-key'] = self::unique_key();
				$assoc_args['auth-salt'] = self::unique_key();
				$assoc_args['secure-auth-salt'] = self::unique_key();
				$assoc_args['logged-in-salt'] = self::unique_key();
				$assoc_args['nonce-salt'] = self::unique_key();
			} catch ( Exception $e ) {
				$assoc_args['keys-and-salts'] = false;
				$assoc_args['keys-and-salts-alt'] = self::_read(
					'https://api.wordpress.org/secret-key/1.1/salt/' );
			}
		}

		if ( Utils\wp_version_compare( '4.0', '<' ) ) {
			$assoc_args['add-wplang'] = true;
		} else {
			$assoc_args['add-wplang'] = false;
		}

		$command_root = Utils\phar_safe_path( dirname( __DIR__ ) );
		$out = Utils\mustache_render( $command_root . '/templates/wp-config.mustache', $assoc_args );

		$bytes_written = file_put_contents( ABSPATH . 'wp-config.php', $out );
		if ( ! $bytes_written ) {
			WP_CLI::error( "Could not create new 'wp-config.php' file." );
		} else {
			WP_CLI::success( "Generated 'wp-config.php' file." );
		}
	}

	/**
	 * Gets the path to wp-config.php file.
	 *
	 * ## EXAMPLES
	 *
	 *     # Get wp-config.php file path
	 *     $ wp config path
	 *     /home/person/htdocs/project/wp-config.php
	 *
	 * @when before_wp_load
	 */
	public function path() {
		WP_CLI::line( $this->get_config_path() );
	}

	/**
	 * Lists variables, constants, and file includes defined in wp-config.php file.
	 *
	 * ## OPTIONS
	 *
	 * [<filter>...]
	 * : Key or partial key to filter the list by.
	 *
	 * [--fields=<fields>]
	 * : Limit the output to specific fields. Defaults to all fields.
	 *
	 * [--format=<format>]
	 * : Render output in a particular format.
	 * ---
	 * default: table
	 * options:
	 *   - table
	 *   - csv
	 *   - json
	 *   - yaml
	 * ---
	 *
	 * [--strict]
	 * : Enforce strict matching when a filter is provided.
	 *
	 * ## EXAMPLES
	 *
	 *     # List variables and constants defined in wp-config.php file.
	 *     $ wp config list
	 *     +------------------+------------------------------------------------------------------+----------+
	 *     | key              | value                                                            | type     |
	 *     +------------------+------------------------------------------------------------------+----------+
	 *     | table_prefix     | wp_                                                              | variable |
	 *     | DB_NAME          | wp_cli_test                                                      | constant |
	 *     | DB_USER          | root                                                             | constant |
	 *     | DB_PASSWORD      | root                                                             | constant |
	 *     | AUTH_KEY         | r6+@shP1yO&$)1gdu.hl[/j;7Zrvmt~o;#WxSsa0mlQOi24j2cR,7i+QM/#7S:o^ | constant |
	 *     | SECURE_AUTH_KEY  | iO-z!_m--YH$Tx2tf/&V,YW*13Z_HiRLqi)d?$o-tMdY+82pK$`T.NYW~iTLW;xp | constant |
	 *     +------------------+------------------------------------------------------------------+----------+
	 *
	 *     # List only database user and password from wp-config.php file.
	 *     $ wp config list DB_USER DB_PASSWORD --strict
	 *     +------------------+-------+----------+
	 *     | key              | value | type     |
	 *     +------------------+-------+----------+
	 *     | DB_USER          | root  | constant |
	 *     | DB_PASSWORD      | root  | constant |
	 *     +------------------+-------+----------+
	 *
	 *     # List all salts from wp-config.php file.
	 *     $ wp config list _SALT
	 *     +------------------+------------------------------------------------------------------+----------+
	 *     | key              | value                                                            | type     |
	 *     +------------------+------------------------------------------------------------------+----------+
	 *     | AUTH_SALT        | n:]Xditk+_7>Qi=>BmtZHiH-6/Ecrvl(V5ceeGP:{>?;BT^=[B3-0>,~F5z$(+Q$ | constant |
	 *     | SECURE_AUTH_SALT | ?Z/p|XhDw3w}?c.z%|+BAr|(Iv*H%%U+Du&kKR y?cJOYyRVRBeB[2zF-`(>+LCC | constant |
	 *     | LOGGED_IN_SALT   | +$@(1{b~Z~s}Cs>8Y]6[m6~TnoCDpE>O%e75u}&6kUH!>q:7uM4lxbB6[1pa_X,q | constant |
	 *     | NONCE_SALT       | _x+F li|QL?0OSQns1_JZ{|Ix3Jleox-71km/gifnyz8kmo=w-;@AE8W,(fP<N}2 | constant |
	 *     +------------------+------------------------------------------------------------------+----------+
	 *
	 * @when before_wp_load
	 * @subcommand list
	 */
	public function list_( $args, $assoc_args ) {
		$path = $this->get_config_path();

		$strict = Utils\get_flag_value( $assoc_args, 'strict' );
		if ( $strict && empty( $args ) ) {
			WP_CLI::error( 'The --strict option can only be used in combination with a filter.' );
		}

		$default_fields = array(
			'key',
			'value',
			'type',
		);

		$defaults = array(
			'fields' => implode( ',', $default_fields ),
			'format' => 'table',
		);

		$assoc_args = array_merge( $defaults, $assoc_args );

		$values = self::get_wp_config_vars();

		if ( ! empty( $args ) ) {
			$values = $this->filter_values( $values, $args, $strict );
		}

		if ( empty( $values ) ) {
			WP_CLI::error( "No matching keys found in 'wp-config.php'." );
		}

		Utils\format_items( $assoc_args['format'], $values, $assoc_args['fields'] );
	}

	/**
	 * Gets the value of a specific variable or constant defined in wp-config.php
	 * file.
	 *
	 * ## OPTIONS
	 *
	 * <key>
	 * : Key for the wp-config.php variable or constant.
	 *
	 * [--type=<type>]
	 * : Type of config value to retrieve. Defaults to 'all'.
	 * ---
	 * default: all
	 * options:
	 *   - constant
	 *   - variable
	 *   - all
	 * ---
	 *
	 * ## EXAMPLES
	 *
	 *     # Get the table_prefix as defined in wp-config.php file.
	 *     $ wp config get table_prefix
	 *     wp_
	 *
	 * @when before_wp_load
	 */
	public function get( $args, $assoc_args ) {
		$path = $this->get_config_path();

		list( $key ) = $args;
		$type = Utils\get_flag_value( $assoc_args, 'type' );

		$value = $this->return_value( $key, $type, self::get_wp_config_vars() );
		WP_CLI::log( $value );
	}

	/**
	 * Get the array of wp-config.php variables and constants.
	 *
	 * @return array
	 */
	private static function get_wp_config_vars() {
		$wp_cli_original_defined_constants = get_defined_constants();
		$wp_cli_original_defined_vars      = get_defined_vars();
		$wp_cli_original_includes          = get_included_files();

		eval( WP_CLI::get_runner()->get_wp_config_code() );

		$wp_config_vars      = self::get_wp_config_diff( get_defined_vars(), $wp_cli_original_defined_vars, 'variable', array( 'wp_cli_original_defined_vars' ) );
		$wp_config_constants = self::get_wp_config_diff( get_defined_constants(), $wp_cli_original_defined_constants, 'constant' );

		foreach ( $wp_config_vars as $key => $value ) {
			if ( 'wp_cli_original_includes' === $value['key'] ) {
				$key_backup = $key;
				break;
			}
		}

		unset( $wp_config_vars[ $key_backup ] );
		$wp_config_vars           = array_values( $wp_config_vars );
		$wp_config_includes       = array_diff( get_included_files(), $wp_cli_original_includes );
		$wp_config_includes_array = array();

		foreach ( $wp_config_includes as $key => $value ) {
			$wp_config_includes_array[] = array(
				'key'   => basename( $value ),
				'value' => $value,
				'type'  => 'includes',
			);
		}

		return array_merge( $wp_config_vars, $wp_config_constants, $wp_config_includes_array );
	}

	/**
	 * Sets the value of a specific variable or constant defined in
	 * wp-config.php file.
	 *
	 * ## OPTIONS
	 *
	 * <key>
	 * : Key for the wp-config.php variable or constant.
	 *
	 * <value>
	 * : Value to set the wp-config.php variable or constant to.
	 *
	 * [--add]
	 * : Add the value if it doesn't exist yet. This is the default behavior. Override with --no-add.
	 *
	 * [--raw]
	 * : Place the value into the wp-config.php file as-is (executable), instead of as a quoted string.
	 *
	 * [--target=<target>]
	 * : Target string to decide where to add new values. Defaults to "/** Absolute path to the WordPress directory".
	 *
	 * [--placement=<placement>]
	 * : Where to place the new values in relation to the target string.
	 * ---
	 * default: 'before'
	 * options:
	 *   - before
	 *   - after
	 * ---
	 *
	 * [--buffer=<buffer>]
	 * : Buffer string to put between an added value and its target string. Defaults to two EOLs.
	 *
	 * [--type=<type>]
	 * : Type of the config value to set. Defaults to 'all'.
	 * ---
	 * default: all
	 * options:
	 *   - constant
	 *   - variable
	 *   - all
	 * ---
	 *
	 * ## EXAMPLES
	 *
	 *     # Set the WP_DEBUG constant to true.
	 *     $ wp config set WP_DEBUG true --raw
	 *
	 * @when before_wp_load
	 */
	public function set( $args, $assoc_args ) {
		$path = $this->get_config_path();

		list( $key, $value ) = $args;
		$type = Utils\get_flag_value( $assoc_args, 'type' );

		$options = array();

		$option_flags = array(
			'raw'       => false,
			'add'       => true,
			'target'    => null,
			'placement' => null,
			'buffer'    => null,
		);

		foreach ( $option_flags as $option => $default ) {
			$option_value = Utils\get_flag_value( $assoc_args, $option, $default );
			if ( null !== $option_value ) {
				$options[ $option ] = $option_value;
				if ( $option === 'buffer' ) {
					$options['buffer'] = $this->parse_buffer( $options['buffer'] );
				}
			}
		}

		$adding = false;
		try {
			$config_transformer = new WPConfigTransformer( $path );

			switch ( $type ) {
				case 'all':
					$has_constant = $config_transformer->exists( 'constant', $key );
					$has_variable = $config_transformer->exists( 'variable', $key );
					if ( $has_constant && $has_variable ) {
						WP_CLI::error( "Found multiple values for '{$key}' in the wp-config.php file. Use --type=<type> to disambiguate." );
					}
					if ( ! $has_constant && ! $has_variable ) {
						if ( ! $options['add'] ) {
							WP_CLI::error( "The '{$key}' variable or constant is not defined in the wp-config.php file." );
						}
						// Default to adding constants if in doubt.
						$type   = 'constant';
						$adding = true;
					} else {
						$type = $has_constant ? 'constant' : 'variable';
					}
					break;
				case 'constant':
				case 'variable':
					if ( ! $config_transformer->exists( $type, $key ) ) {
						if ( ! $options['add'] ) {
							WP_CLI::error( "The '{$key}' {$type} is not defined in the wp-config.php file." );
						}
						$adding = true;
					}
			}

			$config_transformer->update( $type, $key, $value, $options );

		} catch ( Exception $exception ) {
			WP_CLI::error( "Could not process the wp-config.php transformation.\nReason: " . $exception->getMessage() );
		}

		$verb = $adding ? 'Added' : 'Updated';
		$raw  = $options['raw'] ? 'raw ' : '';
		WP_CLI::success( "{$verb} the key '{$key}' in the 'wp-config.php' file with the {$raw}value '{$value}'." );
	}

	/**
	 * Filters wp-config.php file configurations.
	 *
	 * @param array $list
	 * @param array $previous_list
	 * @param string $type
	 * @param array $exclude_list
	 * @return array
	 */
	private static function get_wp_config_diff( $list, $previous_list, $type, $exclude_list = array() ) {
		$result = array();
		foreach ( $list as $key => $val ) {
			if ( array_key_exists( $key, $previous_list ) || in_array( $key, $exclude_list ) ) {
				continue;
			}
			$out = array();
			$out['key'] = $key;
			$out['value'] = $val;
			$out['type'] = $type;
			$result[] = $out;
		}
		return $result;
	}

	private static function _read( $url ) {
		$headers = array('Accept' => 'application/json');
		$response = Utils\http_request( 'GET', $url, null, $headers, array( 'timeout' => 30 ) );
		if ( 200 === $response->status_code ) {
			return $response->body;
		} else {
			WP_CLI::error( "Couldn't fetch response from {$url} (HTTP code {$response->status_code})." );
		}
	}

	/**
	 * Prints the value of a constant or variable defined in the wp-config.php file.
	 *
	 * If the constant or variable is not defined in the wp-config.php file then an error will be returned.
	 *
	 * @param string $key
	 * @param string $type
	 * @param array $values
	 *
	 * @return string The value of the requested constant or variable as defined in the wp-config.php file; if the
	 *                requested constant or variable is not defined then the function will print an error and exit.
	 */
	private function return_value( $key, $type, $values ) {
		$results = array();
		foreach ( $values as $value ) {
			if ( $key === $value['key'] && ( $type === 'all' || $type === $value['type'] ) ) {
				$results[] = $value;
			}
		}

		if ( count( $results ) > 1 ) {
			WP_CLI::error( "Found multiple values for '{$key}' in the wp-config.php file. Use --type=<type> to disambiguate." );
		}

		if ( ! empty( $results ) ) {
			return $results[0]['value'];
		}

		$type = $type === 'all' ? 'variable or constant' : $type;
		$keys = array_column( $values, 'key' );
		$candidate = Utils\get_suggestion( $key, $keys );

		if ( ! empty( $candidate ) && $candidate !== $key ) {
			WP_CLI::error( "The '{$key}' {$type} is not defined in the wp-config.php file.\nDid you mean '{$candidate}'?" );
		}

		WP_CLI::error( "The '{$key}' {$type} is not defined in the wp-config.php file." );
	}

	/**
	 * Generates a unique key/salt for the wp-config.php file.
	 *
	 * @throws Exception
	 *
	 * @return string
	 */
	private static function unique_key() {
		if ( ! function_exists( 'random_int' ) ) {
			throw new Exception( "'random_int' does not exist" );
		}

		$chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_ []{}<>~`+=,.;:/?|';
		$key = '';

		for ( $i = 0; $i < 64; $i++ ) {
			$key .= substr( $chars, random_int( 0, strlen( $chars ) - 1 ), 1 );
		}

		return $key;
	}

	/**
	 * Filters the values based on a provider filter key.
	 *
	 * @param array $values
	 * @param array $filters
	 * @param bool $strict
	 *
	 * @return array
	 */
	private function filter_values( $values, $filters, $strict ) {
		$result = array();

		foreach ( $values as $value ) {
			foreach ( $filters as $filter ) {
				if ( $strict && $filter !== $value['key'] ) {
					continue;
				}

				if ( false === strpos( $value['key'], $filter ) ) {
					continue;
				}

				$result[] = $value;
			}
		}

		return $result;
	}

	/**
	 * Gets the path to the wp-config.php file or gives a helpful error if none
	 * found.
	 *
	 * @return string Path to wp-config.php file.
	 */
	private function get_config_path() {
		$path = Utils\locate_wp_config();
		if ( ! $path ) {
			WP_CLI::error( "'wp-config.php' not found.\nEither create one manually or use `wp config create`." );
		}
		return $path;
	}

	/**
	 * Parses the buffer argument, to allow for special character handling.
	 *
	 * Does the following transformations:
	 * - '\n' => "\n" (newline)
	 * - '\t' => "\t" (tab)
	 *
	 * @param string $buffer Buffer string to parse.
	 *
	 * @return mixed Parsed buffer string.
	 */
	private function parse_buffer( $buffer ) {
		$buffer = str_replace(
			array( '\n', '\t' ),
			array( "\n", "\t" ),
			$buffer
		);

		return $buffer;
	}
}

