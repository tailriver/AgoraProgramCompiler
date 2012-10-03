package Agora::Fetcher;

use strict;
use warnings;

use Carp;
use Furl;
use HTTP::Date;

sub new { return bless {}, $_[0]; }

sub fetch {
	if (ref $_[0]) {
		shift @_;
	}

	my ($url, $filename) = @_;
	my $since = (-e $filename) ? (stat $filename)[9] : 0;

	my $furl = Furl->new(
		agent => 'AgoraProgramCompiler/2012',
		timeout => 10,
	);

	my $res = $furl->get($url, ['If-Modified-Since' => time2str($since) ]);
	if ($res->is_success) {
		open my $FH, '>:raw', $filename or croak $!;
		print $FH $res->content;
		close $FH;
	}

	return $res->code;
}

1;
