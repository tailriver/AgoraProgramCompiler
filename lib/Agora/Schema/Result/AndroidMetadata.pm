package Agora::Schema::Result::AndroidMetadata;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('android_metadata');
__PACKAGE__->add_columns(
	locale => {
		data_type => 'TEXT',
		default_value => 'ja_JP',
		is_nullable => 1,
	},
);


1;
