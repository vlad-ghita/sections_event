(function ($, undefined) {

	$(document).ready(function () {
		var $permissions = $('.permissions');


		// field tables switch based on section
		var $fields = $permissions.find('.fields');
		var $section_selector = $fields.find('.section-selector select');
		var $field_tables = $fields.find('table');

		$section_selector
			.on('change', function () {
				var sid = $section_selector.val();
				$field_tables.hide().filter('[data-section="' + sid + '"]').show();
			})
			.trigger('change');


		// toggle all permissions base on <th/> select
		$permissions.find('th > select').on('change', function () {
			var $select = $(this);
			var value = $select.val();
			var index = $select.parents('th:eq(0)').index();
			var $table = $select.parents('table:eq(0)');

			$table.find('tr td:nth-child(' + (index + 1) + ') > select').val(value);
		});
	});

})(jQuery);
