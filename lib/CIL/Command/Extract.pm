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

package CIL::Command::Extract;

use strict;
use warnings;

use base qw(CIL::Command);
use File::Slurp qw(write_file);

## ----------------------------------------------------------------------------

sub name { 'extract' }

sub run {
    my ($self, $cil, $args, $attachment_name) = @_;

    my $attachment = CIL::Utils->load_attachment_fuzzy($cil, $attachment_name);

    my $filename = $args->{f} || $attachment->Filename();
    write_file( $filename, $attachment->as_binary );
}

1;

## ----------------------------------------------------------------------------
