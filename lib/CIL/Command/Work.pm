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

package CIL::Command::Work;

use strict;
use warnings;
use File::Slurp qw(read_file write_file);

use base qw(CIL::Command);

## ----------------------------------------------------------------------------

sub name { 'work' }

sub run {
    my ($self, $cil, $args, $issue_name) = @_;

    CIL::Utils->fatal("to use this feature the 'UseGit' option in your .cil file should be set")
        unless $cil->UseGit;

    # firstly, read the issue in
    my $issue = CIL::Utils->load_issue_fuzzy( $cil, $issue_name );

    # right, got it's name, let's see if there is a branch for it
    my @branches = $cil->git->branches();
    my $branch = {};
    foreach ( @branches ) {
        $branch->{substr $_, 2} = 1;
    }
    if ( exists $branch->{$issue->name} ) {
        $cil->git->switch_to_branch( $issue->name );
    }
    else {
        $cil->git->create_branch( $issue->name );
    }

    # now that we've switched branches, load the issue in again (just in case)
    $issue = CIL::Utils->load_issue_fuzzy( $cil, $issue_name );
    $issue->Status( 'InProgress' );
    $issue->save($cil);
}

1;

## ----------------------------------------------------------------------------
