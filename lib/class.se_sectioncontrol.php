<?php



	require_once(EXTENSIONS.'/sections_event/lib/class.se_permissionscontrol.php');



	Final Class SE_SectionControl extends SE_PermissionsControl
	{

		/**
		 * For each section it stores the linking fields pointing to Members section.
		 *
		 * @var array
		 */
		private $member_fields = array();



		public function __construct($factory, $res){
			parent::__construct( $factory, $res );

			$field_ids = array();

			if( !is_null( extension_Members::getFieldHandle( 'identity' ) ) ){
				$field_ids[] = extension_Members::getField( 'identity' )->get( 'id' );
			}

			if( !is_null( extension_Members::getFieldHandle( 'email' ) ) ){
				$field_ids[] = extension_Members::getField( 'email' )->get( 'id' );
			}

			// Get data about linking fields that point to the members
			// section AND to one of the linking fields (Username/Email)
			$sql_result = Symphony::Database()->fetch( sprintf( "
					SELECT `child_section_id`, `child_section_field_id`
					FROM `tbl_sections_association`
					WHERE `parent_section_id` = %d
					AND `parent_section_field_id` IN ('%s')
				",
				extension_Members::getMembersSection(),
				implode( "','", $field_ids )
			) );

			$result = array();

			if( is_array( $sql_result ) ){
				foreach($sql_result as $data){
					$result[$data['child_section_id']] = array(
						'id' => $data['child_section_field_id'],
					);
				}
			}

			$this->member_fields = $result;
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Public interface  */
		/*------------------------------------------------------------------------------------------------*/

		public function check($section_id, $action, $entry_id = null){
			$target_level = $this->determineActionLevel( $section_id, $entry_id );

			return $this->checkAtLevel( $section_id, $action, $target_level );
		}

		public function getDefaultLevel($action){
			$level = null;

			switch( $action ){
				case SE_Permissions::ACTION_VIEW:
					$level = SE_Permissions::LEVEL_ALL;
					break;

				case SE_Permissions::ACTION_CREATE:
				case SE_Permissions::ACTION_EDIT:
				case SE_Permissions::ACTION_DELETE:
				default:
					$level = SE_Permissions::LEVEL_NONE;
					break;

			}

			return $level;
		}

		public function getAllowedActions(){
			return array(
				SE_Permissions::ACTION_VIEW,
				SE_Permissions::ACTION_CREATE,
				SE_Permissions::ACTION_EDIT,
				SE_Permissions::ACTION_DELETE,
			);
		}

		/**
		 * Checks if given section has a relating field pointing to Members extension
		 *
		 * @param $section_id
		 *
		 * @return bool
		 */
		public function relatedFieldExists($section_id){
			return isset($this->member_fields[$section_id]);
		}

		/**
		 * Get related Members field ID from a section
		 *
		 * @param $section_id
		 *
		 * @return null
		 */
		public function relatedFieldGetId($section_id){
			if( !$this->relatedFieldExists( $section_id ) ){
				return null;
			}

			return $this->member_fields[$section_id]['id'];
		}

		/**
		 * Given section ID and entry ID, it will retrieve related Member Entry ID.
		 * Returns null if it isn't found.
		 *
		 * @param $section_id
		 * @param $entry_id
		 *
		 * @return null
		 */
		public function relatedFieldGetMemberId($section_id, $entry_id){
			if( !$this->relatedFieldExists( $section_id ) ){
				return null;
			}

			if( !isset($this->member_fields[$section_id]['data']) ){
				$relations = array();

				$sql_result = Symphony::Database()->fetch( sprintf(
					"SELECT `entry_id`, `relation_id` FROM `tbl_entries_data_%s`",
					$this->member_fields[$section_id]['id']
				) );

				if( is_array( $sql_result ) ){
					foreach($sql_result as $data){
						$relations[$data['entry_id']] = (int) $data['relation_id'];
					}
				}

				$this->member_fields[$section_id]['data'] = $relations;
			}

			if( !isset($this->member_fields[$section_id]['data'][$entry_id]) ){
				return null;
			}

			return $this->member_fields[$section_id]['data'][$entry_id];
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Internal utilities  */
		/*------------------------------------------------------------------------------------------------*/

		/**
		 * This will determine required action level for given a give section ID.
		 *
		 * @param $section_id
		 * @param $entry_id
		 *
		 * @return integer
		 */
		private function determineActionLevel($section_id, $entry_id = null){

			// if member role is Public, require ALL
			if( $this->memberGetRoleId() == Role::PUBLIC_ROLE ){
				return SE_Permissions::LEVEL_ALL;
			}


			if( !is_numeric($entry_id) ){
				$entry_id = null;
			}


			// if the section is same as Members section
			if( $section_id == extension_Members::getMembersSection() && $entry_id !== null ){

				// check the `entry_id` is the same as the logged in member
				if( $entry_id == $this->memberGetDriver()->getMemberID() ){
					return SE_Permissions::LEVEL_OWN;
				}
			}

			// normal section. If a Members related field exists
			elseif( $this->relatedFieldExists( $section_id ) ){
				if( $entry_id === null ){
					return SE_Permissions::LEVEL_OWN;
				}

				$entry_member_id = $this->relatedFieldGetMemberId($section_id, $entry_id);
				$logged_in_member_id = $this->memberGetDriver()->getMemberID();

				if( $entry_member_id == $logged_in_member_id ){
					return SE_Permissions::LEVEL_OWN;
				}
			}


			// default to ALL
			return SE_Permissions::LEVEL_ALL;
		}

	}
