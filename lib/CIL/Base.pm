## ----------------------------------------------------------------------------
package CIL::Base;

use strict;
use warnings;
use Carp;
use DateTime;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(Description CreatedBy Inserted Updated));

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
