# -*- perl -*-

use Test::More;
use DBI;

# my $found = 0;
my $haveNetInterface = 0;

eval {
    require Net::Interface;
    $haveNetInterface = 1;
};
diag( " Net::Interface gefunden: " . $haveNetInterface );

plan( skip_all => "Net::Interface > 1.0 required for this test" ) unless $haveNetInterface;
plan( tests => 4 );

ok( my $dbh = DBI->connect('DBI:Sys:'),                             'connect 1' );
ok( $st     = $dbh->prepare("SELECT COUNT(interface) FROM netint"), 'prepare netint' );
ok( my $num = $st->execute(),                                       'execute process' );
$row = $st->fetchrow_arrayref();
ok( $row->[0], 'interfaces found' );
