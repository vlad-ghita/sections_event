<?php

	Abstract Class SE_PermissionsBase
	{

		/**
		 * @var string
		 */
		protected $res = null;

		/**
		 * The factory
		 *
		 * @var SE_PerMan
		 */
		protected $factory = null;



		public function __construct($factory, $res){
			$this->setFactory($factory);
			$this->setRes( $res );
		}



		/*------------------------------------------------------------------------------------------------*/
		/*  Setters & Getters  */
		/*------------------------------------------------------------------------------------------------*/

		final protected function setFactory($factory){
			$this->factory = $factory;
		}

		final protected function getFactory(){
			return $this->factory;
		}

		final protected function setRes($res){
			$this->res = $res;
		}

		final protected function getRes(){
			return $this->res;
		}

		/**
		 * Shortcut to create an object.
		 *
		 * @param $type
		 *
		 * @return mixed
		 */
		final protected function getObject($type){
			return $this->getFactory()->getObject( $this->getRes(), $type );
		}

	}
