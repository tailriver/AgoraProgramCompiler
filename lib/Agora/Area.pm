package Agora::Area;

use strict;
use warnings;
use utf8;

use Carp;
use YAML;

sub new {
	my($self, $yamlfile) = @_;
	my $data = YAML::LoadFile($yamlfile);
	for my $key (keys %$data) {
		$data->{$key}{name} = $key;
		for my $image (@{$data->{$key}{image}}) {
			$image->{device} =~ s/_/@/g;
		}
	}
	return bless { yaml => $data }, $self;
}

sub get_id {
	my($self, $key) = @_;
	if (!exists $self->{yaml}{$key}) {
		croak "unknown area name '$key' found";
	}
	return $self->{yaml}{$key}{id};
}

sub as_list {
	my $self = shift;
	my $yaml = $self->{yaml};
	my @key_order = sort { $yaml->{$a}{id} cmp $yaml->{$b}{id} } (keys %$yaml);
	return map { $yaml->{$_} } @key_order;
}


1;
