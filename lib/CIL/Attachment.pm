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

package CIL::Attachment;

use strict;
use warnings;
use Carp;

use MIME::Base64;

use base qw(CIL::Base);

# fields specific to Attachment
__PACKAGE__->mk_accessors(qw(Issue Filename Size File));

# all fields
my @FIELDS = ( qw(Issue Filename Size CreatedBy Inserted Updated File) );

## ----------------------------------------------------------------------------

sub new {
    my ($proto, $name) = @_;

    croak 'please provide an attachment name'
        unless defined $name;

    my $class = ref $proto || $proto;
    my $self = {};
    bless $self, $class;

    $self->set_name( $name );
    $self->{data}    = {
        Issue       => '',
        Filename    => '',
        Size        => '',
        CreatedBy   => '',
        Inserted    => '',
        Updated     => '',
        File        => '',
    };
    $self->{Changed} = 0;

    $self->set_inserted_now;

    return $self;
}

sub set_file_contents {
    my ($self, $contents) = @_;

    # $contents will be binary
    $self->{data}{File} = encode_base64( $contents );
}

sub as_binary {
    my ($self) = @_;

    return decode_base64( $self->{data}{File} );
}

sub prefix {
    return 'a';
}

sub type {
    return 'Attachment';
}

sub fields {
    return \@FIELDS;
}

sub array_fields {
    return {};
}

sub last_field {
    return 'File';
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
