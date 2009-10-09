# -*- perl -*-

use Test::More tests => 13;

use DBI;

my $username = getpwuid($<);
my $groupname = getgrgid($();

ok( my $dbh = DBI->connect('DBI:Sys:'), 'connect pwent');
ok( $st  = $dbh->prepare( 'SELECT DISTINCT username, uid FROM pwent WHERE uid=?' ), 'prepare pwent' );
ok( $num = $st->execute($<), 'execute pwent' );
while( $row = $st->fetchrow_hashref() )
{
    cmp_ok( $<, '==', $row->{uid}, 'uid pwent' );
    cmp_ok( $username, 'eq', $row->{username}, 'username pwent' );
}

ok( $st  = $dbh->prepare( 'SELECT DISTINCT groupname, gid FROM grent WHERE gid=?' ), 'prepare grent' );
ok( $num = $st->execute(0+$(), 'execute grent' );
while( $row = $st->fetchrow_hashref() )
{
    cmp_ok( $(, '==', $row->{gid}, 'gid grent' );
    cmp_ok( $groupname, 'eq', $row->{groupname}, 'groupname grent' );
}

ok( $st  = $dbh->prepare( 'SELECT DISTINCT grent.groupname, grent.gid FROM grent, pwent WHERE grent.gid=? and pwent.gid=grent.gid' ), 'prepare join' );
ok( $num = $st->execute(0+$(), 'execute join' );
while( $row = $st->fetchrow_hashref() )
{
    cmp_ok( $(, '==', $row->{'grent.gid'}, 'gid join' );
    cmp_ok( $groupname, 'eq', $row->{'grent.groupname'}, 'groupname join' );
}
