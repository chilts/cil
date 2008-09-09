package CIL::Command::List;

use strict;
use warnings;

use base 'CIL::Command';

sub run {
    my ($self, $cil, $args) = @_;

    $cil->check_paths;

    # find all the issues
    my $issues = $cil->get_issues();
    $issues = $cil->filter_issues( $issues, $args );
    if ( @$issues ) {
        foreach my $issue ( sort { $a->Inserted cmp $b->Inserted } @$issues ) {
            $cil->separator();
            $cil->display_issue_headers($issue);
        }
        $cil->separator();
    }
    else {
        $cil->msg('no issues found');
    }
}

'end of package CIL::Command::List';
