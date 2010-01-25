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

package CIL::Command::Edit;

use strict;
use warnings;

use base qw(CIL::Command);

## ----------------------------------------------------------------------------

my $y = 'y';

## ----------------------------------------------------------------------------

sub name { 'edit' }

sub run {
    my ($self, $cil, $args, $issue_name) = @_;

    my $issue = CIL::Utils->load_issue_fuzzy( $cil, $issue_name );

    CIL::Utils->ensure_interactive();

    my $edit = $y;

    # keep going until we get a valid issue or we want to quit
    while ( $edit eq $y ) {
        # read in the new issue text
        my $fh = CIL::Utils->solicit( $issue->as_output );
        $issue = CIL::Issue->new_from_fh( $issue->name, $fh );

        # check if the issue is valid
        if ( $issue->is_valid($cil) ) {
            $edit = 'n';
        }
        else {
            CIL::Utils->msg($_) foreach @{ $issue->errors };
            $edit = CIL::Utils::ans('Would you like to re-edit (y/n): ');
        }
    }

    # if the issue is still invalid, they quit without correcting it
    return unless $issue->is_valid( $cil );

    # save it
    $issue->save($cil);

    if ( $cil->UseGit ) {
        # if we want to add or commit this issue
        if ( $args->{add} or $args->{commit} ) {
            $cil->git->add( $cil, $issue );
        }

        # if we want to commit this issue
        if ( $args->{commit} ) {
            $cil->git->commit( $cil, 'Issue Edited', $issue );
        }
    }

    CIL::Utils->display_issue($cil, $issue);
}

1;
## ----------------------------------------------------------------------------
