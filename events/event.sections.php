<?php



	require_once(EXTENSIONS.'/sections_event/lib/class.event.section.php');
	require_once(TOOLKIT.'/class.sectionmanager.php');



	/**
	 * Processes any amount of sections and their relations.
	 */
	Final Class EventSections extends SectionsSectionEvent
	{
		const ACTION_NONE = 0;

		const ACTION_CREATE = 1;

		const ACTION_EDIT = 2;

		const ACTION_DELETE = 3;

		private $actions = array('none', 'create', 'edit', 'delete');

		public $eParamFILTERS = array();

		/**
		 * Current section ID.
		 *
		 * @var int
		 */
		private static $source;

		/**
		 * Sections values at current processing stage
		 *
		 * @var array
		 */
		private $crt_sections = array();

		/**
		 * Keeps track of errors appeared during processing.
		 *
		 * @var array
		 */
		private $errors = array();

		public function __construct(array $env = null){
			$this->errors = array(
				'prepare' => false,
				'entry' => false,
				'delete' => false,
				'check' => false,
				'set' => false,
				'link' => false,
				'commit' => false
			);

			parent::__construct( $env );
		}



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

		public function priority(){
			return self::kLOW;
		}

		public static function getSource(){
			return self::$source;
		}

		public static function setSource($section_id){
			self::$source = $section_id;
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Execution  */
		/*------------------------------------------------------------------------------------------------*/

		/**
		 * Event entry point
		 *
		 * @return XMLElement
		 */
		public function load(){
			if( isset($_POST['action']['sections']) ){
				return $this->execute();
			}
		}

		/**
		 * Main method.
		 *
		 * @return XMLElement
		 */
		public function execute(){
			$sections_post = $_POST['sections'];

			// store the redirect
			$redirect = '';
			if( isset($sections_post['__redirect']) ){
				$redirect = $sections_post['__redirect'];
				unset($sections_post['__redirect']);
			}

			// allow exclusion of sections, even if form data exists
			$excluded = array();
			if( isset($sections_post['__excluded']) ){
				$excluded = $sections_post['__excluded'];
				unset($sections_post['__excluded']);
			}

			if( !is_array( $excluded ) ){
				$excluded = array($excluded);
			}

			foreach($excluded as $handle){
				if( array_key_exists( $handle, $sections_post ) ){
					unset($sections_post[$handle]);
				}
			}

			if( empty($sections_post) ) return null;

			$this->crt_sections = $sections_post;


			/* 1. Prepare data for processing. Fire PreSaveFilters delegate */
			$sections_prepare = $this->sectionsPrepare( $sections_post );

			if( $this->errorsExist() ){
				return $this->buildOutput( $sections_prepare );
			}

			$this->crt_sections = $sections_prepare;


			/* 2. Delete Entries */
			$sections_delete = $this->sectionsDelete( $sections_prepare );

			if( $this->errorsExist() ){
				return $this->buildOutput( $sections_delete );
			}

			$this->crt_sections = $sections_delete;


			/* 3. Next stages refer to Create & Edit. Check fields data */
			$sections_check = $this->sectionsCheck( $sections_delete );

			if( $this->errorsExist() ){
				return $this->buildOutput( $sections_check );
			}

			$this->crt_sections = $sections_check;


			/* 4. Set fields data. This creates Entries in db table */
			$sections_set = $this->sectionsSet( $sections_check );

			if( $this->errorsExist() ){
				$this->rollback( $sections_set );
				return $this->buildOutput( $sections_set );
			}

			$this->crt_sections = $sections_set;


			/* 5. Replace Variables found in fields data at this stage b/c IDs can be used to link entries */
			$sections_replace = $this->sectionsReplace( $sections_set );

			$this->crt_sections = $sections_replace;


			/* 6. Persist field data to db. Fires other delegates */
			$sections_commit = $this->sectionsCommit( $sections_replace );

			if( $this->errorsExist() ){
				$this->rollback( $sections_commit );
				return $this->buildOutput( $sections_commit );
			}

			$this->crt_sections = $sections_commit;


			// redirect
			if( !empty($redirect) ){
				redirect( $redirect );
			}

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
				$done = false;
				$filters = array();
				$entries = array();
				$result = new XMLElement($handle);

				// make sure section exists
				$section_id = SectionManager::fetchIDFromHandle( $handle );

				if( $handle == '__fields' ){
					$done = true;
					$entry_data = $this->sectionsPrepareEntry( 0, $data, null );
					$entries[0] = $entry_data;

					$output[$handle] = array(
						'id' => $section_id,
						'done' => $done,
						'filters' => $filters,
						'entries' => $entries,
						'result' => $result
					);

					continue;
				}

				if( is_null( $section_id ) && $handle != '__fields' ){
					$result->setAttribute( 'result', 'error' );
					$result->appendChild( new XMLElement('message', __( 'The Section, %s, could not be found.', array($handle) )) );
					$done = true;

					$output[$handle] = array(
						'id' => $section_id,
						'done' => $done,
						'filters' => $filters,
						'entries' => $entries,
						'result' => $result
					);

					continue;
				}

				// set filters if they exist
				if( isset($data['__filters']) ){
					$filters = $data['__filters'];
					unset($data['__filters']);
				}

				// find edit IDs
				$__edit = array();
				if( isset($data['__edit']) ){
					$__edit = $data['__edit'];
					unset($data['__edit']);
				}

				// find delete IDs
				$__delete = array();
				if( isset($data['__delete']) ){
					$__delete = $data['__delete'];
					unset($data['__delete']);
				}

				// set current context
				$this->setCurrentContext( $section_id, $filters );

				// handle the case where $data contains only one un-indexed entry
				reset( $data );
				if( !is_numeric( key( $data ) ) ){
					$data = array($data);

					if( !is_array( $__edit ) ){
						$__edit = array($__edit);
					}

					if( !is_array( $__delete ) ){
						$__delete = array($__delete);
					}
				}

				if( is_array( $data ) and !empty($data) ){
					foreach($data as $position => $fields){
						$id_edit = isset($__edit[$position]) ? $__edit[$position] : null;
						$id_delete = isset($__delete[$position]) ? $__delete[$position] : null;

						$to_edit = is_numeric( $id_edit );
						$to_delete = is_numeric( $id_delete );

						$action = self::ACTION_NONE;
						$entry_id = null;

						if( $to_delete ){
							$action = self::ACTION_DELETE;
							$entry_id = $id_delete;
						}
						else{
							if( $to_edit ){
								$action = self::ACTION_EDIT;
								$entry_id = $id_edit;
							}
							else{
								$action = self::ACTION_CREATE;
							}
						}

						$entries[$position] = $this->sectionsPrepareEntry( $position, $fields, $entry_id, $section_id, $action );
					}
				} // no fields submitted. Don't process section.
				else{
					$done = true;
				}

				$output[$handle] = array(
					'id' => $section_id,
					'done' => $done,
					'filters' => $filters,
					'entries' => $entries,
					'result' => $result
				);
			}

			return $output;
		}

		/**
		 * Create necessary data for an Entry.
		 *
		 * @param int   $position
		 * @param array $fields
		 * @param int   $entry_id
		 * @param int   $section_id
		 * @param int   $action
		 *
		 * @return array
		 */
		private function sectionsPrepareEntry($position, $fields, $entry_id, $section_id = null, $action = null){
			$action = $action === null ? self::ACTION_NONE : $action;

			$result = new XMLElement('entry', null, array('position' => $position, 'action' => $this->actions[$action]));
			$done = false;
			$e = null;

			switch( $action ){

				case self::ACTION_CREATE:
					$e =& EntryManager::create();
					$e->set( 'section_id', $section_id );
					break;

				case self::ACTION_EDIT:
				case self::ACTION_DELETE:
					$e =& EntryManager::fetch( $entry_id );
					$e = $e[0];

					if( !$e instanceof Entry ){
						$this->errors['entry'] = true;
						$done = true;

						$result->setAttribute( 'result', 'error' );
						$result->appendChild( new XMLElement('message', __( 'The Entry, %s, could not be found.', array($entry_id) )) );
					}
					break;

				default:
					$e = null;
					break;
			}

			// create the post data element. This will be replaced in the commit stage
			// with substituted values from frontend
			$post_values = new XMLElement('post-values');
			General::array_to_xml( $post_values, $fields, true );

			// fire PreSaveFilters here because it's earliest point possible
			if( $this->processPreSaveFilters( $result, $fields, $post_values, $entry_id ) === false ){
				if( $section_id !== null ){
					$this->errors['prepare'] = true;
					$done = true;
				}
			}

			return array(
				'action' => $action,
				'id' => $entry_id,
				'entry' => $e,
				'fields' => $fields,
				'post_values' => $post_values,
				'done' => $done,
				'result' => $result
			);
		}


		/**
		 * Takes the sections from sectionsPrepare() and deletes marked entries
		 *
		 * @param $input
		 *
		 * @return array
		 */
		private function sectionsDelete($input){
			$output = $input;
//			$to_delete = array();
//
//			foreach($output as $handle => &$section){
//
//				foreach($section['entries'] as &$entry){
//
//					if( $entry['action'] === self::ACTION_DELETE ){
//						$id = $entry['entry']->get( 'id' );
//
//						if( is_numeric( $id ) ){
//							$entry['done'] = true;
//							$to_delete[] = $id;
//						}
//					}
//				}
//			}
//
//			if( !empty($to_delete) ){
//				include_once(TOOLKIT.'/class.entrymanager.php');
//
//				try{
//					EntryManager::delete( $to_delete );
//				} catch( Exception $e ){
//					$this->errors['delete'] = true;
//				}
//			}

			return $output;
		}


		/**
		 * Takes the sections from sectionsDelete() and checks field data foreach Entry
		 *
		 * @param $input
		 *
		 * @return array
		 */
		private function sectionsCheck($input){
			$output = $input;

			foreach($output as $handle => &$section){

				// skip done sections
				if( $section['done'] === true ) continue;

				foreach($section['entries'] as &$entry){

					// skip done entries
					if( $entry['done'] === true ) continue;

					$errors = array();

					if( __ENTRY_FIELD_ERROR__ == $entry['entry']->checkPostData( $entry['fields'], $errors, ($entry['entry']->get( 'id' ) ? true : false) ) ){
						$this->errors['check'] = true;
						$entry['done'] = true;
						$entry['result'] = self::appendErrors( $entry['result'], $entry['fields'], $errors );
					}
				}
			}

			return $output;
		}


		/**
		 * Takes the sections from sectionsCheck() and sets field data foreach Entry
		 *
		 * @param $input
		 *
		 * @return array
		 */
		private function sectionsSet($input){
			$output = $input;

			foreach($output as $handle => &$section){

				// skip done sections
				if( $section['done'] === true ) continue;

				foreach($section['entries'] as &$entry){

					// skip done entries
					if( $entry['done'] === true ) continue;

					$errors = array();

					if( __ENTRY_OK__ != $entry['entry']->setDataFromPost( $entry['fields'], $errors, false, ($entry['entry']->get( 'id' ) ? true : false) ) ){
						$this->errors['set'] = true;
						$entry['done'] = true;
						$entry['result'] = self::appendErrors( $entry['result'], $entry['fields'], $errors );
					}
				}
			}

			return $output;
		}


		/**
		 * Takes the sections from sectionsSet() and replaces variables in field data
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
								$f = FieldManager::fetch( $f_id );
								$f_data = $f->processRawFieldData( $new_value, $s, $message, false, $entry['entry']->get( 'id' ) );
								$entry['entry']->setData( $f_id, $f_data );
							}
						}
					}

					// if values were replaced, update returned post-values
					if( $old_fields !== $entry['fields'] && !empty($entry['fields']) ){
						$post_values = new XMLElement('post-values');
						General::array_to_xml( $post_values, $entry['fields'], true );

						$entry['post_values'] = $post_values;
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

			$bit_section = array_shift( $result );
			$bit_position = isset($result[0]) && is_numeric( $result[0] ) ? array_shift( $result ) : 0;

			// check if requested entry was sent with the form
			if( !isset($this->crt_sections[$bit_section]) ) return $original;
			if( !isset($this->crt_sections[$bit_section]['entries'][$bit_position]) ) return $original;

			$entry = $this->crt_sections[$bit_section]['entries'][$bit_position];

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
				$new_value = $this->getValueFromMultidimArrayByKeys( $entry['fields'], $result );
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
				if( $section['done'] === true ) continue;

				// set current context
				$this->setCurrentContext( $section['id'], $section['filters'] );

				foreach($section['entries'] as &$entry){

					// try to commit to database
					if( $entry['entry']->commit() === false ){
						$entry['done'] = true;
						$this->errors['commit'] = true;
						$entry['result']->setAttribute( 'result', 'error' );
						$entry['result']->appendChild( new XMLElement('message', __( 'Unknown errors where encountered when saving.' )) );

						if( isset($entry['post_values']) && is_object( $entry['post_values'] ) ){
							$entry['result']->appendChild( $entry['post_values'] );
						}

						continue;
					}

					// Entry was created, add the good news to the return `$result`
					$entry['done'] = true;

					switch( $entry['action'] ){
						case self::ACTION_CREATE:
							$type = 'created';
							$message = __( 'Entry created successfully.' );
							break;

						case self::ACTION_EDIT:
							$type = 'edited';
							$message = __( 'Entry edited successfully.' );
							break;

						case self::ACTION_DELETE:
							$type = 'deleted';
							$message = __( 'Entry deleted successfully.' );
							break;

						default:
							$type = '';
							$message = '';
							break;
					}

					$entry['result']->setAttributeArray( array(
						'result' => 'success',
						'type' => $type,
						'id' => $entry['entry']->get( 'id' )
					) );

					$entry['result']->appendChild( new XMLElement('message', $message) );

					// PASSIVE FILTERS ONLY AT THIS STAGE. ENTRY HAS ALREADY BEEN CREATED.
					if( in_array( 'send-email', $this->eParamFILTERS ) ){
						$fields = $entry['fields'];
						$entry['result'] = $this->processSendMailFilter( $entry['result'], $_POST['send-email'], $fields, SectionManager::fetch( $this->getSource() ), $entry['entry'] );
					}

					$entry['result'] = $this->processPostSaveFilters( $entry['result'], $entry['fields'], $entry['entry'] );
					$entry['result'] = $this->processFinalSaveFilters( $entry['result'], $entry['fields'], $entry['entry'] );
				}
			}

			return $output;
		}



		/*------------------------------------------------------------------------------------------------*/
		/* Internal utilities */
		/*------------------------------------------------------------------------------------------------*/

		/**
		 * In a multidimensional array gets the deep value indicated by keys array.
		 *
		 * @param $array
		 * @param $keys
		 *
		 * @return null
		 */
		private function getValueFromMultidimArrayByKeys($array, $keys){
			$k = array_shift( $keys );

			if(
				// if $array is no longer an array but keys still exist
				!is_array($array) && !empty($keys)

				// or key is not found
				|| !isset($array[$k]) )
			{
				return null;
			}

			if( !empty($keys) ){
				return $this->getValueFromMultidimArrayByKeys( $array[$k], $keys );
			}

			return $array[$k];
		}

		/**
		 * Checks if errors appeared during execution.
		 *
		 * @return bool
		 */
		private function errorsExist(){
			foreach($this->errors as $error){
				if( $error ) return true;
			}

			return false;
		}

		/** Helper to easily set current context for a section */
		private function setCurrentContext($section_id, $filters){
			self::setSource( $section_id );
			$this->eParamFILTERS = $filters;
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

					if( $entry['action'] === self::ACTION_CREATE ){
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
					$entry['result']->appendChild( $entry['post_values'] );

					$section['result']->appendChild( $entry['result'] );
				}

				$result->appendChild( $section['result'] );
			}

			return $result;
		}

	}

