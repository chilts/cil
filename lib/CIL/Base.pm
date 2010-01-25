## ----------------------------------------------------------------------------
# cil is a Command line Issue List
# Copyright (C) 2008 Andrew Chilton
#
# This file is part of 'cil'.
#
# cil is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.
#
## ----------------------------------------------------------------------------

package CIL::Base;

use strict;
use warnings;
use Carp;
use DateTime;
use CIL::Utils;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(CreatedBy Inserted Updated));

## ----------------------------------------------------------------------------

sub new_from_name {
    my ($class, $cil, $name) = @_;

    croak 'provide a name'
        unless defined $name;

    my $filename = $class->filename($cil, $name);
    croak "filename '$filename' does no exist"
        unless $cil->file_exists($filename);

    my $data = $cil->parse_cil_file($filename, $class->last_field);
    my $issue = $class->new_from_data( $name, $data );
    return $issue;
}

sub new_from_data {
    my ($class, $name, $data) = @_;

    croak 'please provide an issue name'
        unless defined $name;

    # ToDo: check we have all the other correct fields

    # create the issue
    my $self = $class->new( $name );

    my $fields = $class->fields();
    my $array_fields = $class->array_fields();

    # save each field
    foreach my $field ( @$fields ) {
        next unless defined $data->{$field};

        # make it an array if it should be one
        if ( exists $array_fields->{$field} and ref $data->{$field} ne 'ARRAY' ) {
            $data->{$field} = [ $data->{$field} ];
        }

        # modify the data directly, otherwise Updated will kick in
        $self->set_no_update($field, $data->{$field});
    }
    $self->set_no_update('Changed', 0);
    $self->set_no_update('Updated', $data->{Updated});

    return $self;
}

sub new_from_fh {
    my ($class, $name, $fh) = @_;

    croak 'please provide name'
        unless defined $name;

    my $data = CIL::Utils->parse_from_fh( $fh, $class->last_field );
    return $class->new_from_data( $name, $data );
}

sub set_data {
    my ($self, $data) = @_;

    # loop through all the allowed fields
    my $fields = $self->fields();
    my $array_fields = $self->array_fields();

    # save each field
    foreach my $field ( @$fields ) {
        next unless defined $data->{$field};

        # make it an array if it should be one
        if ( exists $array_fields->{$field} and ref $data->{$field} ne 'ARRAY' ) {
            $data->{$field} = [ $data->{$field} ];
        }

        # modify the data directly, otherwise Updated will kick in
        $self->set_no_update($field, $data->{$field});
    }
    $self->set_no_update('Changed', 1);

    $self->{data} = $data;
}

sub save {
    my ($self, $cil) = @_;

    my $filename = $self->filename($cil, $self->name);

    my $fields = $self->fields();

    $cil->save( $filename, $self->{data}, @$fields );
}

sub as_output {
    my ($self) = @_;
    my $fields = $self->fields();
    return CIL::Utils->format_data_as_output( $self->{data}, @$fields );
}

sub filename {
    my ($class, $cil, $name) = @_;

    # create the filename from it's parts
    my $prefix    = $class->prefix();
    my $issue_dir = $cil->IssueDir;
    my $filename  = "${issue_dir}/${prefix}_${name}.cil";

    return $filename;
}

# override Class::Accessor's get
sub get {
    my ($self, $field) = @_;
    croak "provide a field name"
        unless defined $field;
    $self->{data}{$field};
}

# override Class::Accessor's set
sub set {
    my ($self, $field, $value) = @_;
    croak "provide a field name"
        unless defined $field;

    my $orig = $self->get($field);

    # finish if both are defined and they're the same
    if ( defined $orig and defined $value ) {
        return if $orig eq $value;
    }

    # finish if neither are defined
    return unless ( defined $orig or defined $value );

    # since we're actually changing the field, say we updated something
    $self->{data}{$field} = $value;
    $self->set_updated_now;
}

# so that we can update fields without 'Updated' being changed
sub set_no_update {
    my ($self, $field, $value) = @_;
    $self->{data}{$field} = $value;
}

sub set_inserted_now {
    my ($self) = @_;
    my $time = DateTime->now->iso8601;
    $self->{data}{Inserted} = $time;
    $self->{data}{Updated} = $time;
    $self->{Changed} = 1;
}

sub set_updated_now {
    my ($self) = @_;
    my $time = DateTime->now->iso8601;
    $self->{data}{Updated} = $time;
    $self->{Changed} = 1;
}

sub flag_as_updated {
    my ($self) = @_;
    $self->{Changed} = 1;
}

sub changed {
    my ($self) = @_;
    return $self->{Changed};
}

sub set_name {
    my ($self, $name) = @_;

    croak 'provide a name'
        unless defined $name;

    $self->{name} = $name;
}

sub name {
    my ($self) = @_;
    return $self->{name};
}

sub errors {
    my $self = shift;
    if( @_ ) {
        $self->{errors} = $_[0];
    }
    return $self->{errors};
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
