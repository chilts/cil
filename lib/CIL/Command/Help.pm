## ----------------------------------------------------------------------------
# cil is a Command line Issue List
# Copyright (C) 2010 Andrew Chilton
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

package CIL::Command::Help;

use strict;
use warnings;

use base qw(CIL::Command);

## ----------------------------------------------------------------------------

sub name { 'help' }

sub run {
    my ($class) = @_;

   print <<"END_USAGE";
Usage: $0 COMMAND [options]

Commands:
   init    [--path=PATH]
   add
   summary [FILTERS...]
   list    [FILTERS...]
   show    ISSUE
   status  NEW_STATUS [ISSUES...]
   label   NEW_LABEL [ISSUES...]
   steal   ISSUE
   edit    ISSUE
   comment ISSUE
   attach  ISSUE FILENAME
   extract ATTACHMENT [--filename=FILENAME]
   am      EMAIL.TXT [--batch]
   track   ISSUE
   fsck

Filters:
   --status=?
   --is-open
   --is-closed
   --label=?
   --assigned-to=?
   --is-mine

See <http://www.chilts.org/project/cil/> for further information.
Report bugs to <andychilton\@gmail.com>.
END_USAGE
}

1;

## ----------------------------------------------------------------------------
