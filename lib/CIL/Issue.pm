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
use Date::Simple;

use base qw(CIL::Base);

# fields specific to Issue
__PACKAGE__->mk_accessors(qw(Summary Status AssignedTo DueDate DependsOn Precedes Label Comment Attachment Description));

my @FIELDS = ( qw(Summary Status CreatedBy AssignedTo DueDate DependsOn Precedes Label Comment Attachment Inserted Updated Description) );
my $cfg = {
    array => {
        Label      => 1,
        Comment    => 1,
        Attachment => 1,
        DependsOn  => 1,
        Precedes   => 1,
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
        DueDate     => '',
        Inserted    => '',
        Updated     => '',
        Label       => [],
        Comment     => [],
        Attachment  => [],
        DependsOn   => [],
        Precedes    => [],
        Description => '',
    };
    $self->{Changed} = 0;

    $self->set_inserted_now;

    return $self;
}

sub prefix {
    return 'i';
}

sub type {
    return 'Issue';
}

sub fields {
    return \@FIELDS;
}

sub array_fields {
    return $cfg->{array};
}

sub last_field {
    return 'Description';
}

sub is_valid {
    my ($self, $cil) = @_;

    my @errors;

    # issues should have a Summary
    unless ( defined $self->Summary and length $self->Summary ) {
        push @errors, 'Issue does not have a summary';
    }

    # see if we only allow certain Statuses
    if ( $cil->StatusStrict ) {
        unless ( exists $cil->StatusAllowed()->{$self->Status} ) {
            push @errors, "StatusStrict is turned on but this issue has an invalid status '" . $self->Status . "'";
        }
    }

    # see if we only allow certain Labels
    if ( $cil->LabelStrict ) {
        my @labels = @{$self->LabelList};
        foreach my $label ( @labels ) {
            unless ( exists $cil->LabelAllowed()->{$label} ) {
                push @errors, "LabelStrict is turned on but this issue has an invalid label '$label'";
            }
        }
    }

    # check that the DueDate is valid
    if ( $self->DueDate ) {
        unless ( Date::Simple->new($self->DueDate) ) {
            push @errors, "DueDate is not a valid date";
        }
    }

    $self->errors( \@errors );
    return @errors ? 0 : 1;
}

sub add_label {
    my ($self, $label) = @_;

    croak 'provide a label when adding one'
        unless defined $label;

    # return if we already have this label
    return if grep { $_ eq $label } @{$self->{data}{Label}};

    push @{$self->{data}{Label}}, $label;
    $self->set_updated_now();
}

sub remove_label {
    my ($self, $label) = @_;

    croak 'provide a label when removing one'
        unless defined $label;

    # remove this label
    @{$self->{data}{Label}} = grep { $_ ne $label } @{$self->{data}{Label}};
    $self->set_updated_now();
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

    croak "can only add attachments of type CIL::Attachment"
        unless $attachment->isa( 'CIL::Attachment' );

    # add the attachment name and set this issue's updated time
    push @{$self->{data}{Attachment}}, $attachment->name;
    $self->Updated( $attachment->Updated );
    $self->flag_as_updated();
}

sub add_depends_on {
    my ($self, $depends) = @_;

    croak 'provide an issue name when adding a depends'
        unless defined $depends;

    # return if we already have this depends
    return if grep { $_ eq $depends } @{$self->{data}{DependsOn}};

    push @{$self->{data}{DependsOn}}, $depends;
    $self->set_updated_now();
}

sub add_precedes {
    my ($self, $precedes) = @_;

    croak 'provide an issue name when adding a precedes'
        unless defined $precedes;

    # return if we already have this precedes
    return if grep { $_ eq $precedes } @{$self->{data}{Precedes}};

    push @{$self->{data}{Precedes}}, $precedes;
    $self->set_updated_now();
}

sub LabelList {
    my ($self) = @_;
    return $self->{data}{Label};
}

sub CommentList {
    my ($self) = @_;
    return $self->{data}{Comment};
}

sub AttachmentList {
    my ($self) = @_;
    return $self->{data}{Attachment};
}

sub DependsOnList {
    my ($self) = @_;
    return $self->{data}{DependsOn};
}

sub PrecedesList {
    my ($self) = @_;
    return $self->{data}{Precedes};
}

sub is_open {
    my ($self, $cil) = @_;

    # check against the list of Open Statuses
    my $open = $cil->StatusOpen();
    return exists $open->{$self->Status};
}

sub is_closed {
    my ($self, $cil) = @_;

    # check against the list of Closed Statuses
    my $closed = $cil->StatusClosed();
    return exists $closed->{$self->Status};
}

sub assigned_to_email {
    my ($self) = @_;

    return CIL::Utils->extract_email_address( $self->AssignedTo );
}

sub created_by_email {
    my ($self) = @_;

    return CIL::Utils->extract_email_address( $self->CreatedBy );
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
