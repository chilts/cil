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

package CIL::Command::Comment;

use strict;
use warnings;

use base qw(CIL::Command);

## ----------------------------------------------------------------------------

sub name { 'comment' }

sub run {
    my ($self, $cil, $args, $issue_name) = @_;

    my $issue = CIL::Utils->load_issue_fuzzy( $cil, $issue_name );

    CIL::Utils->ensure_interactive();

    # create the new comment
    my $comment = CIL::Comment->new('tmpname');
    $comment->Issue( $issue->name );
    $comment->CreatedBy( CIL::Utils->user($cil) );
    $comment->Description("Description ...");

    $comment = CIL::Utils->add_comment_loop($cil, undef, $issue, $comment);

    if ( $cil->UseGit ) {
        # if we want to add or commit this comment
        if ( $args->{add} or $args->{commit} ) {
            $cil->git->add( $cil, $issue );
            $cil->git->add( $cil, $comment );
        }

        # if we want to commit this comment
        if ( $args->{commit} ) {
            $cil->git->commit( $cil, 'New Comment', $issue, $comment );
        }
    }
}

1;
## ----------------------------------------------------------------------------
