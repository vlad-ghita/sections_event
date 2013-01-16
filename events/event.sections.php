<?php



	require_once(EXTENSIONS.'/sections_event/lib/class.event.section.php');
	require_once(TOOLKIT.'/class.sectionmanager.php');



	/**
	 * Processes any amount of sections and their relations.
	 */
	Final Class EventSections extends SectionsSectionEvent
	{

		public $eParamFILTERS = array();

		private $link_fields = array('selectbox_link', 'selectbox_link_plus');

		/**
		 * Current section ID.
		 *
		 * @var int
		 */
		private static $source;

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

			/* 1. Prepare data for processing. Fire PreSaveFilters delegate */
			$sections_prepare = $this->sectionsPrepare( $sections_post );

			if( $this->errorsExist() ){
				return $this->buildOutput( $sections_prepare );
			}

			/* 2. Check data */
			$sections_check = $this->sectionsCheck( $sections_prepare );

			if( $this->errorsExist() ){
				return $this->buildOutput( $sections_check );
			}

			/* 3. Set data. This creates Entries in db table */
			$sections_set = $this->sectionsSet( $sections_check );

			if( $this->errorsExist() ){
				$this->rollback( $sections_set );
				return $this->buildOutput( $sections_set );
			}

			/* 4. Link Entries because we have their IDs */
			$sections_link = $this->sectionsLink( $sections_set );

			/* 5. Persist field data to db. Fires other delegates */
			$sections_commit = $this->sectionsCommit( $sections_link );

			if( $this->errorsExist() ){
				$this->rollback( $sections_commit );
				return $this->buildOutput( $sections_commit );
			}

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
					$entry_data = $this->sectionsPrepareEntry( 0, $data, null);
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
					$filters = isset($data['__filters']);
					unset($data['__filters']);
				}

				// find IDs
				$ids = null;
				if( isset($data['__id']) ){
					$ids = $data['__id'];
					unset($data['__id']);
				}

				// set current context
				$this->setCurrentContext( $section_id, $filters );

				// handle the case where $data contains only one un-indexed entry
				reset( $data );
				if( !is_numeric( key( $data ) ) ){
					$data = array($data);
				}

				if( is_array($data) ){
					foreach($data as $position => $fields){
						$entry_id = isset($ids[$position]) ? $ids[$position] : null;

						$entries[$position] = $this->sectionsPrepareEntry( $position, $fields, $entry_id, $section_id );
					}
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
		 *
		 * @return array
		 */
		private function sectionsPrepareEntry($position, $fields, $entry_id, $section_id = null){
			$result = new XMLElement('entry', null, array('position' => $position));
			$done = false;
			$is_new = !is_numeric( $entry_id );

			if( $is_new === true ){
				$e =& EntryManager::create();
				$e->set( 'section_id', $section_id );

			} else{
				$e =& EntryManager::fetch( $section_id );
				$e = $e[0];

				if( !$e instanceof Entry ){
					$this->errors['entry'] = true;
					$done = true;

					$result->setAttribute( 'result', 'error' );
					$result->appendChild( new XMLElement('message', __( 'The Entry, %s, could not be found.', array($entry_id) )) );
				}
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
				'new' => $is_new,
				'id' => $entry_id,
				'entry' => $e,
				'fields' => $fields,
				'post_values' => $post_values,
				'done' => $done,
				'result' => $result
			);
		}


		/**
		 * Takes the sections from sectionsPrepare() and checks field data foreach Entry
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
		 * Takes the sections from sectionsSet() and links the Entries
		 *
		 * @param $input
		 *
		 * @return array
		 */
		private function sectionsLink($input){
			$output = $input;

			foreach($output as $handle => $section){
				if( empty($section['id']) ) continue;

				$schema = FieldManager::fetchFieldsSchema( $section['id'] );

				if( is_array( $schema ) ){
					foreach($schema as $field){
						if( in_array( $field['type'], $this->link_fields ) ){
							$this->sectionsLinkReplaceIDs( $output, $field );
						}
					}
				}
			}

			return $output;
		}

		private function sectionsLinkReplaceIDs($input, $field){
			foreach($input as $handle => &$section){

				foreach($section['entries'] as &$entry){

					if( array_key_exists( $field['element_name'], $entry['fields'] ) ){
						$old_value = $entry['fields'][$field['element_name']];

						// it will check only plain values for replacements
						if( is_array( $old_value ) ) continue;

						// obtain new value
						$new_value = array();
						$variables = array_map( 'trim', explode( ',', $old_value ) );

						foreach($variables as $variable){
							$expr = '/(?:\[|\])+/';
							$result = preg_split( $expr, $variable, -1, PREG_SPLIT_NO_EMPTY );

							// section handle
							$bit_section = trim( $result[0], '$' );
							array_shift( $result );

							// entry position
							if( is_numeric( $result[0] ) ){
								$bit_position = $result[0];
								array_shift( $result );
							} else{
								$bit_position = 0;
							}

							if( empty($result) || $result[0] === 'system:id' ){
								if( !array_key_exists( $bit_section, $input ) ) continue;
								if( !array_key_exists( $bit_position, $input[$bit_section]['entries'] ) ) continue;

								$new_value[] = $input[$bit_section]['entries'][$bit_position]['entry']->get( 'id' );
							}
						}

						// set the relation for post_back_values
						$entry['fields'][$field['element_name']] = implode( ',', $new_value );

						// set the relation for DB
						$s = $message = null;

						/** @var $f Field */
						$f = FieldManager::fetch( $field['id'] );
						$f_data = $f->processRawFieldData( $new_value, $s, $message, false, $entry['entry']->get( 'id' ) );
						$entry['entry']->setData( $field['id'], $f_data );
					}
				}
			}
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

					$entry['result']->setAttributeArray( array(
						'result' => 'success',
						'type' => $entry['new'] === true ? 'created' : 'edited',
						'id' => $entry['entry']->get( 'id' )
					) );

					$entry['result']->appendChild( new XMLElement('message',
						$entry['new'] === true
							? __( 'Entry created successfully.' )
							: __( 'Entry edited successfully.' )
					) );

					// PASSIVE FILTERS ONLY AT THIS STAGE. ENTRY HAS ALREADY BEEN CREATED.
					if( in_array( 'send-email', $this->eParamFILTERS ) ){
						$fields = $entry['fields'];
						$entry['result'] = $this->processSendMailFilter( $entry['result'], $_POST['send-email'], $fields, SectionManager::fetch( $this->getSource() ), $entry['entry'] );
					}

					$entry['result'] = $this->processPostSaveFilters( $entry['result'], $entry['fields'], $entry['entry'] );
					$entry['result'] = $this->processFinalSaveFilters( $entry['result'], $entry['fields'], $entry['entry'] );

					// post values
					if( !empty($entry['fields']) ){
						$post_values = new XMLElement('post-values');
						General::array_to_xml( $post_values, $entry['fields'], true );

						$entry['post_values'] = $post_values;
					}
				}
			}

			return $output;
		}



		/*------------------------------------------------------------------------------------------------*/
		/* Internal utilities */
		/*------------------------------------------------------------------------------------------------*/

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
		 * Rollback whatever entries have been created. Edited ones are not touched.
		 *
		 * @param $sections
		 */
		private function rollback($sections){
			$to_delete = array();

			foreach($sections as $handle => $section){

				foreach($section['entries'] as $entry){

					if( $entry['new'] === true ){
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

