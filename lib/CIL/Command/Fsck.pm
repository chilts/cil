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

package CIL::Command::Fsck;

use strict;
use warnings;

use base qw(CIL::Command);

## ----------------------------------------------------------------------------

sub name { 'fsck' }

sub run {
    my ($self, $cil, $args) = @_;


    # this looks at all the issues it can find and checks for:
    # * validity
    # * all the comments are there
    # * all the attachments are there
    # then it checks each individual comment/attachment for:
    # * ToDo: validity
    # * it's parent exists

    # find all the issues, comments and attachments
    my $issues = $cil->get_issues();
    my $issue = {};
    foreach my $i ( @$issues ) {
        $issue->{$i->name} = $i;
    }
    my $comments = $cil->get_comments();
    my $comment = {};
    foreach my $c ( @$comments ) {
        $comment->{$c->name} = $c;
    }
    my $attachments = $cil->get_attachments();
    my $attachment = {};
    foreach my $a ( @$attachments ) {
        $attachment->{$a->name} = $a;
    }

    # ------
    # issues
    my $errors = {};
    if ( @$issues ) {
        foreach my $i ( sort { $a->Inserted cmp $b->Inserted } @$issues ) {
            my $name = $i->name;

            unless ( $i->is_valid($cil) ) {
                foreach ( @{ $i->errors } ) {
                    push @{$errors->{$name}}, $_;
                }
            }

            # check that all it's comments are there and that they have this parent
            my $comments = $i->CommentList;
            foreach my $c ( @$comments ) {
                # see if this comment exists at all
                if ( exists $comment->{$c} ) {
                    # check the parent is this issue
                    push @{$errors->{$name}}, "comment '$c' is listed under issue '" . $i->name . "' but does not reciprocate"
                        unless $comment->{$c}->Issue eq $i->name;
                }
                else {
                    push @{$errors->{$name}}, "comment '$c' listed in issue '" . $i->name . "' does not exist";
                }
            }

            # check that all it's attachments are there and that they have this parent
            my $attachments = $i->AttachmentList;
            foreach my $a ( @$attachments ) {
                # see if this attachment exists at all
                if ( exists $attachment->{$a} ) {
                    # check the parent is this issue
                    push @{$errors->{$name}}, "attachment '$a' is listed under issue '" . $i->name . "' but does not reciprocate"
                        unless $attachment->{$a}->Issue eq $i->name;
                }
                else {
                    push @{$errors->{$name}}, "attachment '$a' listed in issue '" . $i->name . "' does not exist";
                }
            }

            # check that all it's 'DependsOn' are there and that they have this under 'Precedes'
            my $depends_on = $i->DependsOnList;
            foreach my $d ( @$depends_on ) {
                # see if this issue exists at all
                if ( exists $issue->{$d} ) {
                    # check the 'Precedes' is this issue
                    my %precedes = map { $_ => 1 } @{$issue->{$d}->PrecedesList};
                    push @{$errors->{$name}}, "issue '$d' should precede '" . $i->name . "' but doesn't"
                        unless exists $precedes{$i->name};
                }
                else {
                    push @{$errors->{$name}}, "issue '$d' listed as a dependency of issue '" . $i->name . "' does not exist";
                }
            }

            # check that all it's 'Precedes' are there and that they have this under 'DependsOn'
            my $precedes = $i->PrecedesList;
            foreach my $p ( @$precedes ) {
                # see if this issue exists at all
                if ( exists $issue->{$p} ) {
                    # check the 'DependsOn' is this issue
                    my %depends_on = map { $_ => 1 } @{$issue->{$p}->DependsOnList};
                    push @{$errors->{$name}}, "issue '$p' should depend on '" . $i->name . "' but doesn't"
                        unless exists $depends_on{$i->name};
                }
                else {
                    push @{$errors->{$name}}, "issue '$p' listed as preceding issue '" . $i->name . "' does not exist";
                }
            }
        }
    }
    print_fsck_errors('Issue', $errors);

    # --------
    # comments
    $errors = {};
    # loop through all the comments
    if ( @$comments ) {
        # check that their parent issues exist
        foreach my $c ( sort { $a->Inserted cmp $b->Inserted } @$comments ) {
            # check that the parent of each comment exists
            unless ( exists $issue->{$c->Issue} ) {
                push @{$errors->{$c->name}}, "comment '" . $c->name . "' refers to issue '" . $c->Issue . "' but issue does not exist";
            }
        }
    }
    print_fsck_errors('Comment', $errors);

    # -----------
    # attachments
    $errors = {};
    # loop through all the attachments
    if ( @$attachments ) {
        # check that their parent issues exist
        foreach my $a ( sort { $a->Inserted cmp $b->Inserted } @$attachments ) {
            # check that the parent of each attachment exists
            unless ( exists $issue->{$a->Issue} ) {
                push @{$errors->{$a->name}}, "attachment '" . $a->name . "' refers to issue '" . $a->Issue . "' but issue does not exist";
            }
        }
    }
    print_fsck_errors('Attachment', $errors);

    # ------------
    # nothing left
    CIL::Utils->separator();
}

sub print_fsck_errors {
    my ($entity, $errors) = @_;
    return unless keys %$errors;

    CIL::Utils->separator();
    foreach my $issue_name ( keys %$errors ) {
        CIL::Utils->title( "$entity $issue_name ");
        foreach my $error ( @{$errors->{$issue_name}} ) {
            CIL::Utils->msg("* $error");
        }
    }
}

1;
## ----------------------------------------------------------------------------
