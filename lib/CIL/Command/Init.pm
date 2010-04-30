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

package CIL::Command::Init;

use strict;
use warnings;
use File::Slurp qw(read_file write_file);

use base qw(CIL::Command);

## ----------------------------------------------------------------------------

sub name { 'init' }

sub run {
    my ($self, $cil, $args) = @_;

    my $path = $args->{p} || '.'; # default path is right here

    # error if $path doesn't exist
    unless ( -d $path ) {
        CIL::Utils->fatal("path '$path' doesn't exist");
    }

    # error if issues/ already exists
    my $issues_dir = "$path/issues";
    if ( -d $issues_dir ) {
        CIL::Utils->fatal("issues directory '$issues_dir' already exists, not initialising issues");
    }

    # error if .cil already exists
    my $config = "$path/.cil";
    if ( -f $config ) {
        CIL::Utils->fatal("config file '$config' already exists, not initialising issues");
    }

    # try to create the issues/ dir
    unless ( mkdir $issues_dir ) {
        CIL::Utils->fatal("Couldn't create '$issues_dir' directory: $!");
    }

    # are we in a Git repository?
    my $use_git = 0;
    if ( -d '.git' ) {
        CIL::Utils->msg( 'git repository detected, setting to use it' );
        $use_git = 1;
    }

    # create a .cil file here also
    if ( $args->{bare} ) {
        unless ( touch $config ) {
            rmdir $issues_dir;
            CIL::Utils->fatal("couldn't create a '$config' file");
        }
    }
    else {
        # write a default .cil file
        write_file($config, <<"CONFIG");
UseGit: $use_git
StatusStrict: 1
StatusOpenList: New
StatusOpenList: InProgress
StatusClosedList: Finished
DefaultNewStatus: New
LabelStrict: 1
LabelAllowedList: Type-Enhancement
LabelAllowedList: Type-Defect
LabelAllowedList: Priority-High
LabelAllowedList: Priority-Medium
LabelAllowedList: Priority-Low
CONFIG
    }

    # add a README.txt so people know what this is about
    unless ( -f "$issues_dir/README.txt" ) {
        write_file("$issues_dir/README.txt", <<'README');
This directory is used by CIL to track issues and feature requests.

The home page for CIL is at http://www.chilts.org/project/cil/
README
    }

    # $path/issues/ and $path/.cil create correctly
    CIL::Utils->msg("initialised empty issue list inside '$path/'");
}

1;

## ----------------------------------------------------------------------------
