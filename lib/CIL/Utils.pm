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
use Email::Find;
use POSIX qw(getpgrp tcgetpgrp);
use Fcntl qw(:DEFAULT :flock);
use Digest::MD5 qw(md5_hex);

## ----------------------------------------------------------------------------
# setup some globals

my $editor = $ENV{EDITOR} || 'vi';
my $y = 'y';

## ----------------------------------------------------------------------------

sub parse_cil_file {
    my ($class, $filename, $last_field) = @_;

    my @lines = read_file($filename);
    return {} unless @lines;

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

## ----------------------------------------------------------------------------
# input

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
    my @editor_args = split(/\s+/, $editor);
    my $status = system(@editor_args, $filename);

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

sub add_issue_loop {
    my ($class, $cil, undef, $issue) = @_;

    my $edit = $y;

    # keep going until we get a valid issue or we want to quit
    while ( $edit eq $y ) {
        # read in the new issue text
        my $fh = $class->solicit( $issue->as_output );
        $issue = CIL::Issue->new_from_fh( 'tmp', $fh );

        # check if the issue is valid
        if ( $issue->is_valid($cil) ) {
            $edit = 'n';
        }
        else {
            $class->msg($_) foreach @{ $issue->errors };
            $edit = ans('Would you like to re-edit (y/n): ');
        }
    }

    # if the issue is still invalid, they quit without correcting it
    return unless $issue->is_valid( $cil );

    # we've got the issue, so let's name it
    my $unique_str = time . $issue->Inserted . $issue->Summary . $issue->Description;
    $issue->set_name( substr(md5_hex($unique_str), 0, 8) );
    $issue->save($cil);

    # should probably be run from with $cil
    $cil->run_hook('issue_post_save', $issue);

    $class->display_issue($cil, $issue);

    return $issue;
}

sub add_comment_loop {
    my ($class, $cil, undef, $issue, $comment) = @_;

    my $edit = $y;

    # keep going until we get a valid issue or we want to quit
    while ( $edit eq $y ) {
        # read in the new comment text
        my $fh = CIL::Utils->solicit( $comment->as_output );
        $comment = CIL::Comment->new_from_fh( 'tmp', $fh );

        # check if the comment is valid
        if ( $comment->is_valid($cil) ) {
            $edit = 'n';
        }
        else {
            $class->msg($_) foreach @{ $issue->errors };
            $edit = $class->ans('Would you like to re-edit (y/n): ');
        }
    }

    # if the comment is still invalid, they quit without correcting it
    return unless $comment->is_valid( $cil );

    # we've got the comment, so let's name it
    my $unique_str = time . $comment->Inserted . $issue->Description;
    $comment->set_name( substr(md5_hex($unique_str), 0, 8) );

    # finally, save it
    $comment->save($cil);

    # add the comment to the issue, update it's timestamp and save it out
    $issue->add_comment( $comment );
    $issue->save($cil);
    $class->display_issue_full($cil, $issue);

    return $comment;
}

## ----------------------------------------------------------------------------
# loading

sub load_issue_fuzzy {
    my ($class, $cil, $partial_name) = @_;

    my $issues = $cil->list_issues_fuzzy( $partial_name );
    unless ( defined $issues ) {
        $class->fatal("Couldn't find any issues using '$partial_name'");
    }

    if ( @$issues > 1 ) {
        $class->fatal('found multiple issues which match that name: ' . join(' ', map { $_->{name} } @$issues));
    }

    my $issue_name = $issues->[0]->{name};
    my $issue = CIL::Issue->new_from_name($cil, $issue_name);
    unless ( defined $issue ) {
        $class->fatal("Couldn't load issue '$issue_name'");
    }

    return $issue;
}

sub load_comment_fuzzy {
    my ($class, $cil, $partial_name) = @_;

    my $comments = $cil->list_comments_fuzzy( $partial_name );
    unless ( defined $comments ) {
        $class->fatal("Couldn't find any comments using '$partial_name'");
    }

    if ( @$comments > 1 ) {
        $class->fatal('found multiple comments which match that name: ' . join(' ', map { $_->{name} } @$comments));
    }

    my $comment_name = $comments->[0]->{name};
    my $comment = CIL::comment->new_from_name($cil, $comment_name);
    unless ( defined $comment ) {
        $class->fatal("Couldn't load comment '$comment_name'");
    }

    return $comment;
}

sub load_attachment_fuzzy {
    my ($class, $cil, $partial_name) = @_;

    my $attachments = $cil->list_attachments_fuzzy( $partial_name );
    unless ( defined $attachments ) {
        $class->fatal("Couldn't find any attachments using '$partial_name'");
    }

    if ( @$attachments > 1 ) {
        $class->fatal('found multiple attachments which match that name: ' . join(' ', map { $_->{name} } @$attachments));
    }

    my $attachment_name = $attachments->[0]->{name};
    my $attachment = CIL::Attachment->new_from_name($cil, $attachment_name);
    unless ( defined $attachment ) {
        $class->fatal("Couldn't load attachment '$partial_name'");
    }

    return $attachment;
}

## ----------------------------------------------------------------------------
# display

sub display_issue {
    my ($class, $cil, $issue) = @_;

    $class->separator();
    $class->title( 'Issue ' . $issue->name() );
    $class->field( 'Summary', $issue->Summary() );
    $class->field( 'Status', $issue->Status() );
    $class->field( 'CreatedBy', $issue->CreatedBy() );
    $class->field( 'AssignedTo', $issue->AssignedTo() );
    $class->field( 'DueDate', $issue->DueDate() )
        if $issue->DueDate();
    $class->field( 'Label', $_ )
        foreach sort @{$issue->LabelList()};
    $class->field( 'Comment', $_ )
        foreach sort @{$issue->CommentList()};
    $class->field( 'Attachment', $_ )
        foreach sort @{$issue->AttachmentList()};
    $class->field( 'DependsOn', $_ )
        foreach sort @{$issue->DependsOnList()};
    $class->field( 'Precedes', $_ )
        foreach sort @{$issue->PrecedesList()};
    $class->field( 'Inserted', $issue->Inserted() );
    $class->field( 'Updated', $issue->Inserted() );
    $class->text('Description', $issue->Description());
    $class->separator();
}

sub display_issue_full {
    my ($class, $cil, $issue) = @_;

    $class->separator();
    $class->title( 'Issue ' . $issue->name() );
    $class->field( 'Summary', $issue->Summary() );
    $class->field( 'Status', $issue->Status() );
    $class->field( 'CreatedBy', $issue->CreatedBy() );
    $class->field( 'AssignedTo', $issue->AssignedTo() );
    $class->field( 'DueDate', $issue->DueDate() )
        if $issue->DueDate();
    $class->field( 'Label', $_ )
        foreach sort @{$issue->Label()};
    $class->field( 'DependsOn', $_ )
        foreach sort @{$issue->DependsOnList()};
    $class->field( 'Precedes', $_ )
        foreach sort @{$issue->PrecedesList()};
    $class->field( 'Inserted', $issue->Inserted() );
    $class->field( 'Updated', $issue->Updated() );
    $class->text('Description', $issue->Description());

    my $comments = $cil->get_comments_for( $issue );
    foreach my $comment ( @$comments ) {
        $class->display_comment( $cil, $comment );
    }

    my $attachments = $cil->get_attachments_for( $issue );
    foreach my $attachment ( @$attachments ) {
        $class->display_attachment( $cil, $attachment );
        $class->msg();
    }

    $class->separator();
}

sub display_comment {
    my ($class, $cil, $comment) = @_;

    $class->title( 'Comment ' . $comment->name() );
    $class->field( 'CreatedBy', $comment->CreatedBy() );
    $class->field( 'Inserted', $comment->Inserted() );
    $class->field( 'Updated', $comment->Inserted() );
    $class->text('Description', $comment->Description());
}

sub display_attachment {
    my ($class, $cil, $attachment) = @_;

    $class->title( 'Attachment ' . $attachment->name() );
    $class->field( 'Filename', $attachment->Filename() );
    $class->field( 'CreatedBy', $attachment->CreatedBy() );
    $class->field( 'Inserted', $attachment->Inserted() );
    $class->field( 'Updated', $attachment->Inserted() );
}

sub filter_issues {
    my ($class, $cil, $issues, $args) = @_;

    # don't filter if we haven't been given anything
    return $issues unless defined $args;
    return $issues unless %$args;

    # check that they aren't filtering on both --assigned-to and --is-mine
    if ( defined $args->{a} and defined $args->{'is-mine'} ) {
        $class->fatal("the --assigned-to and --is-mine filters are mutually exclusive");
    }

    # take a copy of the whole lot first (so we don't destroy the input list)
    my @new_issues = @$issues;

    # firstly, get out the Statuses we want
    if ( defined $args->{s} ) {
        @new_issues = grep { $_->Status eq $args->{s} } @new_issues;
    }

    # then see if we want a particular label (could be a bit nicer)
    if ( defined $args->{l} ) {
        my @tmp;
        foreach my $issue ( @new_issues ) {
            push @tmp, $issue
                if grep { $_ eq $args->{l} } @{$issue->LabelList};
        }
        @new_issues = @tmp;
    }

    # filter out dependent on open/closed
    if ( defined $args->{'is-open'} ) {
        # just get the open issues
        @new_issues = grep { $_->is_open($cil) } @new_issues;
    }
    if ( defined $args->{'is-closed'} ) {
        # just get the closed issues
        @new_issues = grep { $_->is_closed($cil) } @new_issues;
    }

    # filter out 'created by'
    if ( defined $args->{c} ) {
        @new_issues = grep { $args->{c} eq $_->created_by_email } @new_issues;
    }

    # filter out 'assigned to'
    $args->{a} = $cil->UserEmail
        if defined $args->{'is-mine'};
    if ( defined $args->{a} ) {
        @new_issues = grep { $args->{a} eq $_->assigned_to_email } @new_issues;
    }

    return \@new_issues;
}

sub separator {
    my ($class) = @_;
    $class->msg('=' x 79);
}

sub msg {
    my ($class, $msg) = @_;
    print ( defined $msg ? $msg : '' );
    print "\n";
}

sub display_issue_summary {
    my ($class, $issue) = @_;

    my $msg = $issue->name();
    $msg .= "   ";
    $msg .= $issue->Status();
    $msg .= (' ' x ( 13 - length $issue->Status() ));
    $msg .= $issue->Summary();

    $class->msg($msg);
}

sub display_issue_headers {
    my ($class, $issue) = @_;

    $class->title( 'Issue ' . $issue->name() );
    $class->field( 'Summary', $issue->Summary() );
    $class->field( 'CreatedBy', $issue->CreatedBy() );
    $class->field( 'AssignedTo', $issue->AssignedTo() );
    $class->field( 'DueDate', $issue->DueDate() );
    $class->field( 'Inserted', $issue->Inserted() );
    $class->field( 'Status', $issue->Status() );
    $class->field( 'Labels', join(' ', @{$issue->LabelList()}) );
    $class->field( 'DependsOn', join(' ', @{$issue->DependsOnList()}) );
    $class->field( 'Precedes', join(' ', @{$issue->PrecedesList()}) );
}

sub title {
    my ($class, $title) = @_;
    my $msg = "--- $title ";
    $msg .= '-' x (74 - length($title));
    $class->msg($msg);
}

sub field {
    my ($class, $field, $value) = @_;
    my $msg = "$field";
    $msg .= " " x (12 - length($field));
    $class->msg("$msg: " . (defined $value ? $value : '') );
}

sub text {
    my ($class, $field, $value) = @_;
    $class->msg();
    $class->msg($value);
    $class->msg();
}

## ----------------------------------------------------------------------------
# system

sub check_paths {
    my ($class, $cil) = @_;

    # make sure an issue directory is available
    unless ( $cil->dir_exists($cil->IssueDir) ) {
        $class->fatal("couldn't find '" . $cil->IssueDir . "' directory");
    }
}

sub ans {
    my ($msg) = @_;
    print $msg;
    my $ans = <STDIN>;
    chomp $ans;
    print "\n";
    return $ans;
}

sub err {
    my ($class, $msg) = @_;
    print STDERR ( defined $msg ? $msg : '' );
    print STDERR "\n";
}

sub fatal {
    my ($class, $msg) = @_;
    chomp $msg;
    print STDERR $msg, "\n";
    exit 2;
}

## ----------------------------------------------------------------------------
# helpers

sub extract_email_address {
    my ($class, $text) = @_;

    my $email_address;
    my $num_found = find_emails(
        $text,
        sub {
            my ($mail_address, $text_email) = @_;
            $email_address = $text_email;
        }
    );

    return $email_address;
}

sub user {
    my ($class, $cil) = @_;
    return $cil->UserName . ' <' . $cil->UserEmail . '>';
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
