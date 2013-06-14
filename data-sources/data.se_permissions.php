<?php



	require_once(EXTENSIONS.'/sections_event/lib/class.se_permissions.php');



	Final Class DatasourceSE_Permissions extends Datasource
	{

		public function about(){
			return array(
				'name'        => 'SE : Permissions',
				'description' => 'It supplier information about permissions. See result for actual data.'
			);
		}

		public function execute(array &$param_pool = null){
			$result = new XMLElement('se-permissions');

			$actions = array(
				SE_Permissions::ACTION_VIEW,
				SE_Permissions::ACTION_CREATE,
				SE_Permissions::ACTION_EDIT,
				SE_Permissions::ACTION_DELETE,
			);

			$xml_actions = new XMLelement('actions');

			foreach( $actions as $action ){
				$xml_actions->appendChild(
					new XMLelement($action, $action)
				);
			}

			$result->appendChild($xml_actions);

			return $result;
		}

	}
