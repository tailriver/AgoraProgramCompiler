package Agora::Hint;

use strict;
use warnings;

use Carp;
use YAML;

sub new {
	my($self, $yamlfile) = @_;
	my $yaml = YAML::LoadFile($yamlfile);
	my %data;
	my $id = 1;
	for my $table (keys %$yaml) {
		for my $column (keys %{$yaml->{$table}}) {
			my %row = map { $_ => $yaml->{$table}{$column}{$_} }
					qw(ja en description warning ref);
			$row{id}          = $id;
			$row{table_name}  = $table;
			$row{column_name} = $column;
			$data{"$table.$column"} = \%row;
			$id++;
		}
	}
	for my $row (keys %data) {
		if ($data{$row}->{ref} && $data{$row}->{ref} =~ /\./) {
			$data{$row}->{ref} = $data{$data{$row}->{ref}}->{id};
		}
	}
	return bless \%data, $self;
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
