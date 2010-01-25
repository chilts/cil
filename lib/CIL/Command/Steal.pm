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

package CIL::Command::Steal;

use strict;
use warnings;

use base qw(CIL::Command);

## ----------------------------------------------------------------------------

sub name { 'steal' }

sub run {
    my ($self, $cil, $args, $issue_name) = @_;

    # firstly, read the issue in
    my $issue = CIL::Utils->load_issue_fuzzy( $cil, $issue_name );

    # set the AssignedTo for this issue to you (because you're stealing it)
    $issue->AssignedTo( CIL::Utils->user($cil) );
    $issue->save($cil);

    if ( $cil->UseGit ) {
        # if we want to add or commit this issue
        if ( $args->{add} or $args->{commit} ) {
            $cil->git->add( $cil, $issue );
        }

        # if we want to commit this issue
        if ( $args->{commit} ) {
            $cil->git->commit( $cil, 'Issue Stolen', $issue );
        }
    }

    CIL::Utils->display_issue_full($cil, $issue);
}

1;
## ----------------------------------------------------------------------------
