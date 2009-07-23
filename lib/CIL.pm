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
use Carp qw(croak confess);
use File::Glob qw(:glob);

use vars qw( $VERSION );
$VERSION = '0.5.1';

use Module::Pluggable 
        sub_name    => 'commands',
        search_path => [ 'CIL::Command' ],
        require     => 1;

use CIL::VCS::Factory;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(
    IssueDir
    StatusStrict StatusAllowed StatusOpen StatusClosed
    LabelStrict LabelAllowed
    DefaultNewStatus
    VCS
    vcs hook
    vcs_revision
));

my $defaults = {
    IssueDir         => 'issues', # the dir to save the issues in
    StatusStrict     => 0,        # whether to complain if a status is invalid
    LabelStrict      => 0,        # whether to complain if a label is invalid
    DefaultNewStatus => 'New',    # What Status to use for new issues by default
    VCS              => 'Null',   # don't do anything for VCS hooks
};

my @config_hashes = qw(StatusAllowed StatusOpen StatusClosed LabelAllowed);

my $defaults_user = {
    UserName  => 'Name',
    UserEmail => 'me@example.com',
};

my $allowed = {
    vcs => {
        'Git' => 1,
    },
    hook => {
        'issue_post_save' => 1,
    },
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

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub command_names {
    return map { $_->name } $_[0]->commands;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub list_entities {
    my ($self, $prefix, $base) = @_;

    $base = '' unless defined $base;

    my $globpath = $self->IssueDir . "/${prefix}_${base}*.cil";
    my @filenames;
    if ( $self->vcs_revision ) {
        @filenames = $self->vcs->glob_rev($self->vcs_revision, $globpath);
    }
    else {
        @filenames = bsd_glob($globpath);
    }

    my @entities;
    foreach my $filename ( sort @filenames ) {
        my ($name) = $filename =~ m{/${prefix}_(.*)\.cil$}xms;
        push @entities, {
            name => $name,
            filename => $filename,
        };
    }
    return \@entities;
}

sub list_issues {
    my ($self) = @_;

    return $self->list_entities('i');
}

sub list_comments {
    my ($self) = @_;

    return $self->list_entities('c');
}

sub list_attachments {
    my ($self) = @_;

    return $self->list_entities('a');
}

sub list_issues_fuzzy {
    my ($self, $partial_name) = @_;

    return $self->list_entities('i', $partial_name);
}

sub list_comments_fuzzy {
    my ($self, $partial_name) = @_;

    return $self->list_entities('c', $partial_name);
}

sub list_attachments_fuzzy {
    my ($self, $partial_name) = @_;

    return $self->list_entities('a', $partial_name);
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

sub get_comments {
    my ($self) = @_;

    my $comment_list = $self->list_comments();

    my @comments;
    foreach my $comment ( @$comment_list ) {
        push @comments, CIL::Comment->new_from_name( $self, $comment->{name} );
    }
    return \@comments;
}

sub get_attachments {
    my ($self) = @_;

    my $attachment_list = $self->list_attachments();

    my @attachments;
    foreach my $attachment ( @$attachment_list ) {
        push @attachments, CIL::Attachment->new_from_name( $self, $attachment->{name} );
    }
    return \@attachments;
}

sub get_comments_for {
    my ($self, $issue) = @_;

    my @comments;
    foreach my $comment_name ( @{$issue->CommentList} ) {
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
    foreach my $attachment_name ( @{$issue->AttachmentList} ) {
        my $attachment = CIL::Attachment->new_from_name( $self, $attachment_name );
        push @attachments, $attachment;
    }

    # sort them in cronological order
    @attachments = sort { $a->Inserted cmp $b->Inserted } @attachments;

    return \@attachments;
}

sub read_config_user {
    my ($self) = @_;

    my $filename = "$ENV{HOME}/.cilrc";

    my $cfg;
    if ( -f $filename ) {
        $cfg = CIL::Utils->parse_cil_file( $filename );
    }

    # set each config to be either the user defined one or the default
    foreach ( qw() ) { # nothing yet
        $self->$_( $cfg->{$_} || $defaults_user->{$_} );
    }
}

sub read_config_file {
    my ( $self ) = @_;

    my $filename = '.cil';

    # since we might not have a '.cil' file yet (in the case where we're calling 'init',
    # then we should just return whatever the defaults are
    my $cfg;
    if ( -f $filename ) {
        $cfg = CIL::Utils->parse_cil_file( $filename );
    }
    else {
        $cfg = $defaults;
    }

    # set some defaults if we don't have any of these
    %$cfg = (%$defaults, %$cfg);

    # for some things, make a hash out of them
    foreach my $hash_name ( @config_hashes ) {
        # if we have nothing in the cfg hash already, set it to empty and move on
        unless ( exists $cfg->{"${hash_name}List"} ) {
            $cfg->{$hash_name} = {};
            next;
        }

        # if we only have a single item, turn it into an array first
        my $key = "${hash_name}List";
        $cfg->{$key} = [ $cfg->{$key} ] unless ref $cfg->{$key} eq 'ARRAY';

        # loop through all the items making up the hash
        my $h = {};
        $h->{$_} = 1
            for @{ $cfg->{$key} };
        $cfg->{$hash_name} = $h;
        undef $cfg->{$key};
    }

    # set each config item
    $self->IssueDir( $cfg->{IssueDir} );

    $self->StatusStrict( $cfg->{StatusStrict} );
    $self->StatusAllowed( $cfg->{StatusAllowed} );
    $self->StatusOpen( $cfg->{StatusOpen} );
    $self->StatusClosed( $cfg->{StatusClosed} );

    $self->LabelStrict( $cfg->{LabelStrict} );
    $self->LabelAllowed( $cfg->{LabelAllowed} );

    $self->DefaultNewStatus( $cfg->{DefaultNewStatus} );

    # if we are allowed this VCS, create the hook instance
    $self->VCS( $cfg->{VCS} || 'Null' );
    my $vcs = CIL::VCS::Factory->new( $cfg->{VCS} );
    $self->vcs( $vcs );
}

sub check_args {
    my ($self, $args) = @_;

    if ( $args->{r} ) {
        $self->vcs_revision($args->{r});
        if ( !$self->VCS or $self->VCS eq "Null" ) {
            warn "No VCS set in config file!\n";
        }
    }
}


sub register_hook {
    my ($self, $hook_name, $code) = @_;

    unless ( defined $allowed->{hook}{$hook_name} ) {
        croak "hook '$hook_name' not allowed";
    }

    push @{$self->{hook}{$hook_name}}, $code;
}

sub run_hook {
    my ($self, $hook_name, @rest) = @_;

    unless ( defined $allowed->{hook}{$hook_name} ) {
        croak "hook '$hook_name' not allowed";
    }

    # call all the hooks with all the args
    if ( ref $self->hook eq 'HASH' ) {
        foreach my $code ( @{$self->hook->{$hook_name}} ) {
            &$code( $self, @rest );
        }
    }
}

sub file_exists {
    my ($self, $filename) = @_;
    if ( $self->vcs_revision ) {
        $self->vcs->file_exists($self->vcs_revision, $filename);
    }
    else {
        -f $filename;
    }
}

sub dir_exists {
    my ($self, $dir) = @_;

    return $self->vcs_revision 
            ? $self->vcs->dir_exists($self->vcs_revision, $dir)
            : -d $dir
            ;
}

sub parse_cil_file {
    my ($self, $filename, $last_field) = @_;

    if ( $self->vcs_revision ) {
	my $fh = $self->vcs->get_fh($self->vcs_revision, $filename);
	CIL::Utils->parse_from_fh($fh, $last_field);
    }
    else {
	CIL::Utils->parse_cil_file($filename, $last_field);
    }
}

sub save {
    my ($self, $filename, $data, @fields) = @_;	

    if ( $self->vcs_revision ) {
        confess "tried to ->save on alternate revision";
    }
    else {
	CIL::Utils->write_cil_file( $filename, $data, @fields );
    }
}

## ----------------------------------------------------------------------------
# simple delegates to elsewhere

sub UserName {
    my ($self) = @_;
    return $self->vcs->UserName
}

sub UserEmail {
    my ($self) = @_;
    return $self->vcs->UserEmail
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
