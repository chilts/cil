## ----------------------------------------------------------------------------
package CIL::Issue;

use strict;
use warnings;
use Data::Dumper;
use Config::IniFiles;

use base qw(CIL::Base);
__PACKAGE__->mk_accessors(qw(Name Summary Status Labels Comments));

## ----------------------------------------------------------------------------

sub load_issue {
    my ($self, $name) = @_;
    return unless defined $name;

    my $filename = "issues/$name.ini";

    return unless -f $filename;
    my $issue = CIL::Issue->new();
    $issue->read_issue( $filename );
    $issue->Name( $name );
    return $issue;
}

sub read_issue {
    my ($self, $filename) = @_;

    my $cfg = Config::IniFiles->new( -file => $filename );

    foreach my $attr ( qw(Summary Description) ) {
         $self->{$attr} = $cfg->val( 'Issue', $attr );
    }
}

sub reset {
    my ($self) = @_;

    foreach my $attr ( qw(changed) ) {
        delete $self->{$attr};
    }
}

sub inserted {
    my ($self) = @_;
    $self->{data}{inserted} = time;
}

sub updated {
    my ($self) = @_;
    $self->{changed} = '1';
    $self->{data}{updated} = time;
}

sub add_comment {
    my ($self, $comment_h) = @_;

    my $comment = CIL::Comment->new($comment_h);

}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
