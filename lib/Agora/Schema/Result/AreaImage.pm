package Agora::Schema::Result::AreaImage;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('area_image');
__PACKAGE__->add_columns(
	area => {
		data_type => 'TEXT',
		is_nullable => 0,
		is_foreign_key => 1,
	},
	device => {
		data_type => 'TEXT',
		is_nullable => 0,
	},
	src => {
		data_type => 'TEXT',
		is_nullable => 0,
	},
);

__PACKAGE__->set_primary_key('area', 'device');

__PACKAGE__->belongs_to(
	area => 
	'Agora::Schema::Result::Area',
	{ 'foreign.id' => 'self.area' }
);

1;
