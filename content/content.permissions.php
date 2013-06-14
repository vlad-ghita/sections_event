<?php



	require_once(TOOLKIT.'/class.administrationpage.php');
	require_once(TOOLKIT.'/class.sectionmanager.php');

	require_once(EXTENSIONS.'/members/extension.driver.php');
	require_once(EXTENSIONS.'/members/lib/class.role.php');

	require_once(EXTENSIONS.'/sections_event/lib/class.se_perman.php');



	Class contentExtensionSections_EventPermissions extends AdministrationPage
	{



		/*------------------------------------------------------------------------------------------------*/
		/*  Index  */
		/*------------------------------------------------------------------------------------------------*/

		public function __viewIndex(){
			// Add in custom assets
			Administration::instance()->Page->addStylesheetToHead( URL.'/extensions/sections_event/assets/sections_event.permissions_index.css', 'screen', 111 );

			$this->setPageType( 'table' );
			$this->setTitle( __( '%1$s &ndash; %2$s', array(__( 'Symphony' ), __( 'Section permissions' )) ) );

			$this->appendSubheading( __( 'Section permissions' ) );


			// check if roles exist
			$roles = RoleManager::fetch();

			if( !is_array( $roles ) || empty($roles) ){
				return $this->Form->appendChild(
					$this->buildErrorMessage( __( 'No roles found. <a href="%s">Add a new one?</a>', array(
						extension_Members::baseURL().'roles/new/',
					) ) )
				);
			}


			// build table
			$aTableHead = array(
				array(__( 'Member role' ), 'col'),
			);

			$aTableBody = array();

			foreach($roles as $role){
				// Setup each cell
				$td1 = Widget::TableData( Widget::Anchor(
					$role->get( 'name' ), Administration::instance()->getCurrentPageURL().'edit/'.$role->get( 'id' ).'/', null, 'content'
				) );

				// Add cells to a row
				$aTableBody[] = Widget::TableRow( array($td1) );
			}

			$table = Widget::Table(
				Widget::TableHead( $aTableHead ),
				null,
				Widget::TableBody( $aTableBody )
			);

			$this->Form->appendChild( $table );
		}

		private function buildErrorMessage($msg){
			return new XMLElement('div', $msg, array('class' => 'permissions'));
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Edit  */
		/*------------------------------------------------------------------------------------------------*/

		public function __viewEdit(){
			if( !$role_id = $this->_context[1] ){
				redirect( Extension_Sections_Event::baseURL().'permissions/' );
			}

			if( !$existing = RoleManager::fetch( $role_id ) ){
				throw new SymphonyErrorPage(__( 'The role you requested to edit does not exist.' ), __( 'Role not found' ), 'error');
			}


			// check if sections exist
			$sections = SectionManager::fetch();

			if( !is_array( $sections ) || empty($sections) ){
				return $this->Form->appendChild(
					$this->buildErrorMessage( __( 'No sections found. <a href="%s">Create a new one?</a>', array(
						SYMPHONY_URL.'/blueprints/sections/new/'
					) ) )
				);
			}


			// Add in custom assets
			Administration::instance()->Page->addStylesheetToHead( URL.'/extensions/sections_event/assets/sections_event.permissions_single.css', 'screen', 111 );
			Administration::instance()->Page->addScriptToHead( URL.'/extensions/sections_event/assets/sections_event.permissions_single.js', 114 );


			// Append any Page Alerts from the form's
			if( isset($this->_context[2]) ){
				switch( $this->_context[2] ){
					case 'saved':
						$this->pageAlert(
							__(
								'Role permissions updated at %1$s. <a href="%2$s" accesskey="a">View all Roles</a>',
								array(
									$time = Widget::Time( '', __SYM_TIME_FORMAT__ )->generate(),
									Extension_Sections_Event::baseURL().'permissions/',
								)
							),
							Alert::SUCCESS );
						break;
				}
			}

			$this->setPageType( 'form' );

			$this->setTitle( __( 'Symphony &ndash; Section permissions &ndash; ' ).$existing->get( 'name' ) );
			$this->appendSubheading( $existing->get( 'name' ) );

			if( isset($_POST['permissions']) ){
				$permissions = $_POST['permissions'];
			}
			else{
				$permissions = array();

				$permissions['fields']   = SE_PerMan::getCrud( 'field' )->fetchAll( $role_id );
				$permissions['sections'] = SE_PerMan::getCrud( 'section' )->fetchAll( $role_id );
			}

			$this->insertBreadcrumbs( array(
				Widget::Anchor( __( 'Section permissions' ), Extension_Sections_Event::baseURL().'permissions/' ),
			) );

			$div = new XMLElement('div', null, array('class' => 'permissions clearfix'));
			$div->appendChild( $this->buildSectionPermissions( $role_id, $permissions ) );
			$div->appendChild( $this->buildFieldPermissions( $role_id, $permissions ) );
			$this->Form->appendChild( $div );

			$this->Form->appendChild( $this->buildActions() );
		}

		private function buildSectionPermissions($role_id, $permissions){
			$div = new XMLElement('div', null, array('class' => 'sections'));

			$actions = SE_PerMan::getControl('section')->getAllowedActions();

			$levels = array(
				SE_Permissions::LEVEL_NONE,
				SE_Permissions::LEVEL_OWN,
				SE_Permissions::LEVEL_ALL,
			);

			$level_map = SE_Permissions::$levelMap;


			// title
			$div->appendChild(
				new XMLElement('h3', __( 'Sections' ))
			);


			// table head
			$aTableHead   = array();
			$aTableHead[] = array(__( 'Name' ), 'col');
			foreach($actions as $action){
				$options = array();

				foreach($levels as $level){
					$options[] = array($level, false, $level_map[$level] );
				}

				$select = Widget::Select( "toggle-sections-$action", $options );

				$aTableHead[] = array(__( SE_Permissions::$actionMap[$action] ).'<br/>'.$select->generate(), 'col');
			}


			// table body
			$aTableBody = array();

			$sections = SectionManager::fetch();

			if( is_array( $sections ) && !empty($sections) ){
				foreach($sections as $section){
					/** @var $section Section */

					$sid = $section->get( 'id' );

					$tds = array();

					// name
					$first_col = $section->get( 'name' );
					$first_col .= "<input name=\"permissions[sections][$sid][role_id]\" type=\"hidden\" value=\"$role_id\"/>";
					$first_col .= "<input name=\"permissions[sections][$sid][section_id]\" type=\"hidden\" value=\"$sid\"/>";
					$tds[] = Widget::TableData( $first_col, 'name' );

					// actions
					foreach($actions as $action){
						$options = array();

						$default_level = SE_PerMan::getControl( 'section' )->getDefaultLevel( $action );

						foreach($levels as $level){
							$options[] = array(
								$level,
								isset($permissions['sections'][$sid][$action])
									? $permissions['sections'][$sid][$action] == $level
									: $default_level,
								$level_map[$level]
							);
						}

						$tds[] = Widget::TableData(
							Widget::Select( "permissions[sections][$sid][$action]", $options )->generate()
						);
					}

					$aTableBody[] = Widget::TableRow( $tds );
				}
			}

			$table = Widget::Table(
				Widget::TableHead( $aTableHead ),
				null,
				Widget::TableBody( $aTableBody )
			);

			$div->appendChild( $table );

			return $div;
		}

		private function buildFieldPermissions($role_id, $permissions){
			$div = new XMLElement('div', null, array('class' => 'fields'));

			$sections = SectionManager::fetch();


			// title
			$options = array();

			foreach($sections as $idx => $section){
				/** @var $section Section */
				$options[] = array(
					$section->get( 'id' ),
					$idx === 0,
					$section->get( 'name' )
				);
			}

			$div->appendChild( new XMLElement(
				'h3',
				Widget::Select( "section-selector", $options )->generate().__( ' fields' ),
				array('class' => 'section-selector')
			) );


			// section fields
			foreach($sections as $section){
				/** @var $section Section */
				$div->appendChild(
					$this->buildSectionFieldsTable( $role_id, $section->get( 'id' ), $permissions )
				);
			}

			return $div;
		}

		private function buildSectionFieldsTable($role_id, $sid, $permissions){
			$actions = SE_PerMan::getControl('field')->getAllowedActions();

			$levels = array(
				SE_Permissions::LEVEL_NONE,
				SE_Permissions::LEVEL_ALL,
			);

			$level_map = array(
				SE_Permissions::LEVEL_NONE => __( 'No' ),
				SE_Permissions::LEVEL_ALL  => __( 'Yes' ),
			);


			// table head
			$aTableHead   = array();
			$aTableHead[] = array(__( 'Label' ), 'col');
			$aTableHead[] = array(__( 'Handle' ), 'col', array('class' => 'handle'));
			foreach($actions as $action){
				$options = array();

				foreach($levels as $level){
					$options[] = array($level, false, $level_map[$level] );
				}

				$select = Widget::Select( "toggle-fields-$sid-$action", $options );

				$aTableHead[] = array(__( SE_Permissions::$actionMap[$action] ).'<br/>'.$select->generate(), 'col');
			}


			// table body
			$aTableBody = array();

			$fields = FieldManager::fetch( null, $sid );

			if( is_array( $fields ) && !empty($fields) ){
				foreach($fields as $field){
					/** @var $field Field */

					$tds = array();

					$fid = $field->get( 'id' );

					// name
					$first_col = $field->get( 'label' );
					$first_col .= "<input name=\"permissions[fields][$fid][role_id]\" type=\"hidden\" value=\"$role_id\"/>";
					$first_col .= "<input name=\"permissions[fields][$fid][field_id]\" type=\"hidden\" value=\"$fid\"/>";
					$tds[] = Widget::TableData( $first_col, 'name' );

					// handle
					$tds[] = Widget::TableData( $field->get( 'element_name' ), 'handle' );

					// actions
					foreach($actions as $action){
						$options = array();

						$default_level = SE_PerMan::getControl( 'field' )->getDefaultLevel( $action );

						foreach($levels as $level){
							$options[] = array(
								$level,
								isset($permissions['fields'][$fid][$action])
									? $permissions['fields'][$fid][$action] == $level
									: $default_level,
								$level_map[$level]
							);
						}

						$tds[] = Widget::TableData(
							Widget::Select( "permissions[fields][$fid][$action]", $options )->generate()
						);
					}

					$aTableBody[] = Widget::TableRow( $tds );
				}
			}

			$table = Widget::Table(
				Widget::TableHead( $aTableHead ),
				null,
				Widget::TableBody( $aTableBody ),
				null,
				null,
				array('data-section' => $sid)
			);

			return $table;
		}

		private function buildActions(){
			$div = new XMLElement('div');
			$div->setAttribute( 'class', 'actions' );
			$div->appendChild( Widget::Input( 'action[save]', __( 'Save Changes' ), 'submit', array('accesskey' => 's') ) );

			return $div;
		}

		public function __actionEdit(){
			if( array_key_exists( 'save', $_POST['action'] ) ){
				$permissions = $_POST['permissions'];

				// If we are editing, we need to make sure the current `$role_id` exists
				if( !$role_id = $this->_context[1] ){
					redirect( Extension_Sections_Event::baseURL().'permissions/' );
				}

				if( !$existing = RoleManager::fetch( $role_id ) ){
					throw new SymphonyErrorPage(__( 'The role you requested to edit does not exist.' ), __( 'Role not found' ), 'error');
				}

				if(
					SE_PerMan::getCrud( 'section' )->updateAll( $role_id, $permissions['sections'] )
					&& SE_PerMan::getCrud( 'field' )->updateAll( $role_id, $permissions['fields'] )
				){
					redirect( Extension_Sections_Event::baseURL().'permissions/edit/'.$role_id.'/saved/' );
				}
			}
		}
	}
