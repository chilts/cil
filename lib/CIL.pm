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

package CIL;

use strict;
use warnings;
use File::Glob qw(:glob);

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(issue_dir));

my $defaults = {
    issue_dir => 'issues',
};

## ----------------------------------------------------------------------------

sub new {
    my ($proto, $cfg) = @_;

    $cfg ||= {};

    my $class = ref $proto || $proto;
    my $self = bless {}, $class;

    # save the settings for various bits of info
    foreach my $key ( keys %$defaults ) {
        # if we have been passed it in, use it, else use the default
        $self->$key( $cfg->{$key} || $defaults->{$key} ); 
    }
    return $self;
}

sub list_issues {
    my ($self) = @_;

    my $globpath = $self->issue_dir . "/i_*.cil";
    my @filenames = bsd_glob($globpath);

    my @issues;
    foreach my $filename ( sort @filenames ) {
        my ($name) = $filename =~ m{/i_(.*)\.cil$}xms;
        push @issues, {
            name => $name,
            filename => $filename,
        };
    }
    return \@issues;
}

sub get_issues {
    my ($self) = @_;

    my $issue_list = $self->list_issues();

    my @issues;
    foreach my $issue ( @$issue_list ) {
        push @issues, CIL::Issue->new_from_name( $self, $issue->{name} );
    }
    return \@issues;
}

sub get_comments_for {
    my ($self, $issue) = @_;

    my @comments;
    foreach my $comment_name ( @{$issue->Comments} ) {
        my $comment = CIL::Comment->new_from_name( $self, $comment_name );
        push @comments, $comment;
    }

    # sort them in cronological order
    @comments = sort { $a->Inserted cmp $b->Inserted } @comments;

    return \@comments;
}

sub get_attachments_for {
    my ($self, $issue) = @_;

    my @attachments;
    foreach my $attachment_name ( @{$issue->Attachments} ) {
        my $attachment = CIL::Attachment->new_from_name( $self, $attachment_name );
        push @attachments, $attachment;
    }

    # sort them in cronological order
    @attachments = sort { $a->Inserted cmp $b->Inserted } @attachments;

    return \@attachments;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
