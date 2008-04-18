## ----------------------------------------------------------------------------
package CIL::Base;

use strict;
use warnings;
use DateTime;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(Description CreatedBy Inserted Updated));

sub inserted {
    my ($self) = @_;
    $self->{Inserted} = DateTime->new()->iso8601;
}

sub updated {
    my ($self) = @_;
    $self->{Updated} = DateTime->new()->iso8601;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
