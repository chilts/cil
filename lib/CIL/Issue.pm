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
        Summary     => '',
        Status      => '',
        CreatedBy   => '',
        AssignedTo  => '',
        Inserted    => '',
        Updated     => '',
        Label       => [],
        Comment     => [],
        Attachment  => [],
        Description => '',
    };
    $self->{Changed} = 0;

    $self->set_inserted_now;

    return $self;
}

sub prefix {
    return 'i';
}

sub fields {
    return \@FIELDS;
}

sub array_fields {
    return $cfg->{array};
}

sub add_label {
    my ($self, $label) = @_;

    croak 'provide a label when adding one'
        unless defined $label;

    push @{$self->{data}{Label}}, $label;
    $self->flag_as_updated();
}

sub add_comment {
    my ($self, $comment) = @_;

    croak "can only add comments of type CIL::Comment"
        unless $comment->isa( 'CIL::Comment' );

    # add the comment name and set this issue's updated time
    push @{$self->{data}{Comment}}, $comment->name;
    $self->Updated( $comment->Updated );
    $self->flag_as_updated();
}

sub add_attachment {
    my ($self, $attachment) = @_;

    croak "can only add comments of type CIL::Attachment"
        unless ref $attachment eq 'CIL::Attachment';

    push @{$self->{data}{Attachment}}, $attachment->name;
}

sub as_output {
    my ($self) = @_;
    return CIL::Utils->format_data_as_output( $self->{data}, @FIELDS );
}

sub Comments {
    my ($self) = @_;
    return $self->{Comment};
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
