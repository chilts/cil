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

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(CreatedBy Inserted Updated Description));

# override Class::Accessor's set
sub set {
    my ($self, $key, $value) = @_;
    croak "provide a key name" unless defined $key;

    my $orig = $self->get($key);

    # get out if both are defined and they're the same
    if ( defined $orig and defined $value ) {
        return if $orig eq $value
    }

    # get out if neither are defined
    if ( !defined $orig and !defined $value ) {
        return;
    }

    # since we're actually changing the key, say we updated something
    $self->{data}{$key} = $value;
    $self->updated;
}

sub set_no_update {
    my ($self, $key, $value) = @_;
    croak "provide a key name" unless defined $key;
    $self->{data}{$key} = $value;
}

# override Class::Accessor's get
sub get {
    my ($self, $key) = @_;
    $self->{data}{$key};
}

sub inserted {
    my ($self) = @_;
    my $time = time;
    $self->{data}{Inserted} = $time;
    $self->{data}{Updated} = $time;
    $self->{Changed} = '1';
}

sub updated {
    my ($self) = @_;
    my $time = time;
    $self->{data}{Updated} = $time;
    $self->{Changed} = '1';
}

sub changed {
    my ($self) = @_;
    return $self->{Changed};
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
