# -*- perl -*-

use Test::More tests => 7;		# the number of the tests to run.
use FindBin qw($RealBin);		# class for getting the pathname.

use DBI;

ok( my $dbh = DBI->connect('DBI:Sys:'), 'connect');
ok( $st  = $dbh->prepare( 'SELECT DISTINCT mountpoint, label, device FROM filesystems ORDER BY mountpoint' ), 'prepare filesystems' );
ok( $num = $st->execute(), 'execute filesystems' );

my $found = 0;
my $mountpt = '';

while( $row = $st->fetchrow_hashref() )
{
	if (0==index($RealBin,$row->{mountpoint}))
	{
		++$found;
		$mountpt = $row->{mountpoint};
	}
}
ok($found, 'test mountpoint found');

ok( $st  = $dbh->prepare( "SELECT DISTINCT mountpoint, blocks, bfree, bused FROM filesysdf WHERE mountpoint = '$mountpt' ORDER BY mountpoint"), 'prepare filesysdf' );		# " instead of ' because $mountpoint needs to be evaluated!
ok( $num = $st->execute(), 'execute filesysdf' );

while( $row = $st->fetchrow_hashref() )
{
    cmp_ok($row->{bfree} + $row->{bused}, '==', $row->{blocks}, 'free blocks + used blocks = total blocks in filesysdf' );
}

