<?php

	Final Class SE_Permissions
	{
		const ACTION_VIEW   = 'view';
		const ACTION_CREATE = 'create';
		const ACTION_EDIT   = 'edit';
		const ACTION_DELETE = 'delete';

		const LEVEL_NONE = 0;
		const LEVEL_OWN  = 1;
		const LEVEL_ALL  = 2;

		public static $actionMap = array(
			self::ACTION_VIEW   => 'View',
			self::ACTION_CREATE => 'Create',
			self::ACTION_EDIT   => 'Edit',
			self::ACTION_DELETE => 'Delete'
		);

		public static $levelMap = array(
			self::LEVEL_NONE => 'None',
			self::LEVEL_OWN  => 'Own',
			self::LEVEL_ALL  => 'Any'
		);
	}
