use Module::Build;

# See perldoc Module::Build for details of how this works

my $build = Module::Build->new(
        module_name       => 'DBD::Sys',
        dist_author       => 'Jens Rehsack <rehsack@cpan.org>, Alexander Breibach <alexander.breibach@googlemail.com>',
        dist_version_from => 'lib/DBD/Sys.pm',
        license           => 'perl',
        build_required    => { 'Test::More' => 0, },
        requires          => {
                      'DBI'               => '1.605',
                      'Module::Pluggable' => '3.9',
                      'Params::Util'      => '1.00',
                      'Scalar::Util'      => '1.00',
                      'SQL::Statement'    => '1.22',
                      ( $^O eq 'MSWin32' ? ( 'Win32::pwent' => 0.01, ) : () ),
                    },
        recommends => {
                        'DBI'            => '1.611',
                        'SQL::Statement' => '1.27',
                      },
        auto_features => {
            filesys_tables => {
                                description => "Tables containing file system data",
                                requires    => { 'Sys::Filesystem' => '1.28', },
                                recommends  => {
                                                'Filesys::DfPortable' => '0.83',
                                                ( $^O eq 'MSWin32' ? ( 'Win32::DriveInfo' => 0.06, ) : () ),
                                              },
                              },
            proc_tables => {
                description => "Tables containing process information",
                requires =>
                  { ( $^O eq 'MSWin32' ? ( 'Win32::Process::Info' => 1.015, ) : ( 'Proc::ProcessTable' => '0.45' ) ), },
            },
            network_tables => {
                                description => "Tables containing network information",
                                requires    => {
                                              'Net::Interface' => '1.0000',
                                              'Socket6'        => 0,
                                            },
                                recommends => { 'Net::Interface' => '1.0012', },
                              },
                         },
        create_makefile_pl => 'traditional',
);
$build->create_build_script;
