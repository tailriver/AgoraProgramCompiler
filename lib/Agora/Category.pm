package Agora::Category;

use strict;
use warnings;

use Carp;
use YAML;

sub new {
	my($self, $yamlfile) = @_;
	my $data = YAML::LoadFile($yamlfile);
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
	return map { +{$_ => $self->{$_}} } @key_order;
}


1;
