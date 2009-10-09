# -*- perl -*-

use Test::More tests => 8;		           # the number of the tests to run.
use DBI;

my $found = 0;

ok( my $dbh = DBI->connect('DBI:Sys:'), 'connect 1');
ok( $st  = $dbh->prepare( "SELECT COUNT(uid) FROM procs WHERE procs.uid=$<" ), 'prepare process' ); # $< refers to the current user (Hello, it's me ;-))
ok(my $num = $st->execute(), 'execute process' );
$row = $st->fetchrow_arrayref();                  # arrayref BECAUSE hash needs keys (eg. ColumnNames) and array just counts.
ok($row->[0], 'process found for current user');  # $row[0] refers to the first column of the array...here it's the number


ok( $dbh = DBI->connect('DBI:Sys:'), 'connect 2');
ok( $st  = $dbh->prepare( "SELECT grent.username, procs.uid FROM grent, procs WHERE grent.uid = procs.uid ORDER BY grent.uid" ), 'prepare process join user' ); # how many process per user
ok( $num = $st->execute(), 'execute process join user' );
$row = $st->fetchrow_arrayref();                  # arrayref BECAUSE hash needs keys (eg. ColumnNames) and array just counts.
ok($row->[0], 'process found for every user');    # $row[0] refers to the first column of the array...here it's the number
