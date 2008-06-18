#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw(no_plan);
use Data::Dumper;
use CIL::Utils;

my $parsed_fields = CIL::Utils->parse_cil_file( 't/i_cafebabe.cil', 'Description' );

my $correct_fields = {
    'Summary' => 'Addition of a \'attach\' command',
    'Status' => 'New',
    'CreatedBy' => 'A N Other <a.n.other@example.org>',
    'AssignedTo' => 'A Name <aname@example.com>',
    'Label' => [
        'against-v0.1',
        'priority-medium',
        'type-enhancement',
        ],
    'Inserted' => '2008-06-15 18:22:01',
    'Updated' => '2008-06-15 23:15:27',
    'Description' => '\'cil\' currently has no way of adding attachments to issues.
  
This should be added so that the actual data cil stores is complete.'
};

is_deeply($parsed_fields, $correct_fields, 'Check parsing of file');

CIL::Utils->write_cil_file( '/tmp/i_deadbeef.cil', $correct_fields, qw(Summary Status CreatedBy AssignedTo Label Inserted Updated Description) );
CIL::Utils->write_cil_file( '/tmp/i_decaf7ea.cil', $parsed_fields, qw(Summary Status CreatedBy AssignedTo Label Inserted Updated Description) );

# is($parsed_fields, $correct_fields, 'Check parsing of file');
