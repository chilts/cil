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

package CIL::Command::ListLabels;

use strict;
use warnings;

use base qw(CIL::Command);

## ----------------------------------------------------------------------------

sub name { 'list-labels' }

sub run {
    my ($self, $cil, $args) = @_;

    CIL::Utils->check_paths($cil);

    # find all the issues
    my $issues = $cil->get_issues();
    $issues = CIL::Utils->filter_issues( $cil, $issues, $args );
    unless ( @$issues ) {
        CIL::Utils->msg('no issues found');
        return;
    }

    # loop through the issues and save all the labels they have
    use Data::Dumper;
    my %labels;
    foreach my $issue ( @$issues ) {
        # print Dumper($issue->LabelList), "\n";
        my $labels = $issue->LabelList;
        foreach my $label ( @$labels ) {
            $labels{$label}++;
        }
    }

    foreach my $label ( sort keys %labels ) {
        print "$label\n";
    }
}

1;

## ----------------------------------------------------------------------------
