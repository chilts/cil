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

package CIL::Command::Track;

use strict;
use warnings;

use base qw(CIL::Command);

## ----------------------------------------------------------------------------

sub name { 'track' }

sub run {
    my ($self, $cil, undef, $issue_name) = @_;

    CIL::Utils->fatal("to use this feature the 'UseGit' option in your .cil file should be set")
        unless $cil->UseGit;

    my $issue = CIL::Utils->load_issue_fuzzy($cil, $issue_name);

    # add the issue to Git
    my $issue_dir = $cil->IssueDir();
    my @files;
    push @files, "$issue_dir/i_" . $issue->name . '.cil';
    push @files, map { "$issue_dir/c_${_}.cil" } @{ $issue->CommentList };
    push @files, map { "$issue_dir/a_${_}.cil" } @{ $issue->AttachmentList };
    CIL::Utils->msg("git add @files");
}

1;
## ----------------------------------------------------------------------------
