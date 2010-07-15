# -*- perl -*-

use Test::More tests => 7;    # the number of the tests to run.
use FindBin qw($RealBin);     # class for getting the pathname.

use DBI;

my $haveSysFilesystem     = 0;
my $haveFilesysDfPortable = 0;
eval { require Sys::Filesystem; $haveSysFilesystem = 1; };
eval { require Filesys::DfPortable; $haveFilesysDfPortable = 1; } if ($haveSysFilesystem);

my $mountpt = '';

ok( my $dbh = DBI->connect('DBI:Sys:sys_filesysdf_blocksize=1024'), 'connect' );
SKIP:
{
    skip( 'Sys::Filesystem required for table filesystems', 3 ) unless ($haveSysFilesystem);
    ok( $st = $dbh->prepare('SELECT DISTINCT mountpoint, label, device FROM filesystems ORDER BY mountpoint'),
        'prepare filesystems' );
    ok( $num = $st->execute(), 'execute filesystems' );

    my $found = 0;

    while ( $row = $st->fetchrow_hashref() )
    {
        if ( 0 == index( $RealBin, $row->{mountpoint} ) )
        {
            ++$found;
            $mountpt = $row->{mountpoint};
        }
    }
    ok( $found, 'test mountpoint found' );
}

SKIP:
{
    skip( 'Sys::Filesystem and Filesys::DfPortable required for table filesysdf', 3 )
      unless ( $haveSysFilesystem and $haveFilesysDfPortable );
    ok(
        $st = $dbh->prepare(
            "SELECT DISTINCT mountpoint, blocks, bfree, bused FROM filesysdf WHERE mountpoint = '$mountpt' ORDER BY mountpoint"
        ),
        'prepare filesysdf'
      );    # " instead of ' because $mountpoint needs to be evaluated!
    ok( $num = $st->execute(), 'execute filesysdf' );

    use Data::Dumper;
    while ( $row = $st->fetchrow_hashref() )
    {
        cmp_ok( $row->{bfree} + $row->{bused},
                '==', $row->{blocks}, 'free blocks + used blocks = total blocks in filesysdf' );
    }
}
