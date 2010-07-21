# -*- perl -*-

use Test::More;
use Params::Util qw(_HASH);

do "t/lib.pl";

my @proved_vers = proveRequirements( [qw(Net::Interface Net::Ifconfig::Wrapper NetAddr::IP)] );
showRequirements( undef, $proved_vers[1] );

plan( skip_all => "Net::Interface > 1.0 or Net::Ifconfig::Wrapper >= 0.11 required for this test" )
  unless ( defined( _HASH( $proved_vers[1] ) ) );
plan( tests => 4 );

ok( my $dbh = DBI->connect('DBI:Sys:'),                             'connect 1' );
ok( $st     = $dbh->prepare("SELECT COUNT(interface) FROM netint"), 'prepare netint' );
ok( my $num = $st->execute(),                                       'execute for netint' );
$row = $st->fetchrow_arrayref();
ok( $row->[0], 'interfaces found' );
