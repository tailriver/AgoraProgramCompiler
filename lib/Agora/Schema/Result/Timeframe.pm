package Agora::Schema::Result::Timeframe;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('timeframe');
__PACKAGE__->add_columns(
	entry => {
		data_type => 'TEXT',
		is_nullable => 0,
		is_foreign_key => 1,
	},
	day => {
		data_type => 'TEXT',
		is_nullable => 0,
	},
	start => {
		data_type => 'INTEGER',
		is_nullable => 0,
	},
	end => {
		data_type => 'INTEGER',
		is_nullable => 0,
	},
);

__PACKAGE__->set_primary_key('entry', 'day', 'start');

__PACKAGE__->belongs_to(
	entry => 
	'Agora::Schema::Result::Entry',
	{ 'foreign.id' => 'self.entry' }
);

1;
