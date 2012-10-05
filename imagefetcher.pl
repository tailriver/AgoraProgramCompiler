#!/usr/bin/env perl

use v5.12;
use lib 'lib';
use Agora::Schema;
use Agora::Fetcher;

my $schema = Agora::Schema->connect("dbi:SQLite:dist/2012.sqlite3");

my $rs = $schema->resultset('AreaImage')->search;
my $af = Agora::Fetcher->new;

while (my $row = $rs->next) {
	next if $row->src =~ m{^http://tailriver.net/};
	my $pngfile = 'dist/2012/area/'. $row->area->id. '_'. $row->device. '.png';
	$af->($row->src, $pngfile);
	sleep 1;
}
