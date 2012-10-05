package Agora::Area;

use strict;
use warnings;

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
	return bless $data, $self;
}

sub get_id {
	my($self, $key) = @_;
	if (!exists $self->{$key}) {
		croak "unknown category name '$key' found";
	}
	return $self->{$key}{id};
}

sub as_list {
	my $self = shift;
	my @key_order = sort { $self->{$a}{id} cmp $self->{$b}{id} } (keys %$self);
	return map { $self->{$_} } @key_order;
}


1;
