#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/lib";

use Agora::Constant;
use Agora::Program;
use DBI;
use HTML::TreeBuilder;
use XML::Simple;

my %table_to_en = (
	'主催' => 'sponsor',
	'日時' => 'schedule',
	'会場' => 'location',
);

my $sqlite_file = $ARGV[0] !~ /\.xml$/i ? $ARGV[0] : undef;
my $xml_file    = $ARGV[0] =~ /\.xml$/i ? $ARGV[0] : undef;

my @insert_event_keys = qw(title sponsor schedule location is_allday);
my @insert_timeframe_keys = qw(day start end);

my($dbh, $insert_event, $insert_timeframe);
if ($sqlite_file) {
	unlink $sqlite_file;
	$dbh = DBI->connect("dbi:SQLite:dbname=$sqlite_file");
	$dbh->{AutoCommit} = 0;
	$dbh->do('CREATE TABLE event (eid TEXT PRIMARY KEY, title TEXT, sponsor TEXT, schedule TEXT, location TEXT, is_allday INTEGER)');
	$dbh->do('CREATE TABLE timeframe (eid TEXT REFERENCES event(eid), day TEXT, start TEXT, end TEXT, UNIQUE(eid,day,start))');
	$insert_event = $dbh->prepare("INSERT INTO event (eid,". join(',',@insert_event_keys). ") VALUES (?,". join(',',split(//,'?' x @insert_event_keys)) .")");
	$insert_timeframe = $dbh->prepare("INSERT INTO timeframe (eid,". join(',',@insert_timeframe_keys). ") VALUES (?,". join(',',split(//,'?' x @insert_timeframe_keys)). ")");
}

my @id_list = Agora::Program::extract_id(Agora::Constant->LOCAL_INDEX);
my @entries;
foreach my $id (@id_list) {
	open my $EVENT_FILE, '<:encoding(cp932)', "$program_dir/$id.html" or die $!;
	local $/ = undef;
	my $html = <$EVENT_FILE>;
	close $EVENT_FILE;

	my $root = HTML::TreeBuilder->new_from_content($html);
	my $base   = $root->look_down(id => 'base');
	my $detail = $root->look_down(id => 'detail');

	my %entry;
	$entry{id} = $id;
	$entry{is_allday} = $id =~ /a/ ? 1 : 0;
	$entry{category}  = $base->look_down(class => 'category')->as_trimmed_text();
	$entry{title}     = $base->look_down(class => 'title')->as_trimmed_text();

	my @base_dl   = $base->find_by_tag_name('dl');
	my @detail_dl = $detail->find_by_tag_name('dl');
	for (@base_dl, @detail_dl) {
		my ($k, $v) = dl_parse($_);
		$entry{to_en($k)} = $v;
	}

	if (!$entry{is_allday}) {
		my ($day, $start, $end) = $entry{schedule} =~ m{11/(\d+).*?(\d+:\d+)-(\d+:\d+)};
		if ($day == 10) {
			$day = 'Sat';
		}
		elsif ($day == 11) {
			$day = 'Sun';
		}
		else {
			die "unknown day: $day";
		}
		$entry{timeframe} = [ { day => $day, start => $start, end => $end } ];
	}
	else {
		die "multiple time? -> $entry{shedule}" if ($entry{schedule} =~ /-/g) != 1;

		my($start, $end) = ($entry{schedule} =~ /(\d+:\d+)-(\d+:\d+)/);
		my $timeframe_sat = { day => 'Sat', start => $start, end => $end };
		my $timeframe_sun = { day => 'Sun', start => $start, end => $end };
		if ($entry{schedule} =~ m{11/10・11}) {
			$entry{timeframe} = [ $timeframe_sat, $timeframe_sun ];
		}
		elsif ($entry{schedule} =~ m{11/10}) {
			$entry{timeframe} = [ $timeframe_sat ];
		}
		elsif ($entry{schedule} =~ m{11/11}) {
			$entry{timeframe} = [ $timeframe_sun ];
		}
		else {
			die "unknown day: $entry{schedule}";
		}
	}

	if ($sqlite_file) {
		$insert_event->execute($id, @entry{@insert_event_keys});
		foreach my $tf (@{$entry{timeframe}}) {
			my %tf = %$tf;
			$insert_timeframe->execute($id, @tf{@insert_timeframe_keys});
		}
	}

	# patch
	foreach my $tf (@{$entry{timeframe}}) {
		$tf->{start} =~ s/://;
		$tf->{end}   =~ s/://;
	}

	push @entries, \%entry;
}
if ($sqlite_file) {
	$dbh->commit;
	$dbh->disconnect;
}

if ($xml_file) {
	my $xs = XML::Simple->new(RootName => "entrylist");
	open my $XML, '>:utf8', $xml_file or die $!;
	say $XML q(<?xml version="1.0" encoding="UTF-8"?>);
	say $XML q(<!DOCTYPE entrylist PUBLIC "-//tailriver//ScienceAgora 2011 EntryList//EN");
	say $XML q(  "http://tailriver.net/agoraguide/dtd">);
	print $XML $xs->XMLout({entry => \@entries});
	close $XML;
}

exit;


sub dl_parse {
	my $dt = $_[0]->find_by_tag_name('dt')->as_trimmed_text();
	my $dd = $_[0]->find_by_tag_name('dd')->as_trimmed_text();
	return ($dt, $dd);
}

sub to_en {
	return (exists $table_to_en{$_[0]}) ? $table_to_en{$_[0]} : $_[0];
}
