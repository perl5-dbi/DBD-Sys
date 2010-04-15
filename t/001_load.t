# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use strict;
use warnings;

use Test::More tests => 1;

BEGIN { use_ok( 'DBD::Sys' ); }

my @opt_vers;
eval { require Proc::ProcessTable; push @opt_vers, "Proc::ProcessTable: $Proc::ProcessTable::VERSION" };
eval { require Net::Interface; push @opt_vers, "Net::Interface: $Net::Interface::VERSION" };
eval { require Sys::Filesystem; push @opt_vers, "Sys::Filesystem: $Sys::Filesystem::VERSION" };
eval { require Filesys::DfPortable; push @opt_vers, "Filesys::DfPortable: $Filesys::DfPortable::VERSION" };

diag( "Testing DBD::Sys $DBD::Sys::VERSION, Perl $], $^X on $^O" );
diag( "Using optional: " . join( ", ", @opt_vers ) );
