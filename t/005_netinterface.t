# -*- perl -*-

use Test::More;
use DBI;

use Data::Dumper;

# my $found = 0;
my $haveNetInterface = 0;
my $haveNetIfconfigWrapper = 0;

eval {
    require Net::Interface;
    $haveNetInterface = Net::Interface->VERSION;
};
eval {
    require Net::Ifconfig::Wrapper;
    $haveNetIfconfigWrapper = Net::Ifconfig::Wrapper->VERSION;
};
diag( " Net::Interface gefunden: " . $haveNetInterface );
diag( " Net::Ifconfig::Wrapper gefunden: " . $haveNetIfconfigWrapper );

plan( skip_all => "Net::Interface > 1.0 required for this test" ) unless $haveNetInterface or $haveNetIfconfigWrapper;
plan( tests => 4 );

ok( my $dbh = DBI->connect('DBI:Sys:'),                             'connect 1' );
ok( $st     = $dbh->prepare("SELECT COUNT(interface) FROM netint"), 'prepare netint' );
ok( my $num = $st->execute(),                                       'execute process' );
$row = $st->fetchrow_arrayref();
ok( $row->[0], 'interfaces found' );
