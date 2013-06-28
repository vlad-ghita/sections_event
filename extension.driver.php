<?php



	require_once(EXTENSIONS.'/sections_event/lib/class.se_perman.php');



	Final Class Extension_Sections_Event extends Extension
	{

		private $valid_dependencies = null;



		public function __construct(){
			$this->validateDependencies();
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Installation  */
		/*------------------------------------------------------------------------------------------------*/

		public function install(){
			$this->dropPermissionTables();
			return $this->createPermissionTables();
		}

		public function uninstall(){
			return $this->dropPermissionTables();
		}

		public function update($previous_version){
			if( version_compare( $previous_version, '2.0', '<' ) ){
				$this->dropPermissionTables();
				$this->createPermissionTables();
			}
		}

		private function createPermissionTables(){
			return Symphony::Database()->import( "
				CREATE TABLE `tbl_se_section_permissions` (
				  `id` INT unsigned NOT NULL AUTO_INCREMENT,
				  `role_id` INT unsigned NOT NULL,
				  `section_id` INT unsigned NOT NULL,
				  `view` TINYINT unsigned NOT NULL DEFAULT '0',
				  `create` TINYINT unsigned NOT NULL DEFAULT '0',
				  `edit` TINYINT unsigned NOT NULL DEFAULT '0',
				  `delete` TINYINT unsigned NOT NULL DEFAULT '0',
				  PRIMARY KEY (`id`)
				) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

				CREATE TABLE `tbl_se_field_permissions` (
				  `id` INT unsigned NOT NULL AUTO_INCREMENT,
				  `role_id` INT unsigned NOT NULL,
				  `field_id` INT unsigned NOT NULL,
				  `view` TINYINT unsigned NOT NULL DEFAULT '0',
				  `edit` TINYINT unsigned NOT NULL DEFAULT '0',
				  PRIMARY KEY (`id`)
				) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
			" );
		}

		private function dropPermissionTables(){
			return Symphony::Database()->import( "
				DROP TABLE IF EXISTS `tbl_se_section_permissions`;
				DROP TABLE IF EXISTS `tbl_se_field_permissions`;
			" );
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Setters & Getters  */
		/*------------------------------------------------------------------------------------------------*/

		private function setValidDependencies($status){
			$this->valid_dependencies = $status;
		}

		private function getValidDependencies(){
			return $this->valid_dependencies;
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Navigation  */
		/*------------------------------------------------------------------------------------------------*/

		public function fetchNavigation(){
			if( !$this->getValidDependencies() ){
				return null;
			}

			return array(
				array(
					'location' => __( 'System' ),
					'name'     => __( 'Section permissions' ),
					'link'     => '/permissions/'
				)
			);
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Delegates  */
		/*------------------------------------------------------------------------------------------------*/


		public function getSubscribedDelegates(){
			return array(
				array(
					'page'     => '/backend/',
					'delegate' => 'InitaliseAdminPageHead',
					'callback' => 'dInitialiseAdminPageHead'
				),

				array(
					'page'     => '*',
					'delegate' => 'SE_PrepareFilter',
					'callback' => 'dSE_PrepareFilter'
				),

				array(
					'page'     => '*',
					'delegate' => 'SE_CommitFilter',
					'callback' => 'dSE_CommitFilter'
				),

				array(
					'page'     => '/frontend/',
					'delegate' => 'ManageEXSLFunctions',
					'callback' => 'dManageEXSLFunctions'
				),

			);
		}

		public function dInitialiseAdminPageHead(){
			if( !$this->getValidDependencies() ){
				$message = __( 'Sections Event depends on Members extension. Make sure it is installed.' );
				Administration::instance()->Page->pageAlert( $message, Alert::NOTICE );
			}
		}

		public function dSE_PrepareFilter($context){
			// simulate XSS filter
			$this->triggerXSS( $context );
		}

		public function dSE_CommitFilter($context){
			// simulate ETM
			$this->triggerETM( $context );

			// simulate Reflection
			$this->triggerReflection( $context );

			// simulate Multilingual Entry URL
			$this->triggerMultilingualEntryUrl( $context );
		}

		public function dManageEXSLFunctions($context){
			$context['manager']->addFunction(
				'SE_PerMan::control_check',
				'http://xanderadvertising.com/functions',
				'controlCheck'
			);

			$context['manager']->addFunction(
				'SE_PerMan::control_getLevel',
				'http://xanderadvertising.com/functions',
				'controlGetLevel'
			);
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Utilities  */
		/*------------------------------------------------------------------------------------------------*/

		public static function baseURL(){
			return SYMPHONY_URL.'/extension/sections_event/';
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Internal  */
		/*------------------------------------------------------------------------------------------------*/

		private function triggerETM($context){
			// make sure extension is enabled
			$etm_ext_status = ExtensionManager::fetchStatus( array('handle' => 'email_template_manager') );
			if( $etm_ext_status[0] !== EXTENSION_ENABLED ){
				return;
			}

			/** @var $etm Extension_Email_Template_Manager */
			$etm = ExtensionManager::getInstance( 'email_template_manager' );

			require_once(EXTENSIONS.'/sections_event/lib/class.etmsectionsevent.php');

			// simulate ETM context
			$event                = new ETMSectionsEvent();
			$event->eParamFILTERS = $context['filters'];

			$errors = array();

			$etm_context = array(
				'entry'  => $context['entry'],
				'fields' => $context['fields'],
				'event'  => $event,
				'errors' => &$errors
			);

			$etm->eventFinalSaveFilter( $etm_context );

			$context['filter_results'] = $errors;
		}

		private function triggerReflection($context){
			$reflection_ext_status = ExtensionManager::fetchStatus( array('handle' => 'reflectionfield') );
			if( $reflection_ext_status[0] !== EXTENSION_ENABLED ){
				return;
			}

			/** @var $reflection Extension_ReflectionField */
			$reflection = ExtensionManager::getInstance( 'reflectionfield' );

			$reflection_context = array(
				'entry' => $context['entry']
			);

			$reflection->compileFrontendFields( $reflection_context );
		}

		private function triggerMultilingualEntryUrl($context){
			$meu_ext_status = ExtensionManager::fetchStatus( array('handle' => 'multilingual_entry_url') );
			if( $meu_ext_status[0] !== EXTENSION_ENABLED ){
				return;
			}

			/** @var $reflection Extension_ReflectionField */
			$reflection = ExtensionManager::getInstance( 'multilingual_entry_url' );

			$meu_context = array(
				'entry' => $context['entry']
			);

			$reflection->compileFrontendFields( $meu_context );
		}

		/**
		 * Triggers XSS filter functionality
		 *
		 * @param $context
		 */
		private function triggerXSS($context){
			// make sure extension is enabled
			$xss_ext_status = ExtensionManager::fetchStatus( array('handle' => 'xssfilter') );
			if( $xss_ext_status[0] !== EXTENSION_ENABLED ){
				return;
			}

			// check for filter presence
			if( !in_array( 'xss-fail', $context['filters'] ) && !in_array( 'xss-remove', $context['filters'] ) ){
				return;
			}

			/** @var $xss_filter Extension_XssFilter */
			$xss_filter = ExtensionManager::getInstance( 'xssfilter' );

			$contains_xss = false;

			// Loop over the fields to check for XSS, this loop will
			// break as soon as XSS is detected
			foreach($context['original_fields'] as $value){
				if( is_array( $value ) ){
					if( $xss_filter::detectXSSInArray( $value ) ){
						$contains_xss = true;
						break;
					}
				}
				else{
					if( $xss_filter::detectXSS( $value ) ){
						$contains_xss = true;
						break;
					}
				}
			}

			// "fail" filter
			if( in_array( 'xss-fail', $context['filters'] ) && $contains_xss === true ){
				$context['filter_results'][] = array(
					'xss', false, __( "Possible XSS attack detected in submitted data" )
				);
			}
		}

		private function validateDependencies(){
			$result = true;

			// members installed
			$members = ExtensionManager::fetchStatus( array('handle' => 'members') );
			$result  = $result && ($members[0] === EXTENSION_ENABLED);

			// exsl function manager installed
			$efm    = ExtensionManager::fetchStatus( array('handle' => 'exsl_function_manager') );
			$result = $result && ($efm[0] === EXTENSION_ENABLED);

			$this->setValidDependencies( $result );
		}

	}
