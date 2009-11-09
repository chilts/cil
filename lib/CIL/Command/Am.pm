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

package CIL::Command::Am;

use strict;
use warnings;

use File::Slurp qw(read_file write_file);
use Email::Date qw(find_date);
use base qw(CIL::Command);

## ----------------------------------------------------------------------------

sub name { 'am' }

sub run {
    my ($self, $cil, $args, $email_filename) = @_;

    unless ( -r $email_filename ) {
        CIL::Utils::fatal("couldn't load email '$email_filename'");
    }

    my $msg_text = read_file($email_filename);

    my $email = Email::Simple->new($msg_text);
    unless ( defined $email ) {
        CIL::Utils::fatal("email file '$email_filename' didn't look like an email");
    }

    # extract some fields
    my $subject = $email->header('Subject');
    my $from    = $email->header('From');
    my $date    = find_date($email)->datetime;
    my $body    = $email->body;

    # see if we can find any issue names in either the subject or the body
    my @issue_names;
    foreach my $text ( $subject, $body ) {
        my @new = ( $text =~ /\b\#?([0-9a-f]{8})\b/gxms );
        push @issue_names, @new;
    }

    CIL::Utils->msg("Found possible issue names in email: ", ( join(' ', @issue_names) || '[none]' ));

    my %issue;
    foreach ( @issue_names ) {
        my $i = eval { CIL::Issue->new_from_name($cil, $_) };
        next unless defined $i;

        $issue{$i->name} = $i;
    }

    if ( keys %issue ) {
        CIL::Utils->msg( "Found actual issues: " . (join(' ', keys %issue)) );

        # create the new comment
        my $comment = CIL::Comment->new('tmpname');
        $comment->Issue( '...' );
        $comment->CreatedBy( $from );
        $comment->Inserted( $date );
        # $comment->Updated( $date );
        $comment->Description( $body );

        # display
        CIL::Utils->display_comment($cil, $comment);

        # found at least one issue, so this might be a comment
        my $issue;
        if ( keys %issue == 1 ) {
            $issue = (values %issue)[0];
        }
        else {
            if ( $args->{batch} ) {
                CIL::Utils->fatal('Cannot add to an existing message (in batch mode) when there are multiple matched messages!');
            }
            my $ans = CIL::Utils::ans('To which issue would you like to add this comment: ');

            # ToDo: decide whether we let them choose an arbitrary issue, for
            # now quit unless they choose one from the list
            return unless exists $issue{$ans};

            # got a valid issue_name, so set the parent name
            $issue = $issue{$ans};
        }

        # set the parent issue
        $comment->Issue( $issue->name );

        CIL::Utils->add_comment_loop($cil, undef, $issue, $comment);
    }
    else {
        CIL::Utils->msg("Couldn't find reference to any issues in the email.");

        # no issue found so make up the issue first
        my $issue = CIL::Issue->new('tmpname');
        $issue->Summary( $subject );
        $issue->Status($cil->DefaultNewStatus);
        $issue->CreatedBy( $from );
        $issue->AssignedTo( CIL::Utils->user($cil) );
        $issue->Inserted( $date );
        $issue->Updated( $date );
        $issue->Description( $body );

        # display
        CIL::Utils->display_issue_full($cil, $issue);

        # then ask if the user would like to add it
        CIL::Utils->msg("Couldn't find any likely issues, so this might be a new one.");
        if ( $args->{batch} ) {
            CIL::Utils->msg('Running in batch mode, so just adding mail as a new issue');
        } else {
            my $ans = CIL::Utils::ans('Would you like to add this message as an issue shown above (y/n): ');
            return unless $ans eq 'y';
        }

        CIL::Utils->add_issue_loop($cil, undef, $issue);
    }
}

1;
## ----------------------------------------------------------------------------
