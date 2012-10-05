package Agora::Schema::Result::Entry;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('entry');
__PACKAGE__->add_columns(
	id => {
		data_type => 'TEXT',
		is_nullable => 0,
	},
	category => {
		data_type => 'TEXT',
		is_nullable => 0,
		is_foreign_key => 1,
	},
	title => {
		data_type => 'TEXT',
		is_nullable => 0,
	},
	schedule => {
		data_type => 'TEXT',
		is_nullable => 0,
	},
	sponsor => {
		data_type => 'TEXT',
		is_nullable => 0,
	},
	cosponsor => {
		data_type => 'TEXT',
		is_nullable => 1,
	},
	guest => {
		data_type => 'TEXT',
		is_nullable => 1,
	},
	abstract => {
		data_type => 'TEXT',
		is_nullable => 1,
	},
	content => {
		data_type => 'TEXT',
		is_nullable => 1,
	},
	website => {
		data_type => 'TEXT',
		is_nullable => 1,
	},
	reservation => {
		data_type => 'TEXT',
		is_nullable => 1,
	},
	note => {
		data_type => 'TEXT',
		is_nullable => 1,
	},
	original => {
		data_type => 'TEXT',
		is_nullable => 0,
	},
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
	category => 
	'Agora::Schema::Result::Category',
	{ 'foreign.id' => 'self.category' }
);

1;
