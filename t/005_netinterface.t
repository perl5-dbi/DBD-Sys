# -*- perl -*-

use Test::More tests => 4;		           # the number of the tests to run.
use DBI;

# my $found = 0;
my $haveNetInterface = 0;

eval {
    require Net::Interface;
    $haveNetInterface = 1;
}; diag( " Net::Interface gefunden: " . $haveNetInterface);


ok( my $dbh = DBI->connect('DBI:Sys:'), 'connect 1');
ok( $st  = $dbh->prepare( "SELECT COUNT(interface) FROM netint" ), 'prepare netint' ); 
ok(my $num = $st->execute(), 'execute process' );
$row = $st->fetchrow_arrayref();                  # arrayref BECAUSE hash needs keys (eg. ColumnNames) and array just counts.
ok($row->[0], 'interfaces found');  # $row[0] refers to the first column of the array...here it's the number

#ok( $dbh = DBI->connect('DBI:Sys:'), 'connect 2');
#ok( $st  = $dbh->prepare( 'SELECT username, COUNT(procs.uid) as process_ct FROM procs, pwent WHERE procs.uid = pwent.uid GROUP BY username' ), 'prepare process join user' ); # how many process per user
#print $st;
#ok( $num = $st->execute(), 'execute process join user' );
#$row = $st->fetchrow_arrayref();                  # arrayref BECAUSE hash needs keys (eg. ColumnNames) and array just counts.
#ok($row->[0], 'process found for every user');    # $row[0] refers to the first column of the array...here it's the number

