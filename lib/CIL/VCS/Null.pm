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

package CIL::VCS::Null;

use strict;
use warnings;
use Carp;

use base qw(CIL::VCS::Factory);

foreach my $method_name ( qw(post_add) ) {
    no strict 'refs';
    *{"CIL::VCS::Null::$method_name"} = sub {};
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
