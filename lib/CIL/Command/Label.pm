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

package CIL::Command::Label;

use strict;
use warnings;

use base qw(CIL::Command);

## ----------------------------------------------------------------------------

sub name { 'label' }

sub run {
    my ($self, $cil, $args, $label, @issue_names) = @_;

    unless ( defined $label ) {
        CIL::Utils->fatal("provide a valid label to add to this issue");
    }

    my @issues;

    # for every issue
    foreach my $issue_name ( @issue_names ) {
        # firstly, read the issue in
        my $issue = CIL::Utils->load_issue_fuzzy( $cil, $issue_name );

        # decide whether we are adding or removing this label
        if ( $args->{remove} ) {
            $issue->remove_label( $label );
        }
        else {
            $issue->add_label( $label );
        }

        # save
        $issue->save($cil);

        if ( $cil->UseGit ) {
            # if we want to add or commit this issue
            if ( $args->{add} or $args->{commit} ) {
                $cil->git->add( $cil, $issue );
            }
        }

        push @issues, $issue;
    }

    if ( $cil->UseGit ) {
        # if we want to commit these issues
        if ( $args->{commit} ) {
            if ( $args->{remove} ) {
                $cil->git->commit_multiple( $cil, "Removed label '$label'", @issues );
            }
            else {
                $cil->git->commit_multiple( $cil, "Added label '$label'", @issues );
            }
        }
    }
}

1;
## ----------------------------------------------------------------------------
