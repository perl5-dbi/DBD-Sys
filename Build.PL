use Module::Build;

# See perldoc Module::Build for details of how this works

my $build = Module::Build->new(
               module_name => 'DBD::Sys',
               dist_author => 'Jens Rehsack <rehsack@cpan.org>, Alexander Breibach <alexander.breibach@googlemail.com>',
               dist_version_from => 'lib/DBD/Sys.pm',
               license           => 'perl',
               build_required    => { 'Test::More' => 0, },
               requires          => {
                             'DBI'               => '1.605',
                             'Module::Pluggable' => '3.9',
                             'Params::Util'      => '1.00',
                             'Scalar::Util'      => '1.00',
                             'SQL::Statement'    => '1.20',
                           },
               recommends => {
                               'Filesys::DfPortable' => '0.83',
                               'Net::Interface'      => '1.0000',
                               'Proc::ProcessTable'  => '0.45',
                               'Sys::Filesystem'     => '1.28',
                             },
               create_makefile_pl => 'traditional',
);
$build->create_build_script;
