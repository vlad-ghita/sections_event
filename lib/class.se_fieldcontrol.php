<?php



	require_once(EXTENSIONS.'/sections_event/lib/class.se_permissionscontrol.php');



	Final Class SE_FieldControl extends SE_PermissionsControl
	{

		public function check($field_id, $action){
			return $this->checkAtLevel( $field_id, $action, SE_Permissions::LEVEL_ALL );
		}

		public function getDefaultLevel($action){
			return SE_Permissions::LEVEL_ALL;
		}

		public function getAllowedActions(){
			return array(
				SE_Permissions::ACTION_VIEW,
				SE_Permissions::ACTION_EDIT,
			);
		}

	}
