<?php



	require_once(TOOLKIT.'/class.sectionmanager.php');
	require_once(TOOLKIT.'/class.entrymanager.php');

	require_once(EXTENSIONS.'/sections_event/lib/class.se_perman.php');



	/**
	 * Processes any amount of sections and their relations.
	 */
	Final Class EventSections extends Event
	{

		/**
		 * Sections values at current processing stage.
		 *
		 * @var array
		 */
		private $sections = array();

		/**
		 * Knows if errors occurred during current processing stage.
		 *
		 * @var array
		 */
		private $error = false;



		/*------------------------------------------------------------------------------------------------*/
		/* Public utilities */
		/*------------------------------------------------------------------------------------------------*/

		public static function about(){
			return array(
				'name' => 'Sections'
			);
		}

		public static function allowEditorToParse(){
			return false;
		}

		public function load(){
			if( isset($_REQUEST['action']['sections']) ){
				return $this->execute();
			}
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Execution  */
		/*------------------------------------------------------------------------------------------------*/

		/**
		 * Main method.
		 *
		 * @return XMLElement
		 */
		private function execute(){
			$request = $this->getInputData( $_REQUEST );

			$sections_input = $request['sections'];

			// store the redirect
			$redirect = '';
			if( isset($sections_input['__redirect']) ){
				$redirect = $sections_input['__redirect'];
				unset($sections_input['__redirect']);
			}

			if( !is_array( $sections_input ) || empty($sections_input) ){
				return null;
			}

			$this->sections = $sections_input;


			/* 1. Prepare data for processing. Fire Sections_Event_PrepareFilter */
			$sections_prepare = $this->sectionsPrepare( $sections_input );
			if( $this->errorExists() ){
				return $this->buildOutput( $sections_prepare );
			}
			$this->sections = $sections_prepare;


			/* 2. Check permissions */
			$sections_permissions = $this->sectionsCheckPermissions( $sections_prepare );
			if( $this->errorExists() ){
				return $this->buildOutput( $sections_permissions );
			}
			$this->sections = $sections_permissions;


			/* 3. Delete Entries */
			$sections_delete = $this->sectionsDeleteEntries( $sections_permissions );
			if( $this->errorExists() ){
				return $this->buildOutput( $sections_delete );
			}
			$this->sections = $sections_delete;


			/* 4. Create & Edit. Check fields data */
			$sections_check = $this->sectionsCheckFields( $sections_delete );
			if( $this->errorExists() ){
				return $this->buildOutput( $sections_check );
			}
			$this->sections = $sections_check;


			/* 5. Create & Edit. Set fields data. This creates Entries in db table */
			$sections_set = $this->sectionsSetFields( $sections_check );
			if( $this->errorExists() ){
				$this->rollback( $sections_set );
				return $this->buildOutput( $sections_set );
			}
			$this->sections = $sections_set;


			/* 6. Replace Variables found in fields data at this stage b/c IDs can be used to link entries */
			$sections_replace = $this->sectionsReplace( $sections_set );
			$this->sections   = $sections_replace;


			/* 7. Create & Edit. Persist field data to db. Fire Sections_Event_PostSaveFilter */
			$sections_commit = $this->sectionsCommit( $sections_replace );
			if( $this->errorExists() ){
				$this->rollback( $sections_commit );
				return $this->buildOutput( $sections_commit );
			}
			$this->sections = $sections_commit;


			// redirect
			if( !empty($redirect) ){
				$processed_redirect = $this->sectionsReplaceGetNewValue( $redirect );
				redirect( $processed_redirect );
			}


			// dump entry ids in param pool for reference
			$this->dumpEntriesIDsInParamPool( $sections_commit );


			return $this->buildOutput( $sections_commit );
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Execution stages  */
		/*------------------------------------------------------------------------------------------------*/

		/**
		 * Takes the $_POST data and prepares sections to process.
		 * Sections that do not exist are marked as done.
		 *
		 * @param array $input
		 *
		 * @return array
		 */
		private function sectionsPrepare($input){
			$output = array();

			foreach($input as $handle => $data){
				$entries = array();
				$result  = new XMLElement($handle);

				// make sure section exists
				$section_id = SectionManager::fetchIDFromHandle( $handle );

				if( $section_id === null ){
					$result->setAttribute( 'result', 'error' );
					$result->appendChild( new XMLElement('message', __( 'The Section, %s, could not be found.', array($handle) )) );
					$done = true;

					$output[$handle] = array(
						'id'      => $section_id,
						'done'    => $done,
						'entries' => $entries,
						'result'  => $result
					);

					continue;
				}

				// get section level filters
				$section_filters = array();
				if( isset($data['__filters']) ){
					$section_filters = is_array( $data['__filters'] ) ? $data['__filters'] : array($data['__filters']);
					unset($data['__filters']);
				}

				// prepare entries that must be created or edited
				if( !empty($data) && is_array( $data ) ){

					// handle the case where $data contains only one un-indexed entry
					reset( $data );
					if( !is_numeric( key( $data ) ) ){
						$data = array($data);
					}

					foreach($data as $position => $fields){
						$entries[$position] = $this->sectionsPrepareEntry( $handle, $section_filters, $position, $fields );
					}
				}

				$output[$handle] = array(
					'id'      => $section_id,
					'done'    => empty($entries),
					'entries' => $entries,
					'result'  => $result
				);
			}

			return $output;
		}

		/**
		 * Create necessary data for an Entry.
		 *
		 * @param string $section_handle
		 * @param array  $section_filters
		 * @param int    $position
		 * @param array  $original_fields
		 *
		 * @return array
		 */
		private function sectionsPrepareEntry($section_handle, array $section_filters, $position, array $original_fields){
			$action   = null;
			$entry_id = null;
			$filters  = array();

			// determine filters
			if( isset($original_fields['__filters']) ){
				$filters = is_array( $original_fields['__filters'] ) ? $original_fields['__filters'] : array($original_fields['__filters']);
				unset($original_fields['__filters']);
			}

			$filters = array_replace_recursive( $section_filters, $filters );

			// determine entry_id
			if( isset($original_fields['__system-id']) ){
				$entry_id = $original_fields['__system-id'];
				if( is_array( $entry_id ) ){
					$entry_id = current( $entry_id );
				}
				unset($original_fields['__system-id']);
			}

			// // determine action
			if( isset($original_fields['__action']) ){
				$action = $original_fields['__action'];
				unset($original_fields['__action']);
			}
			elseif( is_numeric( $entry_id ) ){
				$action = SE_Permissions::ACTION_EDIT;
			}
			else{
				$action = SE_Permissions::ACTION_CREATE;
			}

			$fields = $original_fields;

			$res_entry = new XMLElement('entry', null, array('action' => $action));
			$done      = false;
			$entry     = null;

			// validate $action & get the Entry object
			switch( $action ){

				case SE_Permissions::ACTION_CREATE:
					$entry = EntryManager::create();
					$entry->set( 'section_id', SectionManager::fetchIDFromHandle( $section_handle ) );
					break;

				case SE_Permissions::ACTION_EDIT:
				case SE_Permissions::ACTION_DELETE:
					$entry = EntryManager::fetch( $entry_id );
					$entry = $entry[0];

					if( !$entry instanceof Entry ){
						$this->error = true;
						$done        = true;
						$this->resultEntry( $res_entry, 'error', __( 'The Entry `%d` could not be found.', array($entry_id) ) );
					}
					break;

				default:
					$done = true;
					$this->resultEntry( $res_entry, 'error', __( 'Requested action `%s` is not supported.', array($action) ) );
					break;
			}

			// fire PreSaveFilter
			$res_filters = new XMLElement('filters');

			if( !$done ){
				if( !$this->filtersProcessPrepare( $res_filters, $section_handle, $entry, $fields, $original_fields, $filters, $action ) ){
					$this->error = true;
					$this->resultEntry( $res_entry, 'error' );
				}
			}

			return array(
				'action'      => $action,
				'id'          => $entry_id,
				'entry'       => $entry,
				'orig_fields' => $original_fields,
				'fields'      => $fields,
				'filters'     => $filters,
				'done'        => $done,
				'result'      => new XMLElement('entry', null, array('position' => $position)),
				'res_entry'   => $res_entry,
				'res_fields'  => new XMLElement('fields'),
				'res_filters' => $res_filters,
			);
		}


		/**
		 * Checks Entries for permissions.
		 *
		 * @param $input
		 *
		 * @return array
		 */
		private function sectionsCheckPermissions($input){
			$output = $input;

			foreach($output as $handle => &$section){

				$schema = FieldManager::fetchFieldsSchema( $section['id'] );

				foreach($section['entries'] as &$entry){

					$valid = true;

					$has_perm_section = SE_PerMan::getControl( 'section' )->check( $section['id'], $entry['action'], $entry['id'] );

					if( !$has_perm_section ){
						$this->error   = true;
						$entry['done'] = true;
						$valid         = false;
						$entry['res_filters']->appendChild(
							$this->filtersBuildElement( 'permissions-section', false, __( 'You do not have enough permissions to perform this operation.' ) )
						);
					}

					if( !is_array( $schema ) || empty($schema) ){
						continue;
					}

					// check fields only on EDIT and VIEW b/c there's no practical reason to check other values
					if(
						$entry['action'] === SE_Permissions::ACTION_EDIT
						|| $entry['action'] === SE_Permissions::ACTION_VIEW
					){
						foreach($schema as $field_info){
							$field_name = $field_info['element_name'];

							// make sure this field has data
							if( !isset($entry['fields'][$field_name]) ){
								continue;
							}

							$has_perm_field = SE_PerMan::getControl( 'field' )->check( $field_info['id'], $entry['action'] );

							if( !$has_perm_field ){
								$this->error   = true;
								$entry['done'] = true;
								$valid         = false;
								$entry['res_filters']->appendChild(
									$this->filtersBuildElement(
										"permissions-field-$field_name",
										false,
										__( 'You do not have enough permissions to perform this operation.' )
									)
								);
							}
						}
					}

					if( !$valid ){
						$this->resultEntry( $entry['res_entry'], 'error' );
					}

				}
			}

			return $output;
		}


		/**
		 * Deletes marked entries
		 *
		 * @param $input
		 *
		 * @return array
		 */
		private function sectionsDeleteEntries($input){
			$output = $input;

			include_once(TOOLKIT.'/class.entrymanager.php');

			foreach($output as $handle => &$section){

				foreach($section['entries'] as &$entry){

					if( $entry['action'] === SE_Permissions::ACTION_DELETE ){
						$id = $entry['entry']->get( 'id' );

						if( is_numeric( $id ) ){
							try{
								EntryManager::delete( $id );
								$entry['done'] = true;
							} catch( Exception $e ){
								$this->error = true;
								$this->resultEntry( $entry['res_entry'], 'error' );
							}
						}
					}
				}
			}

			return $output;
		}


		/**
		 * Checks field data foreach Entry
		 *
		 * @param $input
		 *
		 * @return array
		 */
		private function sectionsCheckFields($input){
			$output = $input;

			foreach($output as $handle => &$section){

				// skip done sections
				if( $section['done'] === true ){
					continue;
				}

				$schema = FieldManager::fetchFieldsSchema( $section['id'] );

				if( !is_array( $schema ) || empty($schema) ){
					continue;
				}

				foreach($section['entries'] as &$entry){

					// skip done entries
					if( $entry['done'] === true ){
						continue;
					}

					$errors                = array();
					$entry_status          = __ENTRY_OK__;
					$ignore_missing_fields = $entry['action'] === SE_Permissions::ACTION_EDIT;

					foreach($schema as $field_info){
						$field_name = $field_info['element_name'];
						$has_data   = isset($entry['fields'][$field_name]);

						if( $ignore_missing_fields && !$has_data ){
							continue;
						}

						$field_id = $field_info['id'];
						$message  = null;

						/** @var $field Field */
						$field = FieldManager::fetch( $field_id );

						$field_data = $has_data ? $entry['fields'][$field_name] : null;

						$field_status = $field->checkPostFieldData( $field_data, $message, $entry['entry']->get( 'id' ) );

						if( $field_status != Field::__OK__ ){
							$entry_status                 = __ENTRY_FIELD_ERROR__;
							$errors[$field_id]['code']    = $field_status;
							$errors[$field_id]['message'] = $message;
						}
					}

					if( $entry_status !== __ENTRY_OK__ ){
						$this->error   = true;
						$entry['done'] = true;
						$this->resultEntry( $entry['res_entry'], 'error' );
						$this->resultFields( $entry['res_fields'], $entry['fields'], $errors );
					}
				}
			}

			return $output;
		}


		/**
		 * Sets field data foreach Entry
		 *
		 * @param $input
		 *
		 * @return array
		 */
		private function sectionsSetFields($input){
			$output = $input;

			foreach($output as $handle => &$section){

				// skip done sections
				if( $section['done'] === true ) continue;

				foreach($section['entries'] as &$entry){

					// skip done entries
					if( $entry['done'] === true ) continue;

					$errors = array();

					$ignore_missing_fields = $entry['action'] === SE_Permissions::ACTION_EDIT;

					if( __ENTRY_OK__ != $entry['entry']->setDataFromPost( $entry['fields'], $errors, false, $ignore_missing_fields ) ){
						$this->error   = true;
						$entry['done'] = true;
						$this->resultFields( $entry['res_fields'], $entry['fields'], $errors );
						continue;
					}

					/**
					 * After data is set from fields.
					 *
					 * @delegate Sections_Event_FieldsPostSet
					 *
					 * @param string $context
					 * '*'
					 * @param int    $section_id
					 * @param Entry  $entry
					 * @param array  $fields
					 */
					Symphony::ExtensionManager()->notifyMembers( 'Sections_Event_FieldsPostSet', '*', array(
						'section_id' => $section['id'],
						'entry'      => $entry['entry'],
						'fields'     => $entry['fields']
					) );
				}
			}

			return $output;
		}


		/**
		 * Replaces variables in field data
		 *
		 * @param $input
		 *
		 * @return array
		 */
		private function sectionsReplace($input){
			$output = $input;

			foreach($output as $handle => &$section){

				foreach($section['entries'] as &$entry){

					$old_fields = $entry['fields'];

					foreach($entry['fields'] as $field => $value){
						$new_value = $this->sectionsReplaceGetNewValue( $value );

						if( $new_value !== $value ){

							// set the relation for post_back_values
							$entry['fields'][$field] = $new_value;

							// set the relation for DB if Entry exists
							if( $entry['entry'] instanceof Entry ){
								$s = $message = null;

								$f_id = FieldManager::fetchFieldIDFromElementName( $field, $section['id'] );

								/** @var $f Field */
								$f      = FieldManager::fetch( $f_id );
								$f_data = $f->processRawFieldData( $new_value, $s, $message, false, $entry['entry']->get( 'id' ) );
								$entry['entry']->setData( $f_id, $f_data );
							}
						}
					}
				}
			}

			return $output;
		}

		/**
		 * Processes a field's data for replacing variables within it's value.
		 *
		 * @param string|array $field_data - field data
		 *
		 * @return array|mixed
		 */
		private function sectionsReplaceGetNewValue($field_data){

			// array. treat every value
			if( is_array( $field_data ) ){
				$new_value = array();

				foreach($field_data as $k => $v){
					$new_value[$k] = $this->sectionsReplaceGetNewValue( $v );
				}
			}

			// plain value. find variables and replace them
			else{
				// this will match all variables like: %...%
				$regex = '/\\\\.|(%([^%\\\\]|\\\\.)+%)/';

				$new_value = preg_replace_callback( $regex, array($this, 'sectionReplaceProcessValue'), $field_data );
			}

			return $new_value;
		}

		/**
		 * Callback method to process a plain value for replaceable variables
		 *
		 * @param $match
		 *
		 * @return string|null
		 */
		private function sectionReplaceProcessValue($match){
			$original = $match[1];
			$variable = trim( $original, '%' );

			// explode the parts from a variable
			$result = preg_split( '/(?:\[|\])+/', $variable, -1, PREG_SPLIT_NO_EMPTY );

			$bit_section  = array_shift( $result );
			$bit_position = isset($result[0]) && is_numeric( $result[0] ) ? array_shift( $result ) : 0;

			// check if requested entry was sent with the form
			if( !isset($this->sections[$bit_section]) ) return $original;
			if( !isset($this->sections[$bit_section]['entries'][$bit_position]) ) return $original;

			$entry = $this->sections[$bit_section]['entries'][$bit_position];

			$new_value = null;

			// link the system ID only if Entry exists
			if( empty($result) || $result[0] === 'system:id' ){
				if( $entry['entry'] instanceof Entry ){
					$new_value = $entry['entry']->get( 'id' );
				}
			}

			// link other fields
			else{
				// Go go go deep in entry's fields array and get the value from keys
				$new_value = $this->getArrayValueByDepthKeys( $entry['fields'], $result );
			}

			if( $new_value == null ) return $original;

			return $new_value;
		}



		/**
		 * Takes the sections from sectionsLink() and commits field data foreach Entry
		 *
		 * @param $input
		 *
		 * @return array
		 */
		private function sectionsCommit($input){
			$output = $input;

			foreach($output as $handle => &$section){

				// skip done sections
				if( $section['done'] === true ){
					continue;
				}

				foreach($section['entries'] as &$entry){

					// Entry is done at this stage
					$entry['done'] = true;

					// try to commit to database
					if( $entry['entry']->commit() === false ){
						$entry['done'] = true;
						$this->error   = true;
						$this->resultEntry( $entry['res_entry'], 'error', __( 'Unknown errors where encountered when saving.' ) );
						continue;
					}

					switch( $entry['action'] ){
						case SE_Permissions::ACTION_CREATE:
							$message = __( 'Entry created successfully.' );
							break;

						case SE_Permissions::ACTION_EDIT:
							$message = __( 'Entry edited successfully.' );
							break;

						case SE_Permissions::ACTION_DELETE:
							$message = __( 'Entry deleted successfully.' );
							break;

						default:
							$message = __( 'This should not be reached.' );
							break;
					}

					$this->resultEntry( $entry['res_entry'], 'success', $message );

					$entry['res_entry']->setAttribute( 'id', $entry['entry']->get( 'id' ) );

					$this->filtersProcessCommit( $entry['res_filters'], $entry['entry'], $entry['fields'], $entry['filters'], $entry['action'] );
				}
			}

			return $output;
		}



		/*------------------------------------------------------------------------------------------------*/
		/* Internal utilities */
		/*------------------------------------------------------------------------------------------------*/

		private function resultEntry(XMLElement $result, $status = 'success', $msg = null){
			if( $msg === null ){
				$msg = __( 'Entry encountered errors when saving.' );
			}

			if( $status !== 'success' ){
				$status = 'error';
			}

			$result->setAttribute( 'result', $status );

			$result->appendChild( new XMLElement('message', $msg) );
		}

		private function resultFields(XMLElement $result, array $fields, array $errors = array()){
			foreach($errors as $field_id => $data){
				/** @var $field Field */
				$field = FieldManager::fetch( $field_id );

				$elem_name = $field->get( 'element_name' );

				$result->appendChild( new XMLElement($elem_name, null, array(
					'label'   => General::sanitize( $field->get( 'label' ) ),
					'type'    => ($fields[$elem_name] == '') ? 'missing' : 'invalid',
					'message' => General::sanitize( $data['message'] ),
					'code'    => $data['code']
				)) );
			}
		}

		/**
		 * In a multidimensional array gets the value deep inside indicated by keys array.
		 *
		 * @param $array
		 * @param $keys
		 *
		 * @return null
		 */
		private function getArrayValueByDepthKeys($array, $keys){
			$k = array_shift( $keys );

			if(
				// if $array is no longer an array but keys still exist
				!is_array( $array ) && !empty($keys)

				// or key is not found
				|| !isset($array[$k])
			){
				return null;
			}

			if( !empty($keys) ){
				return $this->getArrayValueByDepthKeys( $array[$k], $keys );
			}

			return $array[$k];
		}

		/**
		 * Checks if errors appeared during execution.
		 *
		 * @return bool
		 */
		private function errorExists(){
			return $this->error;
		}

		/**
		 * Rollback whatever entries have been created
		 *
		 * @param $sections
		 */
		private function rollback($sections){
			$to_delete = array();

			foreach($sections as $handle => $section){

				foreach($section['entries'] as $entry){

					if( $entry['action'] === SE_Permissions::ACTION_CREATE ){
						$id = $entry['entry']->get( 'id' );

						if( is_numeric( $id ) ){
							$to_delete[] = $id;
						}
					}
				}
			}

			if( !empty($to_delete) ){
				include_once(TOOLKIT.'/class.entrymanager.php');

				EntryManager::delete( $to_delete );
			}
		}

		/**
		 * Dumps sections to XMLElement.
		 *
		 * @param $sections
		 *
		 * @return XMLElement
		 */
		private function buildOutput($sections){
			$result = new XMLElement('sections');

			foreach($sections as $handle => $section){

				foreach($section['entries'] as $entry){
					$post_values = new XMLElement('post-values');
					General::array_to_xml( $post_values, $entry['orig_fields'], true );

					$rep_post_values = new XMLElement('rep-post-values');
					General::array_to_xml( $rep_post_values, $entry['fields'], true );

					$entry['result']->appendChild( $post_values );
					$entry['result']->appendChild( $rep_post_values );
					$entry['result']->appendChild( $entry['res_entry'] );
					$entry['result']->appendChild( $entry['res_fields'] );
					$entry['result']->appendChild( $entry['res_filters'] );

					$section['result']->appendChild( $entry['result'] );
				}

				$result->appendChild( $section['result'] );
			}

			return $result;
		}

		/**
		 * Similar to @see General::getPostData(), but targets $_REQUEST instead of $_POST.
		 *
		 * @param $src - $_POST | $_GET | $_REQUEST - defaults to $_REQUEST
		 *
		 * @return array - merged input data
		 */
		private function getInputData($src = null){
			if( !function_exists( 'merge_file_post_data' ) ){
				function merge_file_post_data($type, array $file, &$src){
					foreach($file as $key => $value){
						if( !isset($src[$key]) ) $src[$key] = array();
						if( is_array( $value ) ){
							merge_file_post_data( $type, $value, $src[$key] );
						}
						else $src[$key][$type] = $value;
					}
				}
			}

			$files = array(
				'name'     => array(),
				'type'     => array(),
				'tmp_name' => array(),
				'error'    => array(),
				'size'     => array()
			);

			if( $src === null ){
				$src = $_REQUEST;
			}

			if( is_array( $_FILES ) && !empty($_FILES) ){
				foreach($_FILES as $key_a => $data_a){
					if( !is_array( $data_a ) ) continue;
					foreach($data_a as $key_b => $data_b){
						$files[$key_b][$key_a] = $data_b;
					}
				}
			}

			foreach($files as $type => $data){
				merge_file_post_data( $type, $data, $src );
			}

			return $src;
		}

		/**
		 * Dumps entries in param pool.
		 *
		 * @param $sections
		 */
		private function dumpEntriesIDsInParamPool($sections){
			foreach($sections as $handle => $section){

				foreach($section['entries'] as $entry){

					if( $entry['entry'] instanceof Entry ){
						Frontend::Page()->_param["event-sections-$handle"][] = $entry['entry']->get( 'id' );
					}
				}
			}
		}



		/*------------------------------------------------------------------------------------------------*/
		/* Filter utilities */
		/*------------------------------------------------------------------------------------------------*/

		/**
		 * Processes all extensions attached to the `SE_PrepareFilter` delegate
		 *
		 * @param XMLElement $result
		 * @param string     $section_handle
		 * @param Entry      $entry
		 * @param array      $fields
		 * @param array      $original_fields
		 * @param array      $filters
		 * @param string     $action
		 *
		 * @return boolean
		 */
		private function filtersProcessPrepare(XMLElement $result, $section_handle, Entry $entry, array &$fields, array $original_fields, array $filters, $action){
			$can_proceed    = true;
			$filter_results = array();

			/**
			 * On preparing entry data. This delegate will force the Event
			 * to terminate if it populates the `$filter_results` array.
			 *
			 * @delegate SE_PrepareFilter
			 *
			 * @param Entry  $entry
			 * @param array  $fields          - the fields including $_FILES
			 * @param array  $original_fields - the fields without $_FILES
			 * @param array  $filters
			 * @param string $action
			 * @param array  $filter_results
			 *                                An associative array of arrays which contain 4 values:
			 *   - the name of the filter (string)
			 *   - the status (boolean),
			 *   - the message (string)
			 *   - an associative array of additional attributes to add to the filter element.
			 */
			Symphony::ExtensionManager()->notifyMembers( 'SE_PrepareFilter', '*', array(
				'section_handle'  => $section_handle,
				'entry'           => $entry,
				'fields'          => &$fields,
				'original_fields' => $original_fields,
				'filters'         => $filters,
				'action'          => $action,
				'filter_results'  => &$filter_results,
			) );

			// Fail entry should any `$filter_results` be returned
			if( is_array( $filter_results ) && !empty($filter_results) ){
				foreach($filter_results as $fr){
					list($name, $status, $message, $attributes) = $fr;

					$result->appendChild(
						$this->filtersBuildElement( $name, $status, $message, $attributes )
					);

					if( $status === false ){
						$can_proceed = false;
					}
				}
			}

			return $can_proceed;
		}

		/**
		 * Processes all extensions attached to the `SE_CommitFilter` delegate
		 *
		 * @param XMLElement $result
		 * @param Entry      $entry
		 * @param array      $fields
		 * @param array      $filters
		 * @param string     $action
		 */
		private function filtersProcessCommit(XMLElement $result, Entry $entry, array $fields, array $filters, $action){
			$filter_results = array();

			/**
			 * After saving an entry.
			 *
			 * @delegate SE_CommitFilter
			 *
			 * @param Entry  $entry
			 * @param array  $fields
			 * @param array  $filters
			 * @param string $action
			 * @param array  $filter_results
			 *  An associative array of arrays which contain 4 values:
			 *   - the name of the filter (string)
			 *   - the status (boolean),
			 *   - the message (string)
			 *   - an associative array of additional attributes to add to the filter element.
			 */
			Symphony::ExtensionManager()->notifyMembers( 'SE_CommitFilter', '*', array(
				'entry'          => $entry,
				'fields'         => $fields,
				'filters'        => $filters,
				'action'         => $action,
				'filter_results' => &$filter_results,
			) );

			if( is_array( $filter_results ) && !empty($filter_results) ){
				foreach($filter_results as $fr){
					list($name, $status, $message, $attributes) = $fr;

					$result->appendChild(
						$this->filtersBuildElement( $name, $status, $message, $attributes )
					);
				}
			}
		}

		/**
		 * This method will construct XML that represents the result of
		 * an Event filter.
		 *
		 * @param string            $name
		 *  The name of the filter
		 * @param string            $status
		 * @param XMLElement|string $message
		 *  Optionally, an XMLElement or string to be appended to this
		 *  `<filter>` element. XMLElement allows for more complex return
		 *  types.
		 * @param array             $attributes
		 *  An associative array of additional attributes to add to this
		 *  `<filter>` element
		 *
		 * @return XMLElement
		 */
		private function filtersBuildElement($name, $status, $message = null, array $attributes = null){
			$filter = new XMLElement('filter', (!$message || is_object( $message ) ? null : $message));

			if( $message instanceof XMLElement ){
				$filter->appendChild( $message );
			}

			$attrs = array('name' => $name, 'status' => $status ? 'passed' : 'failed');

			if( !is_array( $attributes ) ){
				$attributes = array();
			}

			$filter->setAttributeArray( array_replace_recursive( $attributes, $attrs ) );

			return $filter;
		}

	}

