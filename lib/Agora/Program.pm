package Agora::Program;

use strict;
use warnings;

use List::MoreUtils;

sub extract_id {
	my $index_file = shift;

	my @id_list_not_unique;
	open my $INDEX_FILE, '<:utf8', $index_file or die $!;
	while (<$INDEX_FILE>) {
		if (/summary\/(.*?)\.html/) {
			push @id_list_not_unique, $1;
		}
	}
	close $INDEX_FILE;
	return List::MoreUtils::uniq @id_list_not_unique;
}


1;
