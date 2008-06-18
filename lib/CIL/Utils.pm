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

package CIL::Utils;

use strict;
use warnings;
use File::Slurp;

sub parse_cil_file {
    my ($class, $filename, $last_field) = @_;

    my @lines = read_file($filename);
    return unless @lines;

    return $class->parse_from_lines( $last_field, @lines );
}

sub parse_from_fh {
    my ($class, $fh, $last_field) = @_;

    my @lines = <$fh>;
    return unless @lines;

    return $class->parse_from_lines( $last_field, @lines );
}

sub parse_from_lines {
    my ($class, $last_field, @lines) = @_;
    return unless @lines;
    chomp @lines;

    my $data = {};

    # read all the initial fields
    while ( my $line = shift @lines ) {
        my ($key, $value) = split(/\s*:\s*/, $line, 2);

        if ( defined $data->{$key} ) {
            unless ( ref $data->{$key} eq 'ARRAY' ) {
                $data->{$key} = [ $data->{$key} ];
            };
            push @{$data->{$key}}, $value;
        }
        else {
            $data->{$key} = $value;
        }
    }
    
    # now read everything that's left into the $last_field field
    $data->{$last_field} = join("\n", @lines);

    return $data;
}

sub write_cil_file {
    my ($class, $filename, $data, @fields) = @_;

    my $last_field = pop @fields;

    my @lines;

    foreach my $field ( @fields ) {
        next if $field eq $last_field;

        if ( ref $data->{$field} eq 'ARRAY' ) {
            foreach ( sort @{$data->{$field}} ) {
                push @lines, "$field: $_\n";
            }
        }
        else {
            push @lines, "$field: $data->{$field}\n";
        }
    }

    push @lines, "\n";
    push @lines, $data->{$last_field}, "\n";

    write_file($filename, \@lines);
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
