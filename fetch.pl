#!/usr/bin/env perl

use v5.12;
use FindBin;
use lib "$FindBin::Bin/lib";

use Agora::Constant;
use Agora::Fetcher;
use Agora::Program;
use File::Path;

my $ac = Agora::Constant->new;
my $af = Agora::Fetcher->new;
File::Path::mkpath($ac->LOCAL_BASE);

my $status_index = $af->fetch($ac->REMOTE_INDEX, $ac->LOCAL_INDEX);
given ($status_index) {
	say "index [$status_index]" when /^2/ || /^3/;
	default {
		die "ERROR: index [$status_index]\n";
	}
}

my @id_list = Agora::Program::extract_id($ac->LOCAL_INDEX);
foreach my $id (@id_list) {
	my $url  = sprintf($ac->REMOTE_DETAIL, $id);
	my $file = sprintf($ac->LOCAL_DETAIL,  $id);
	my $status = $af->fetch($url, $file);
	given ($status) {
		say "$id [$status]" when /^2/ || /^3/;
		default {
			warn "ERROR: $id [$status]\n";
		}
	}
	sleep 1;
}

exit;
