#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/lib";

use Agora::Area;
use Agora::Category;
use Agora::Constant;
use Agora::Program;
use Agora::Schema;
use HTML::TreeBuilder;

my $sqlite_file = $ARGV[0];

my %table_to_en = (
	'主催' => 'sponsor',
	'日時' => 'schedule',
	'会場' => 'location',
);

my $area     = Agora::Area->new('area.yml');
my $category = Agora::Category->new('category.yml');

my @areas      = $area->as_list;
my @categories = $category->as_list;
my @area_images;
my @entries;
my @locations;
my @timeframes;

for my $area (@areas) {
	my @images = @{delete $area->{image}};
	for my $image (@images) {
		$image->{area} = $area->{id};
		push @area_images, $image;
	}
}

my @id_list = Agora::Program::extract_id(Agora::Constant->LOCAL_INDEX);
foreach my $id (@id_list) {
	my $file = sprintf Agora::Constant->LOCAL_DETAIL, $id;
	open my $ENTRY_FILE, '<:encoding(cp932)', $file or die $!;
	local $/ = undef;
	my $html = <$ENTRY_FILE>;
	close $ENTRY_FILE;

	my $root = HTML::TreeBuilder->new_from_content($html);
	my $base   = $root->look_down(id => 'base');
	my $detail = $root->look_down(id => 'detail');

	my %entry;
	$entry{id}       = $id;
	$entry{title}    = $base->look_down(class => 'title')->as_trimmed_text();
	$entry{category} = $base->look_down(class => 'category')->as_trimmed_text();
	$entry{category} = $category->get_id($entry{category});
	$entry{original} = sprintf Agora::Constant->REMOTE_DETAIL, $id;

	my @base_dl   = $base->find_by_tag_name('dl');
	my @detail_dl = $detail->find_by_tag_name('dl');
	for (@base_dl, @detail_dl) {
		my ($k, $v) = dl_parse($_);
		$entry{to_en($k)} = $v;
	}

	my($location_y, $location_x) = ($id =~ /(\d)(\d)$/);
	push @locations, {
		entry => $id,
		area  => $area->get_id(delete $entry{location}),
		x     => int((0.05 + 0.1 * $location_x)*1000)/1000,
		y     => int((0.05 + 0.1 * $location_y)*1000)/1000,
	};

	die "multiple time? -> $entry{shedule}" if ($entry{schedule} =~ /-/g) != 1;

	my($duration, $start, $end) = ($entry{schedule} =~ /((\d+:\d+)-(\d+:\d+))$/);
	if ($entry{schedule} =~ m{11/10・11}) {
		$entry{schedule} = "[Sat] [Sun] $duration";
	}
	elsif ($entry{schedule} =~ m{11/10}) {
		$entry{schedule} = "[Sat] $duration";
	}
	elsif ($entry{schedule} =~ m{11/11}) {
		$entry{schedule} = "[Sun] $duration";
	}
	else {
		die "unparsable schedule expression: $entry{schedule}";
	}

	$start =~ tr/://d;
	$end   =~ tr/://d;
	for my $day (qw/Sat Sun/) {
		if ($entry{schedule} =~ /\[$day\]/) {
			push @timeframes, {
				entry => $id,
				day   => $day,
				start => $start,
				end   => $end
			};
		}
	}

	push @entries, \%entry;
}

# transaction

unlink $sqlite_file;
my $schema = Agora::Schema->connect("dbi:SQLite:dbname=$sqlite_file");

my $txn = sub {
	my ($resultset, $arrayref) = @_;
	my $rs = $schema->resultset($resultset);
	for (@$arrayref) {
		$rs->create($_);
	}
};

$schema->deploy;
$schema->txn_do($txn, Area      => \@areas);
$schema->txn_do($txn, AreaImage => \@area_images);
$schema->txn_do($txn, Category  => \@categories);
$schema->txn_do($txn, Entry     => \@entries);
$schema->txn_do($txn, Location  => \@locations);
$schema->txn_do($txn, Timeframe => \@timeframes);

exit;


sub dl_parse {
	my $dt = $_[0]->find_by_tag_name('dt')->as_trimmed_text();
	my $dd = $_[0]->find_by_tag_name('dd')->as_trimmed_text();
	return ($dt, $dd);
}

sub to_en {
	return (exists $table_to_en{$_[0]}) ? $table_to_en{$_[0]} : $_[0];
}
