use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CIL',
    license             => 'perl',
    dist_author         => 'Pedro Melo <melo@cpan.org>',
    dist_version_from   => 'lib/CIL.pm',
    build_requires => {
        'Test::More'       => 0,
        'Term::CallEditor' => 0,
        'File::Touch'      => 0,
        'File::Glob'       => 0,
        'File::Basename'   => 0,
        'MIME::Base64'     => 0,
        'Email::Find'      => 0,
        
    },
    add_to_cleanup      => [ 'CIL-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
