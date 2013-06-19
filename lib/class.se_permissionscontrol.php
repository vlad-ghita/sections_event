<?php



	require_once(EXTENSIONS.'/sections_event/lib/class.se_permissionsbase.php');



	Abstract Class SE_PermissionsControl extends SE_PermissionsBase
	{

		private $role_id = null;



		/*------------------------------------------------------------------------------------------------*/
		/*  Public interface  */
		/*------------------------------------------------------------------------------------------------*/

		/**
		 * Checks permissions access for given resource ID and action
		 *
		 * @param integer $res_id - field ID, section ID etc
		 * @param string  $action - @see SE_Permissions::ACTION_* constants
		 *
		 * @return boolean
		 */
		abstract public function check($res_id, $action);

		/**
		 * Get permissions level for resource at action
		 *
		 * @param $res_id
		 * @param $action
		 *
		 * @return integer
		 */
		public function getLevel($res_id, $action){
			$role_id = $this->memberGetRoleId();

			$crt_level = $this->getObject( 'crud' )->fetchOneAction( $role_id, $res_id, $action );

			// no permission found in database. Use default value
			if( $crt_level === false ){
				$crt_level = $this->getDefaultLevel( $action );
			}

			return (int) $crt_level;
		}

		/**
		 * Get permission levels for these actions.
		 *
		 * @param       $res_id
		 * @param array $actions - if not specified, will default to allowed actions
		 *
		 * @return array
		 */
		public function getLevels($res_id, array $actions = null){
			if( $actions === null || !is_array( $actions ) ){
				$actions = $this->getAllowedActions();
			}

			$result = array();

			foreach($actions as $action){
				$result[$action] = $this->getLevel( $res_id, $action );
			}

			return $result;
		}

		/**
		 * Return an array of allowed actions on this Resource
		 *
		 * @return array
		 */
		public function getAllowedActions(){
			return array();
		}

		/**
		 * Returns default level for each action.
		 *
		 * @param $action
		 *
		 * @return integer
		 */
		public function getDefaultLevel($action){
			return SE_Permissions::LEVEL_NONE;
		}

		/**
		 * Get current member role ID. From cache !!!
		 *
		 * @return int
		 */
		final public function memberGetRoleId(){
			if( $this->role_id === null ){
				$this->role_id = $this->memberDetermineRoleId();
			}

			return $this->role_id;
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Internal utilities  */
		/*------------------------------------------------------------------------------------------------*/

		/**
		 * Given desired action and target level, check permissions for this resource.
		 *
		 * @param $res_id       - field_id, section_id etc
		 * @param $action       - @see SE_Permissions:::ACTION_* constants for values
		 * @param $target_level - @see SE_Permissions:::LEVEL_* constants for values
		 *
		 * @return bool
		 */
		final protected function checkAtLevel($res_id, $action, $target_level){
			if( !is_numeric( $target_level ) ){
				return false;
			}

			$target_level = (int) $target_level;

			$crt_level = $this->getLevel( $res_id, $action );

			return $crt_level >= $target_level;
		}

		/**
		 * Determine current member role ID.
		 *
		 * @return int
		 */
		final private function memberDetermineRoleId(){
			$driver = $this->memberGetDriver();

			// not logged in?
			if( !$driver->isLoggedIn() ){
				return $this->memberGetDefaultRoleId();
			}

			/** @var $member Entry */
			$member = $driver->getMember();

			$role_data = $member->getData( extension_Members::getField( 'role' )->get( 'id' ) );

			$role = RoleManager::fetch( $role_data['role_id'] );

			// role doesn't exist?
			if( !$role instanceof Role ){
				return $this->memberGetDefaultRoleId();
			}

			return (int) $role_data['role_id'];
		}

		final protected function memberGetDefaultRoleId(){
			return (int) Role::PUBLIC_ROLE;
		}

		/**
		 * Get member driver powering ACL.
		 *
		 * @return SymphonyMember
		 */
		final protected function memberGetDriver(){
			return ExtensionManager::getInstance( 'members' )->getMemberDriver();
		}

	}
