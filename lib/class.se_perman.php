<?php



	require_once(EXTENSIONS.'/sections_event/lib/class.se_permissions.php');



	/**
	 * Factory class for easy access to specialized permission objects.
	 */
	Final Class SE_PerMan
	{

		private static $instance;

		private $supported_resources = array('field', 'section');

		private $objects = array();



		private function __construct(){
		}

		private static function instance(){
			if( !self::$instance instanceof SE_PerMan ){
				self::$instance = new SE_PerMan();
			}

			return self::$instance;
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Public interface  */
		/*------------------------------------------------------------------------------------------------*/

		/**
		 * Get a new handle object for this resource type.
		 *
		 * @param $res
		 *
		 * @return SE_PermissionsCrud
		 */
		public static function getCrud($res){
			return self::instance()->getObject( $res, 'crud' );
		}

		/**
		 * Get a new handle object for this resource type.
		 *
		 * @param $res
		 *
		 * @return SE_PermissionsControl
		 */
		public static function getControl($res){
			return self::instance()->getObject( $res, 'control' );
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  XSL Functions. Don't use them :)  */
		/*------------------------------------------------------------------------------------------------*/

		/**
		 * Must set the parameters b/c XSL functions need a fixed number of arguments.
		 *
		 * @param $p1
		 * @param $p2
		 * @param $p3
		 * @param $p4
		 * @param $p5
		 *
		 * @return int
		 */
		public static function control_check($p1, $p2, $p3, $p4, $p5){
			return self::instance()->xslCallbackHandler( __FUNCTION__, func_get_args() ) ? 1 : 0;
		}

		private function xslCallbackHandler($fn, $args){
			// can't be empty
			if( !is_array( $args ) || empty($args) ){
				return null;
			}

			// first param is the resource
			$res = array_shift( $args );

			// these are the type and the method
			list($type, $method) = explode( '_', strtolower( $fn ) );

			// fetch correct type object
			$object = $this->getObject( $res, $type );

			// $obj->$method($args[0], $args[1], ...)
			return (string) call_user_func_array( array($object, $method), $args );
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Internal usage interface  */
		/*------------------------------------------------------------------------------------------------*/

		public function getObject($res, $type){
			$res  = strtolower( $res );
			$type = strtolower( $type );

			if( !in_array( $res, $this->supported_resources ) ){
				return null;
			}

			$obj_id = "$res-$type";

			if( !array_key_exists( $obj_id, $this->objects ) ){
				$this->objects[$obj_id] = $this->createObject( $res, $type );
			}

			return $this->objects[$obj_id];
		}

		private function createObject($res, $type){
			$class_name = "se_{$res}{$type}";

			require_once EXTENSIONS."/sections_event/lib/class.$class_name.php";

			if( !class_exists( $class_name ) ){
				return null;
			}

			return new $class_name($this, $res);
		}

	}
