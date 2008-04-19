## ----------------------------------------------------------------------------
package CIL::Issue;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Config::IniFiles;
use YAML qw(LoadFile DumpFile);

use base qw(CIL::Base);
__PACKAGE__->mk_accessors(qw(Name Summary Status Labels Comments));

my @FIELDS = ( qw(Name Summary Description CreatedBy Status Labels Comments) );

## ----------------------------------------------------------------------------

sub new {
    my ($proto) = @_;
    my $class = ref $proto || $proto;
    my $self = {};
    $self->{data}    = {};
    $self->{Changed} = 0;
    bless $self, $class;
    $self->inserted;
    return $self;
}

sub new_load_issue {
    my ($class, $name) = @_;

    unless ( defined $name ) {
        croak "provide an issue name to load";
    }

    my $filename = "issues/$name.yaml";
    unless ( -f $filename ) {
        croak "filename '$filename' does no exist";
    }

    my $issue = CIL::Issue->new();
    $issue->{data} = LoadFile( $filename );
    return $issue;

    my $cfg = Config::IniFiles->new( -file => $filename );
    unless ( defined $cfg ) {
        croak("not a valid inifile");
    }

    # my $issue = CIL::Issue->new();
    foreach my $field ( qw(Summary Name Description CreatedBy Status Labels Inserted Updated) ) {
        # modify the data directly, otherwise Updated will kick in
        $issue->{data}{$field} = $cfg->val( 'Issue', $field );
    }
    $issue->{data}{Comments}    = [];

    # set the issue Name
    $issue->{data}{Name} = $name;

    return $issue;
}

sub new_parse_issue {
    my ($class, $file) = @_;

    # $file may be a string ($filename) or a file handle ($fh)
    my $cfg = Config::IniFiles->new( -file => $file );

    unless ( defined $cfg ) {
        croak("not a valid inifile");
    }

    my $issue = CIL::Issue->new();
    foreach my $field ( qw(Summary Name Description CreatedBy Status Labels Inserted Updated) ) {
        # modify the data directly, otherwise Updated will kick in
        my $value = $cfg->val( 'Issue', $field );
        next unless defined $value;

        $value =~ s/^\s*//;
        $value =~ s/\s*$//;
        $issue->set_no_update($field, $value);
    }
    $issue->set_no_update('Comments', []);
    return $issue;
}

sub save {
    my ($self) = @_;
    my $name = $self->Name;
    my $filename = "issues/$name.yaml";
    DumpFile($filename, $self->{data});
}

sub reset {
    my ($self) = @_;

    foreach my $field ( @FIELDS ) {
        delete $self->{$field};
    }
}

sub add_comment {
    my ($self, $comment_h) = @_;

    my $comment = CIL::Comment->new($comment_h);

}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
