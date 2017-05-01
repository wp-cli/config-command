<?php

use \WP_CLI\Utils;

/**
 * Manage the wp-config.php file
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
	 * Generate a wp-config.php file.
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
	 *     $ wp core config --dbname=testing --dbuser=wp --dbpass=securepswd --locale=ro_RO
	 *     Success: Generated 'wp-config.php' file.
	 *
	 *     # Enable WP_DEBUG and WP_DEBUG_LOG
	 *     $ wp core config --dbname=testing --dbuser=wp --dbpass=securepswd --extra-php <<PHP
	 *     $ define( 'WP_DEBUG', true );
	 *     $ define( 'WP_DEBUG_LOG', true );
	 *     $ PHP
	 *     Success: Generated 'wp-config.php' file.
	 *
	 *     # Avoid disclosing password to bash history by reading from password.txt
	 *     $ wp core config --dbname=testing --dbuser=wp --prompt=dbpass < password.txt
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
		if ( ! \WP_CLI\Utils\get_flag_value( $assoc_args, 'skip-check' ) ) {
			Utils\run_mysql_command( 'mysql --no-defaults', array(
				'execute' => ';',
				'host' => $assoc_args['dbhost'],
				'user' => $assoc_args['dbuser'],
				'pass' => $assoc_args['dbpass'],
			) );
		}

		if ( \WP_CLI\Utils\get_flag_value( $assoc_args, 'extra-php' ) === true ) {
			$assoc_args['extra-php'] = file_get_contents( 'php://stdin' );
		}

		// TODO: adapt more resilient code from wp-admin/setup-config.php
		if ( ! \WP_CLI\Utils\get_flag_value( $assoc_args, 'skip-salts' ) ) {
			$assoc_args['keys-and-salts'] = self::_read(
				'https://api.wordpress.org/secret-key/1.1/salt/' );
		}

		if ( \WP_CLI\Utils\wp_version_compare( '4.0', '<' ) ) {
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
	 * Get the path to wp-config.php file.
	 *
	 * ## EXAMPLES
	 *
	 *     # Get wp-config.php file path
	 *     $ wp config path
	 *     /home/person/htdocs/project/wp-config.php
	 */
	public function path() {
		$path = Utils\locate_wp_config();
		if ( $path ) {
			WP_CLI::line( $path );
		}
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

}
