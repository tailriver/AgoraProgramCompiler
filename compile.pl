#!/usr/bin/env perl

use v5.16;
use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/lib";

use Agora::Area;
use Agora::Category;
use Agora::Constant;
use Agora::Hint;
use Agora::Location;
use Agora::Program;
use Agora::Schema;
use Clone qw(clone);
use HTML::FormatText;
use HTML::TreeBuilder;
use Try::Tiny;

my $sqlite_file = $ARGV[0];

my %table_to_en = (
	'主催'   => 'sponsor',
	'共催等' => 'cosponsor',
	'概要'   => 'abstract',
	'日時'   => 'schedule',
	'会場'   => 'location',
	'内容'   => 'content',
	'主な登壇者など' => 'guest',
	'参考URL' => 'website',
	'事前申込' => 'res1',
	'当日申込' => 'res2',
	'備考'   => 'note',
);

my $area     = Agora::Area->new('area.yml');
my $category = Agora::Category->new('category.yml');
my $hint     = Agora::Hint->new('hint.yml');
my $location = Agora::Location->new('location.yml');
my $formatter = HTML::FormatText->new(rightmargin => 10000);

my @areas      = $area->as_list;
my @categories = $category->as_list;
my @hints      = $hint->as_list;
my @area_images;
my @entries;
my @locations;
my @timeframes;

for my $area (@areas) {
	my $images = clone $area->{image};
	for my $image (@$images) {
		$image->{area} = $area->{id};
		push @area_images, $image;
	}
}

for my $area (@areas) {
	delete $area->{image};
}

my @id_list = Agora::Program::extract_id(Agora::Constant->LOCAL_INDEX);
my @skip_id = qw(Aa-030 Aa-032);
foreach my $id (@id_list) {
	my $file = sprintf Agora::Constant->LOCAL_DETAIL, $id;
	open my $ENTRY_FILE, '<:encoding(cp932)', $file or die $!;
	local $/ = undef;
	my $html = <$ENTRY_FILE>;
	close $ENTRY_FILE;

	$html =~ s/<a [^>]*href=["']([^"']+)[^>]*>(.+?)<\/a>/$2( $1 )/g;

	my $root = HTML::TreeBuilder->new_from_content($html);
	my $base   = $root->look_down(id => 'base');
	my $detail = $root->look_down(id => 'detail');

	my %entry;
	$entry{id}       = $id;
	$entry{title}    = $base->look_down(class => 'title')->as_trimmed_text();
	$entry{category} = $base->look_down(class => 'category')->as_trimmed_text();
	$entry{original} = sprintf Agora::Constant->REMOTE_DETAIL, $id;

	try {
		my @base_dl   = $base->find_by_tag_name('dl');
		my @detail_dl = $detail->find_by_tag_name('dl');
		for (@base_dl, @detail_dl) {
			my ($k, $v) = dl_parse($_);
			$entry{to_en($k)} = $v;
		}
	} catch {
		my $msg = $_;
		if (grep { $id eq $_ } @skip_id) {
			warn "skip $id\n";
			$entry{skip} = 1;
		}
		else {
			die "$id: $msg\n" if $msg;
		}
	};
	next if exists $entry{skip};

	$entry{location} =~ s/\( http[^)]+ \)//;
	$entry{location} =~ s/ＣＡＮ/CAN/;
	$entry{reservation} = delete($entry{res1}). "\n". delete($entry{res2});

	if ($entry{schedule} eq "11月10日（土）10:30-12:00,12:30-14:00、11日（日）14:30-16:00") {
		$entry{schedule} = "[Sat] 10:30-12:00 [Sat] 12:30-14:00 [Sun] 14:30-16:00";
		push @timeframes, { entry => $id, day => 'Sat', start => 1030, end => 1200 };
		push @timeframes, { entry => $id, day => 'Sat', start => 1230, end => 1400 };
		push @timeframes, { entry => $id, day => 'Sun', start => 1430, end => 1600 };
	}
	elsif ($entry{schedule} eq "11月10日（土）13:30-16:30、11日（日）10:00-16:00") {
		$entry{schedule} = "[Sat] 13:30-16:30 [Sun] 10:00-16:00";
		push @timeframes, { entry => $id, day => 'Sat', start => 1330, end => 1630 };
		push @timeframes, { entry => $id, day => 'Sun', start => 1000, end => 1600 };
	}
	elsif ($entry{schedule} eq "11月11日（日） 10:30-12:00,12:30-14:00") {
		$entry{schedule} = "[Sun] 10:30-12:00 [Sun] 12:30-14:00";
		push @timeframes, { entry => $id, day => 'Sun', start => 1030, end => 1200 };
		push @timeframes, { entry => $id, day => 'Sun', start => 1230, end => 1400 };
	}
	else {
		die "multiple time? -> $entry{schedule}" if ($entry{schedule} =~ tr/-/-/) != 1;

		my($duration, $start, $end) = ($entry{schedule} =~ /((\d+:\d+)-(\d+:\d+))$/);
		if ($entry{schedule} =~ m{11月10日（土）・11日（日）}) {
			$entry{schedule} = "[Sat] [Sun] $duration";
		}
		elsif ($entry{schedule} =~ m{11月10日（土）}) {
			$entry{schedule} = "[Sat] $duration";
		}
		elsif ($entry{schedule} =~ m{11月11日（日）}) {
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
	}

	apply_hook('Aa-077', \%entry, '★実験の内容',
			sub{ exists $_[0] },
			sub{ delete $entry{'★実験の内容'} }
	);

	apply_hook('Ab-366', \%entry, 'note',
			sub { $_[0] =~ /fromEmail=true&/ },
			sub { $_[0] =~ s/fromEmail=true&// }
	);

	apply_hook('Ea-963', \%entry, 'reservation',
			sub { $_[0] =~ /申込フォーム/ },
			sub { $_[0] =~ s/申込フォーム/お問い合わせフォーム/ }
	);

	apply_hook('OP', \%entry, 'title',
			sub { $_[0] =~ /http/ },
			sub { $_[0] =~ s/ \(.*\)$// }
	);
	apply_hook('OP', \%entry, 'location',
			sub { $_[0] eq "日本科学未来館7階みらいCANホール" },
			sub { $_[0] = "日本科学未来館 7階 みらいCANホール" }
	);
	apply_hook('OP', \%entry, 'reservation',
			sub { $_[0] =~ /Webフォーム/ },
			sub { $_[0] =~ s/Webフォーム/お問い合わせフォーム/ }
	);

	$entry{category}    =  $category->get_id($entry{category});
	$entry{location}    =~ tr/　//d;
	$entry{reservation} =  get_reservation($id, $entry{reservation});
	$entry{website}     =~ s/\(.+\)//;

	try {
		push @locations, {
			entry => $id,
			area  => $area->get_id(delete $entry{location}),
			x     => $location->get_x($id),
			y     => $location->get_y($id),
		};
	} catch {
		die "$id: $_\n" if $_;
	};

	for (keys %entry) {
		$entry{$_} = undef unless length $entry{$_};
	}
	push @entries, \%entry;
}

# transaction

unlink $sqlite_file;
my $schema = Agora::Schema->connect("dbi:SQLite:dbname=$sqlite_file");

my $txn = sub {
	my ($resultset, $arrayref) = @_;
	my $rs = $schema->resultset($resultset);
	for my $row (@$arrayref) {
		try {
			$rs->create($row);
		} catch {
			use YAML;
			warn $_. "\n";
			die YAML::Dump $row if $_;
		};
	}
};

$schema->deploy;
$schema->txn_do($txn, Area      => \@areas);
$schema->txn_do($txn, AreaImage => \@area_images);
$schema->txn_do($txn, Category  => \@categories);
$schema->txn_do($txn, Entry     => \@entries);
$schema->txn_do($txn, Hint      => \@hints);
$schema->txn_do($txn, Location  => \@locations);
$schema->txn_do($txn, Timeframe => \@timeframes);

exit;


sub dl_parse {
	my $dt = $_[0]->find_by_tag_name('dt')->as_trimmed_text();
	my $dd = $_[0]->find_by_tag_name('dd')->format($formatter);
	$dd =~ s/^\s+//mg;
	$dd =~ s/(\S)\s+$/$1/mg;
	$dd = '' if $dd eq '-';
	return ($dt, $dd);
}

sub to_en {
	return (exists $table_to_en{$_[0]}) ? $table_to_en{$_[0]} : $_[0];
}

sub get_reservation {
	my($id, $s) = @_;
	$s =~ s/なし（自由に参加できます）\n//;
	$s =~ s/あり（当日見学のみの参加は可能です）\n//;
	$s =~ s/あり（当日枠もあります）\n//;
	$s =~ s/\*\s*\n//g;
	my $res  = $s =~ s/事前枠（人）：(.*)\n//  && $1;
	my $open = $s =~ s/当日枠（人）：(.*)\n?// && $1;
	my($start, $end) = $s =~ s/\* 申込開始予定日時：(.*?) 締切予定日時：(.*)\n// && ($1, $2);
	my $note = $s =~ s/\* 特記事項：(.*)\n//   && $1;
	for ($res, $open) {
		tr/０１２３４５６７８９/0123456789/ if defined $_;
		if (length $_ && $_ !~ /名|人/ && $_ ne "残り") {
			$_ .= "名";
		}
	}
	my @methods;
	$s =~ s/\* 申込方法：?\n//;
	$s =~ s/\*\s+お問い合わせフォーム\( ([^ ]+) \)から\n// && push @methods, $1;
	$s =~ s/\*\s+eメール（([^）]*)）\n// && push @methods, $1;
	$s =~ s/\*\s+電話（([^）]*)）\n(?:\*\s+FAX（\1）\n)?// && push @methods, $1;
	$s =~ s/\*\s+ハガキ（はがき）\n//;
	$s =~ s/\*\s+その他（その他）\n//;

	if ($s ne "") {
		die "$id: reservation [$s]\n";
	}
	if ($res || $open) {
		my $str = '';
		$str .= "事前申込枠：$res\n" if $res;
		$str .= "事前申込期間：$start $end\n" if $end;
		$str .= "事前申込方法：@methods\n" if @methods;
		$str .= "特記事項：$note\n" if $note;
		$str .= "当日参加枠：$open" if $open;
		chomp $str;
		return $str;
	}
	return undef;
}

sub apply_hook {
	my($id, $entry, $key, $condition, $fix) = @_;
	return if $entry->{id} ne $id;
	if ($condition->($entry->{$key})) {
		$fix->($entry->{$key});
	}
	else {
		warn "$id $key hook NOT WORKED\n";
		warn "[$entry->{$key}]\n";
	}
}
