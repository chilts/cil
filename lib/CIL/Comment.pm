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

package CIL::Comment;

use strict;
use warnings;
use Carp;

use base qw(CIL::Base);

# fields specific to Comment
__PACKAGE__->mk_accessors(qw(Issue Description));

my @FIELDS = ( qw(Issue CreatedBy Inserted Updated Description) );

## ----------------------------------------------------------------------------

sub new {
    my ($proto, $name) = @_;

    croak 'please provide a comment name'
        unless defined $name;

    my $class = ref $proto || $proto;
    my $self = {};
    bless $self, $class;

    $self->set_name( $name );
    $self->{data}    = {
        Issue       => '',
        CreatedBy   => '',
        Inserted    => '',
        Updated     => '',
        Description => '',
    };
    $self->{Changed} = 0;

    $self->set_inserted_now;

    return $self;
}

sub prefix {
    return 'c';
}

sub type {
    return 'Comment';
}

sub fields {
    return \@FIELDS;
}

sub array_fields {
    return {};
}

sub last_field {
    return 'Description';
}

sub is_valid {
    # ToDo:
    # * check that the issue is valid
    # * Inserted and Updated are valid
    # * Description has something in it
    return 1;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
