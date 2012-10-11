package Agora::Schema::Result::Hint;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('hint');
__PACKAGE__->add_columns(
	id => {
		data_type => 'INTEGER',
		is_nullable => 0,
	},
	table_name => {
		data_type => 'TEXT',
		is_nullable => 0,
	},
	column_name => {
		data_type => 'TEXT',
		is_nullable => 0,
	},
	en => {
		data_type => 'TEXT',
		is_nullable => 1,
	},
	ja => {
		data_type => 'TEXT',
		is_nullable => 1,
	},
	description => {
		data_type => 'TEXT',
		is_nullable => 1,
	},
	warning => {
		data_type => 'TEXT',
		is_nullable => 1,
	},
	ref => {
		data_type => 'INTEGER',
		is_foreign_key => 1,
		is_nullable => 1,
	},
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
	ref_id => 
	'Agora::Schema::Result::Hint',
	{ 'foreign.id' => 'self.ref' }
);

1;
