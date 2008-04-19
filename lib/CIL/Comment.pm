## ----------------------------------------------------------------------------
package CIL::Comment;

use strict;
use warnings;
use Config::IniFiles;

use base qw(CIL::Base);

## ----------------------------------------------------------------------------

sub new {
    my ($proto) = @_;
    my $class = ref $proto || $proto;
    my $self = {};
    $self->{data}    = {};
    $self->{Changed} = 0;
    bless $self, $class;
    $self->inserted;
    return $self;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
