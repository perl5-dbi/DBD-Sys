package DBD::Sys::Plugin::Any::FileSysDf;

use strict;
use warnings;

use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

my $haveFilesysDf = 0;
eval {
    require Sys::Filesystem;
    require Filesys::DfPortable;
    $haveFilesysDf = 1;
};
Filesys::DfPortable->import() if($haveFilesysDf);

$VERSION  = "0.02";
@colNames = qw(mountpoint blocks bfree bavail bused bper files ffree favail fused fper);

sub getColNames()   { return @colNames }
sub getAttributes() { return qw(blocksize) }

sub collectData()
{
    my $self = $_[0];
    my @data;

    if ($haveFilesysDf)
    {
        my $fs          = Sys::Filesystem->new();
        my @filesystems = $fs->filesystems( mounted => 1 );
        my $blocksize   = $self->{attrs}->{blocksize} || 1;

        foreach my $filesys (@filesystems)
        {
            my @row;
            my $mountpt = $fs->mount_point($filesys);
            my $df = dfportable( $mountpt, $blocksize );
            if ( defined($df) )
            {
                @row = (
                        $fs->mount_point($filesys),
                        @$df{ 'blocks', 'bfree', 'bavail', 'bused', 'per', 'files', 'ffree', 'favail', 'fused', 'fper' }
                       );
            }
            else
            {
                @row = ( $fs->mount_point($filesys), (undef) x 10 );
            }
            push( @data, \@row );
        }
    }

    return \@data;
}

=pod

=head1 NAME

DBD::Sys::Plugin::Any::FileSysDf - provides a table containing the free space of file systems

=head1 SYNOPSIS

  $alltables = $dbh->selectall_hashref("select * from filesysdf", "mountpoint");

=head1 DESCRIPTION

Columns:

=over 8

=item mountpoint

The friendly name of the filesystem. This will usually be the same
name as appears in the list returned by the filesystems() method.

=item blocks

Total blocks existing on the filesystem.

=item bfree

Total blocks free existing on the filesystem.

=item bavail

Total blocks available to the user executing the Perl application.
This can be different than C<bfree> if you have per-user quotas on
the filesystem, or if the super user has a reserved amount.
C<bavail> can also be a negative value because of this. For instance
if there is more space being used then you have available to you.

=item bused

Total blocks used existing on the filesystem.

=item bper

Percent of disk space used. This is based on the disk space available
to the user executing the application. In other words, if the filesystem
has 10% of its space reserved for the superuser, then the percent used
can go up to 110%.

=item files

Total inodes existing on the filesystem.

=item ffree

Total inodes free existing on the filesystem.

=item favail

Total inodes available to the user executing the application.
See the information for the C<bavail> column.

=item fused

Total inodes used existing on the filesystem.

=item fper

Percent of inodes used on the filesystem.
See the information for the C<bper> column.

=back

=head1 PREREQUISITES

C<Sys::Filesystem> and C<Filesys::DfPortable> are required in order to
run this table.

=head1 AUTHOR

    Jens Rehsack			Alexander Breibach
    CPAN ID: REHSACK
    rehsack@cpan.org			alexander.breibach@googlemail.com
    http://www.rehsack.de/		http://...

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SUPPORT

Free support can be requested via regular CPAN bug-tracking system. There is
no guaranteed reaction time or solution time. It depends on business load.
That doesn't mean that ticket via rt aren't handles as soon as possible,
that means that soon depends on how much I have to do.

Business and commercial support should be aquired from the authors via
preferred freelancer agencies.

=cut

1;
