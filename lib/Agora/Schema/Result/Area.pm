package Agora::Schema::Result::Area;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('area');
__PACKAGE__->add_columns(
	id => {
		data_type => 'TEXT',
		is_nullable => 0,
	},
	name => {
		data_type => 'TEXT',
		is_nullable => 0,
	},
	abbrev => {
		data_type => 'TEXT',
		is_nullable => 0,
	},
);

__PACKAGE__->set_primary_key('id');


1;
