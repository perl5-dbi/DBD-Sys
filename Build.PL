use Module::Build;

# See perldoc Module::Build for details of how this works

my $build = Module::Build->new(
               module_name => 'DBD::Sys',
               dist_author => 'Jens Rehsack <rehsack@cpan.org>, Alexander Breibach <alexander.breibach@googlemail.com>',
               license     => 'perl',
               requires    => {
                             'SQL::Statement'      => '1.20',
                             'Module::Pluggable'   => '3.9',
                             'DBI'                 => '1.41',
                             'Params::Util'        => '1.00',
                           },
               recommends         => {
                             'Sys::Filesystem'     => '1.00',
                             'Filesys::DfPortable' => '0.83',
		       },
               create_makefile_pl => 'traditional',
);
$build->create_build_script;
