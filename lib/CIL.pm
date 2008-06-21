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

package CIL;

use strict;
use warnings;
use File::Glob qw(:glob);

use base qw(Class::Singleton Class::Accessor);
__PACKAGE__->mk_accessors(qw(issue_dir));

my $defaults = {
    issue_dir => 'issues',
};

## ----------------------------------------------------------------------------

sub _new_instance {
    my ($proto) = @_;
    my $class = ref $proto || $proto;
    my $self = bless {}, $class;
    foreach my $key ( keys %$defaults ) {
        $self->$key( $defaults->{$key} ); 
    }
    return $self;
}

sub set_config {
    my ($self, $config) = @_;

    foreach my $key ( qw(issue_dir) ) {
        $self->$key( $config->{$key} )
            if defined $config->{$key};
    }
}

sub list_issues {
    my ($self) = @_;

    my $globpath = $self->issue_dir . "/i_*.cil";
    my @filenames = bsd_glob($globpath);

    my @issues;
    foreach my $filename ( sort @filenames ) {
        my ($name) = $filename =~ m{/i_(.*)\.cil$}xms;
        push @issues, {
            name => $name,
            filename => $filename,
        };
    }
    return \@issues;
}

sub get_issues {
    my ($self) = @_;

    my $issue_list = $self->list_issues();

    my @issues;
    foreach my $issue ( @$issue_list ) {
        push @issues, CIL::Issue->load( $issue->{name} );
    }
    return \@issues;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
