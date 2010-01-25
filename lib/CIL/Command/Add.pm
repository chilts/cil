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

package CIL::Command::Add;

use strict;
use warnings;

use base qw(CIL::Command);

## ----------------------------------------------------------------------------

sub name { 'add' }

sub run {
    my ($self, $cil, $args, @argv) = @_;

    CIL::Utils->ensure_interactive();

    my $user = CIL::Utils->user($cil);

    my $issue = CIL::Issue->new('tmpname');
    $issue->Summary( join ' ', @argv );
    $issue->Status($cil->DefaultNewStatus);
    $issue->CreatedBy( $user );
    $issue->AssignedTo( $user )
        if ( $args->{mine} or $cil->AutoAssignSelf );
    $issue->Description("Description ...");

    $issue = CIL::Utils->add_issue_loop($cil, undef, $issue);

    if ( $cil->UseGit ) {
        # if we want to add or commit this issue
        if ( $args->{add} or $args->{commit} ) {
            $cil->git->add( $cil, $issue );
        }

        # if we want to commit this issue
        if ( $args->{commit} ) {
            $cil->git->commit( $cil, 'New Issue', $issue );
        }
    }
}

1;

## ----------------------------------------------------------------------------
