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
use Carp;
use File::Slurp;
use File::Temp qw(tempfile);
use POSIX qw(getpgrp tcgetpgrp);
use Fcntl qw(:DEFAULT :flock);

## ----------------------------------------------------------------------------
# setup some globals

my $editor = $ENV{EDITOR} || 'vi';

## ----------------------------------------------------------------------------

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
    
    # now read everything that's left into the $last_field field (if there is one)
    $data->{$last_field} = join("\n", @lines)
        if defined $last_field;

    return $data;
}

sub format_data_as_output {
    my ($class, $data, @fields) = @_;

    # we format the last field differently, so pop it off now
    my $last_field = pop @fields;

    my @lines;
    foreach my $field ( @fields ) {
        next if $field eq $last_field;

        if ( ref $data->{$field} eq 'ARRAY' ) {
            # don't output this field if there is nothing in it
            next unless @{$data->{$field}};

            foreach ( sort @{$data->{$field}} ) {
                push @lines, "$field: $_\n";
            }
        }
        else {
            push @lines, "$field: $data->{$field}\n";
        }
    }

    # finally, output the last field on it's own
    push @lines, "\n";
    push @lines, $data->{$last_field}, "\n";

    return \@lines;
}

sub write_cil_file {
    my ($class, $filename, $data, @fields) = @_;

    # get the output format
    my $lines = $class->format_data_as_output($data, @fields);

    # ... and save
    write_file($filename, $lines);
}

# this method based on Term::CallEditor(v0.11)'s solicit method
# original: Copyright 2004 by Jeremy Mates
# copied under the terms of the GPL
sub solicit {
    my ($class, $message) = @_;

    $message = join('', @$message) if ref $message eq 'ARRAY';

    # when calling this, assume we're already interactive

    File::Temp->safe_level(File::Temp::HIGH);
    my ( $fh, $filename ) = tempfile( UNLINK => 1 );

    # since File::Temp returns both, check both
    unless ( $fh and $filename ) {
        croak "couldn't create temporary file";
    }

    select( ( select($fh), $|++ )[0] );
    print $fh $message;

    # need to unlock for external editor
    flock $fh, LOCK_UN;

    # run the editor
    my $status = system($editor, $filename);

    # check its return value
    if ( $status != 0 ) {
        croak $status != -1
            ? "external editor ($editor) failed: $?"
            : "could not launch ($editor) program: $!";
    }

    unless ( seek $fh, 0, 0 ) {
        croak "could not seek on temp file: errno=$!";
    }

    return $fh;
}

# this method based on Recipe 15.2
sub ensure_interactive {
    my $tty;
    open($tty, "/dev/tty")
        or croak "program not running interactively (can't open /dev/tty): $!";

    my $tpgrp = tcgetpgrp( fileno($tty) );
    my $pgrp = getpgrp();
    close $tty;

    unless ( $tpgrp == $pgrp ) {
        croak "can't get exclusive control of tty: tpgrp=$tpgrp, pgrp=$pgrp";
    }

    # if we are here, then we have ensured what we wanted
    return;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
