package Agora::Schema::Result::Location;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('location');
__PACKAGE__->add_columns(
	entry => {
		data_type => 'TEXT',
		is_nullable => 0,
		is_foreign_key => 1,
	},
	area => {
		data_type => 'TEXT',
		is_nullable => 0,
		is_foreign_key => 1,
	},
	x => {
		data_type => 'REAL',
		is_nullable => 0,
	},
	y => {
		data_type => 'REAL',
		is_nullable => 0,
	},
);

__PACKAGE__->set_primary_key('entry');

__PACKAGE__->belongs_to(
	entry_ => 
	'Agora::Schema::Result::Entry',
	{ 'foreign.id' => 'self.entry' }
);

__PACKAGE__->belongs_to(
	area_ =>
	'Agora::Schema::Result::Area',
	{ 'foreign.id' => 'self.area' }
);

1;
