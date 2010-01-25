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

package CIL::Command::DependsOn;

use strict;
use warnings;

use base qw(CIL::Command);

## ----------------------------------------------------------------------------

sub name { 'depends-on' }

sub run {
    my ($self, $cil, $args, $issue_name, $depends_name) = @_;

    my $issue = CIL::Utils->load_issue_fuzzy($cil, $issue_name);
    my $depends = CIL::Utils->load_issue_fuzzy($cil, $depends_name);

    $issue->add_depends_on( $depends->name );
    $depends->add_precedes( $issue->name );

    $issue->save($cil);
    $depends->save($cil);

    if ( $cil->UseGit ) {
        # if we want to add or commit this change
        if ( $args->{add} or $args->{commit} ) {
            $cil->git->add( $cil, $issue );
            $cil->git->add( $cil, $depends );
        }

        # if we want to commit this change
        if ( $args->{commit} ) {
            my $message = 'Issue ' . $issue->name . ' has a new dependent ' . $depends->name;
            $cil->git->commit_multiple( $cil, $message, $issue, $depends );
        }
    }
}

1;
## ----------------------------------------------------------------------------
