package Agora::Location;

use strict;
use warnings;

use Carp;
use YAML;

sub new {
	my($self, $yamlfile) = @_;
	my $data = YAML::LoadFile($yamlfile);
	my %map;
	for my $area (keys %$data) {
		for my $xy (keys %{$data->{$area}}) {
			my($x, $y) = split /-/, $xy;
			for my $id (@{$data->{$area}{$xy}}) {
				if (exists $map{$id}) {
					croak "id '$id' is duplicated";
				}
				$id =~ s/\s*#.*$//g;
				$map{$id} = { x => $x, y => $y };
			}
		}
	}
	return bless \%map, $self;
}

sub get_x {
	my($self, $id) = @_;
	if (!exists $self->{$id}) {
		croak "unknown id '$id'";
	}
	return $self->{$id}{x};
}

sub get_y {
	my($self, $id) = @_;
	if (!exists $self->{$id}) {
		croak "unknown id '$id'";
	}
	return $self->{$id}{y};
}


1;
