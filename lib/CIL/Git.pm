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

package CIL::Git;

use strict;
use warnings;
use Carp;
use List::Util qw(reduce);
use Git;

use base qw(Class::Accessor);

sub git {
    my $self = shift;
    $self->{git} ||= Git->repository;
}

sub glob_rev {
    my ($self, $rev, $path) = @_;

    # only support globbing the last element
    my ($dir, $pattern) = $path =~ m{^([^\*]*/)([^/]*)$}
        or croak "unsupported pattern '$path'";
    $pattern =~ s{([\\\.])}{\\$1}g;
    $pattern =~ s{\*}{.*}g;
    my @match;
    $DB::single = 1;
    for ( $self->git->command("ls-tree", $rev, $dir) ) {
        chomp;
        my ($blobid, $path) = m{([0-9a-f]{40})\s+(.*)} or die;
        if ( $path =~ m{^\Q$dir\E$pattern$} ) {
            push @match, $path;
        }
    }
    @match;
}

sub file_exists {
    my ($self, $rev, $path) = @_;

    my $output = eval { $self->git->command("cat-file", "-t", "$rev:$path") };
    return ( $output && $output =~ /blob/ );
}

sub dir_exists {
    my ($self, $rev, $path) = @_;

    my $output = eval { $self->git->command("cat-file", "-t", "$rev:$path") };
    return ( $output && $output =~ /tree/ );
}

sub get_fh {
    my ($self, $rev, $path) = @_;
    $self->git->command_output_pipe("cat-file", "blob", "$rev:$path");
}

sub UserName {
    return $_[0]->git->config( 'user.name' );
}

sub UserEmail {
    return $_[0]->git->config( 'user.email' );
}

sub branches {
    my ($self) = @_;
    return $self->git->command('branch');
}

sub switch_to_branch {
    my ($self, $branch_name) = @_;
    $self->git->command('checkout', $branch_name);
}

sub create_branch {
    my ($self, $branch_name) = @_;
    $self->git->command('checkout', '-b', $branch_name);
}

sub add {
    my ($self, $cil, @entities) = @_;

    my @filenames;
    foreach my $entity ( @entities ) {
        my $filename = $entity->filename($cil, $entity->name());
        push @filenames, $filename;
    }
    return $self->git->command('add', @filenames);
}

sub commit {
    my ($self, $cil, $message, @entities) = @_;

    my @filenames;
    foreach my $entity ( @entities ) {
        my $filename = $entity->filename($cil, $entity->name());
        push @filenames, $filename;
    }

    $message = 'cil-' . $entities[0]->name . ": $message";
    return $self->git->command('commit', '-m', $message, @filenames);
}

sub commit_multiple {
    my ($self, $cil, $message, @entities) = @_;

    my @filenames;
    foreach my $entity ( @entities ) {
        my $filename = $entity->filename($cil, $entity->name());
        push @filenames, $filename;
    }

    my $commit_list_string = reduce { $a . $b } map { "* cil-" . $_->name . "\n" } @entities;

    return $self->git->command('commit', '-m', "$message\n\n$commit_list_string", @filenames);
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
