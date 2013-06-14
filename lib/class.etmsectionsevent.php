<?php



	require_once(TOOLKIT.'/class.event.php');



	Final Class ETMSectionsEvent extends Event
	{

		public $eParamFILTERS = array();

		public static function about(){
			return array(
				'name' => 'sections',
			);
		}

	}
