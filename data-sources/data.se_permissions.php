<?php



	require_once(EXTENSIONS.'/sections_event/lib/class.se_permissions.php');



	Final Class DatasourceSE_Permissions extends Datasource
	{

		public function about(){
			return array(
				'name'        => 'SE : Permissions',
				'description' => 'It supplies information about permissions. See result for actual data.'
			);
		}

		public function execute(array &$param_pool = null){
			$result = new XMLElement('se-permissions');

			$result->appendChild(
				$this->buildActions()
			);

			$result->appendChild(
				$this->buildLevels()
			);

			return $result;
		}

		private function buildActions(){
			$actions = array(
				SE_Permissions::ACTION_VIEW,
				SE_Permissions::ACTION_CREATE,
				SE_Permissions::ACTION_EDIT,
				SE_Permissions::ACTION_DELETE,
			);

			$result = new XMLelement('actions');

			foreach( $actions as $action ){
				$result->appendChild(
					new XMLelement($action, $action)
				);
			}

			return $result;
		}

		private function buildLevels(){
			$levels = array(
				SE_Permissions::LEVEL_NONE => 'none',
				SE_Permissions::LEVEL_OWN => 'own',
				SE_Permissions::LEVEL_ALL => 'all',
			);

			$result = new XMLelement('levels');

			foreach( $levels as $level_num => $level_text ){
				$result->appendChild(
					new XMLelement($level_text, $level_num)
				);
			}

			return $result;
		}

	}
