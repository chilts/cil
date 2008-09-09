package CIL::Command;

use strict;
use warnings;

sub name {
    my $self = shift;

    my $name = lc( ref $self || $self );

    $name =~ s/^CIL::Command:://i;

    return $name;
}


'end of package CIL::Command';
