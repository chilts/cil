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

package CIL::Command::Attach;

use strict;
use warnings;

use base qw(CIL::Command);
use File::Basename;
use File::Slurp;
use Digest::MD5 qw(md5_hex);

## ----------------------------------------------------------------------------

sub name { 'attach' }

sub run {
    my ($self, $cil, undef, $issue_name, $filename) = @_;

    my $issue = CIL::Utils->load_issue_fuzzy( $cil, $issue_name );

    # check to see if the file exists
    unless ( -r $filename ) {
        $cil->fatal("couldn't read file '$filename'");
    }

    my $basename = basename( $filename );
    my $user = CIL::Utils->user($cil);

    my $add_attachment_text = <<"EOF";
Filename    : $basename
CreatedBy   : $user

File goes here ... this will be overwritten.
EOF

    # read in the new issue text
    CIL::Utils->ensure_interactive();
    my $fh = CIL::Utils->solicit( $add_attachment_text );

    my $attachment = CIL::Attachment->new_from_fh( 'tmp', $fh );
    unless ( defined $attachment ) {
        $cil->fatal("could not create new attachment");
    }

    # now add the file itself
    my $contents = read_file( $filename );
    $attachment->set_file_contents( $contents );

    # set the size
    my ($size) = (stat($filename))[7];
    $attachment->Size( $size );

    # we've got the attachment, so let's name it
    my $unique_str = time . $attachment->Inserted . $attachment->File;
    $attachment->set_name( substr(md5_hex($unique_str), 0, 8) );

    # finally, tell it who it's parent is and then save
    $attachment->Issue( $issue->name );
    $attachment->save($cil);

    # add the comment to the issue, update it's timestamp and save it out
    $issue->add_attachment( $attachment );
    $issue->save($cil);
    CIL::Utils->display_issue_full($cil, $issue);
}

1;
## ----------------------------------------------------------------------------
