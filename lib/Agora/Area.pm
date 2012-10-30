package Agora::Area;

use strict;
use warnings;
use utf8;

use Carp;
use YAML;

sub new {
	my($self, $yamlfile) = @_;
	my $data = YAML::LoadFile($yamlfile);
	my $dummy_url_base = "http://tailriver.net/agoraguide/2012/area/";
	for my $key (keys %$data) {
		$data->{$key}{name} = $key;
		for my $image (@{$data->{$key}{image}}) {
			$image->{device} =~ s/_/@/g;
			$image->{src} = $image->{device} eq 'iOS' ?
				$dummy_url_base. 'dummy.png' : $dummy_url_base. 'dummy@2x.png';
		}
	}
	return bless $data, $self;
}

sub get_id {
	my($self, $key) = @_;
	$key =~ tr/ //d;
	$key =~ tr/Ａ-Ｚ/A-Z/;
	if (!exists $self->{$key}) {
		croak "unknown area name '$key' found";
	}
	return $self->{$key}{id};
}

sub as_list {
	my $self = shift;
	my @key_order = sort { $self->{$a}{id} cmp $self->{$b}{id} } (keys %$self);
	return map { $self->{$_} } @key_order;
}


1;
