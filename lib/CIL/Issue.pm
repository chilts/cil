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

package CIL::Issue;

use strict;
use warnings;
use Carp;
use Config::IniFiles;
use YAML qw(LoadFile DumpFile);

use CIL;
use CIL::Utils;

use base qw(CIL::Base);
__PACKAGE__->mk_accessors(qw(Summary Status AssignedTo Label Comment Attachment));

my @FIELDS = ( qw(Summary Status CreatedBy AssignedTo Label Comment Attachment Inserted Updated Description) );
my $cfg = {
    array => {
        Label      => 1,
        Comment    => 1,
        Attachment => 1,
    },
};

## ----------------------------------------------------------------------------

sub new {
    my ($proto, $name) = @_;

    croak 'please provide an issue name'
        unless defined $name;

    my $class = ref $proto || $proto;
    my $self = {};
    bless $self, $class;

    $self->set_name( $name );
    $self->{data}    = {
        Summary    => '',
        Status     => '',
        CreatedBy  => '',
        AssignedTo => '',
        Label      => [],
        Comment    => [],
        Attachment => [],
    };
    $self->{Changed} = 0;

    $self->flag_inserted;

    return $self;
}

sub new_from_data {
    my ($class, $name, $data) = @_;

    croak 'please provide an issue name'
        unless defined $name;

    # ToDo: check we have all the other correct fields

    # create the issue
    my $self = $class->new( $name );

    # save each field
    foreach my $field ( @FIELDS ) {
        next unless defined $data->{$field};

        # make it an array if it should be one
        if ( exists $cfg->{array}{$field} and ref $data->{$field} ne 'ARRAY' ) {
            $data->{$field} = [ $data->{$field} ];
        }

        # modify the data directly, otherwise Updated will kick in
        $self->set_no_update($field, $data->{$field});
    }
    $self->set_no_update('Changed', 0);

    return $self;
}

sub new_from_fh {
    my ($class, $name, $fh) = @_;

    croak 'please provide an issue name'
        unless defined $name;

    my $data = CIL::Utils->parse_from_fh( $fh, 'Description' );
    return $class->new_from_data( $name, $data );
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

sub add_label {
    my ($self, $label) = @_;

    croak 'provide a label when adding one'
        unless defined $label;

    push @{$self->{data}{Label}}, $label;
}

sub add_comment {
    my ($self, $comment) = @_;

    croak "can only add comments of type CIL::Comment"
        unless ref $comment eq 'CIL::Comment';

    push @{$self->{data}{Comment}}, $comment->name;
}

sub add_attachment {
    my ($self, $attachment) = @_;

    croak "can only add comments of type CIL::Attachment"
        unless ref $attachment eq 'CIL::Attachment';

    push @{$self->{data}{Attachment}}, $attachment->name;
}

sub load {
    my ($class, $name) = @_;

    croak 'provide an issue name to load'
        unless defined $name;

    my $filename = CIL->instance->issue_dir . "/i_$name.cil";

    croak "filename '$filename' does no exist"
        unless -f $filename;

    my $data = CIL::Utils->parse_cil_file($filename, 'Description');
    my $issue = CIL::Issue->new_from_data( $name, $data );
    return $issue;
}

sub as_output {
    my ($self) = @_;
    return CIL::Utils->format_data_as_output( $self->{data}, @FIELDS );
}

sub save {
    my ($self) = @_;
    my $name = $self->name;
    my $filename = CIL->instance->issue_dir . "/i_$name.cil";
    CIL::Utils->write_cil_file( $filename, $self->{data}, @FIELDS );
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
