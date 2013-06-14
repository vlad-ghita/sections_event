<?php



	require_once(EXTENSIONS.'/sections_event/lib/class.se_permissionsbase.php');



	Abstract Class SE_PermissionsCrud extends SE_PermissionsBase
	{

		protected $permissions = array();


		/**
		 * Get permissions for all resources for this role
		 *
		 * @param integer $role_id
		 * @param boolean $from_cache
		 *
		 * @return array
		 */
		public function fetchAll($role_id, $from_cache = true){
			if( !isset($this->permissions[$role_id]) || !$from_cache ){
				$permissions = Symphony::Database()->fetch( "SELECT * FROM `{$this->buildTableName()}` WHERE `role_id` = $role_id" );

				$result = array();

				$res_col = $this->buildResCol();

				foreach($permissions as $data){
					$result[$data[$res_col]] = $data;
				}

				$this->permissions[$role_id] = $result;
			}

			return $this->permissions[$role_id];
		}

		/**
		 * Get permissions for one resource for this role
		 *
		 * @param integer $role_id
		 * @param integer $res_id
		 * @param boolean $from_cache
		 *
		 * @return array
		 */
		public function fetchOne($role_id, $res_id, $from_cache = true){
			$permissions = $this->fetchAll($role_id, $from_cache);

			if( isset($permissions[$res_id]) ){
				return $permissions[$res_id];
			}

			return false;
		}

		/**
		 * Get permissions for one resource for this role
		 *
		 * @param integer $role_id
		 * @param integer $res_id
		 * @param string  $action
		 * @param boolean $from_cache
		 *
		 * @return integer|bool - return false if no permissions found
		 */
		public function fetchOneAction($role_id, $res_id, $action, $from_cache = true){
			$permissions = $this->fetchOne( $role_id, $res_id, $from_cache );

			if( is_array( $permissions ) && isset($permissions[$action]) ){
				return (int) $permissions[$action];
			}

			return false;
		}

		/**
		 * Update permissions for all resources for this role.
		 *
		 * @param integer $role_id - if role is specified it will be added to each permissions row
		 * @param array   $permissions
		 *
		 * @return boolean
		 */
		public function updateAll($role_id, array $permissions = array()){
			if( !is_numeric( $role_id ) ){
				return false;
			}

			$this->deleteAll($role_id);

			if( !empty($permissions) ){
				foreach($permissions as &$data){
					$data['role_id'] = $role_id;
				}

				Symphony::Database()->insert( $permissions, $this->buildTableName(), true );
			}

			return true;
		}

		/**
		 * Delete permissions for all resources for this role.
		 *
		 * @param integer $role_id
		 *
		 * @return boolean
		 */
		public function deleteAll($role_id){
			return Symphony::Database()->delete( "`{$this->buildTableName()}`", "`role_id` = $role_id" );
		}

		/**
		 * Update permissions for one resource for this role.
		 *
		 * @param       $role_id
		 * @param       $res_id
		 * @param array $permissions
		 *
		 * @return boolean
		 */
		public function updateOne($role_id, $res_id, array $permissions = array()){
			if( !is_numeric( $role_id ) ){
				return false;
			}

			if( !is_numeric( $res_id ) ){
				return false;
			}

			$this->deleteOne($role_id, $res_id);

			if( !empty($permissions) ){
				$res_col = $this->buildResCol();

				foreach($permissions as &$data){
					$data['role_id'] = $role_id;
					$data[$res_col]  = $res_id;
				}

				Symphony::Database()->insert( $permissions, $this->buildTableName(), true );
			}

			return true;
		}

		/**
		 * Delete permissions for one resource for this role.
		 *
		 * @param integer $role_id
		 * @param integer $res_id
		 *
		 * @return boolean
		 */
		public function deleteOne($role_id, $res_id){
			return Symphony::Database()->delete( "`{$this->buildTableName()}`", "`role_id` = $role_id AND `{$this->buildResCol()}` = $res_id" );
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Internal  */
		/*------------------------------------------------------------------------------------------------*/

		final protected function buildTableName(){
			return "tbl_se_{$this->getRes()}_permissions";
		}

		final protected function buildResCol(){
			return $this->getRes().'_id';
		}

	}
