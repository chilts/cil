use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CIL',
    license             => 'perl',
    dist_author         => 'Andrew Chilton <andychilton@gmail.com>',
    dist_version_from   => 'lib/CIL.pm',
    build_requires => {
        'Class::Accessor'  => 0,
        'DateTime'         => 0,
        'Date::Simple'     => 0,
        'Digest::MD5'      => 0,
        'Email::Date'      => 0,
        'Email::Find'      => 0,
        'Email::Simple'    => 0,
        'Fcntl'            => 0,
        'File::Basename'   => 0,
        'File::Glob'       => 0,
        'File::Slurp'      => 0,
        'File::Spec'       => 0,
        'File::Temp'       => 0,
        'File::Touch'      => 0,
        'Getopt::Mixed'    => 0,
        'MIME::Base64'     => 0,
        'Test::More'       => 0,
    },
    add_to_cleanup      => [ 'CIL-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
