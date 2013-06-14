<?php



	require_once(EXTENSIONS.'/sections_event/lib/class.se_permissionscontrol.php');



	Final Class SE_SectionControl extends SE_PermissionsControl
	{



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
		public function determineActionLevel($section_id, $entry_id = null){

			// if member role is Public, require highest level of permissions
			if( $this->memberGetRoleId() === Role::PUBLIC_ROLE ){
				return SE_Permissions::LEVEL_ALL;
			}

			$members_sid = extension_Members::getMembersSection();

			// if the section is same as Members section
			if( $section_id == $members_sid ){
				// check the logged in member is the same as the `entry_id` that is about to be updated
				if( $this->memberGetDriver()->getMemberID() == $entry_id ){
					return SE_Permissions::LEVEL_OWN;
				}
				else{
					return SE_Permissions::LEVEL_ALL;
				}
			}

			// if section has a related field pointing to Members section then LEVEL_OWN
			$field_ids = array();

			if( !is_null( extension_Members::getFieldHandle( 'identity' ) ) ){
				$field_ids[] = extension_Members::getField( 'identity' )->get( 'id' );
			}

			if( !is_null( extension_Members::getFieldHandle( 'email' ) ) ){
				$field_ids[] = extension_Members::getField( 'email' )->get( 'id' );
			}

			// Get a count of any linking fields that link to the members
			// section AND to one of the linking fields (Username/Email)
			$count = Symphony::Database()->fetchCol( 'COUNT(*)', sprintf( "
					SELECT COUNT(*)
					FROM `tbl_sections_association`
					WHERE `parent_section_id` = %d
					AND `child_section_id` = %d
					AND `parent_section_field_id` IN ('%s')
				",
				$members_sid,
				$section_id,
				implode( "','", $field_ids )
			) );

			if( (int) $count[0] > 0 ){
				return SE_Permissions::LEVEL_OWN;
			}

			return SE_Permissions::LEVEL_ALL;
		}

	}
