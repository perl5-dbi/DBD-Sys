package DBD::Sys::Plugin::Any;

use strict;
use warnings;

#################### main pod documentation start ###################

=head1 NAME

DBD::Sys::Plugin::Any - provides tables available for any known operating system
using filesystems.

=head1 TABLES

This plugin provides access to following tables:

=over 8

=item filesystems

Table containing information about the filesystem, e.g. mountpoint, label, etc.

Columns:

=over 12

=item mountpoint

The friendly name of the filesystem. This will usually be the same
name as appears in the list returned by the filesystems() method.

=item mounted

Boolean true if the filesystem is mounted.

=item label

The fileystem label

=item volume

Volume that the filesystem belongs to or is mounted on.

=item device

The physical device that the filesystem is connected to.

=item special

Boolean true if the filesystem type is considered "special".

=item type

The type of filesystem format, e.g. fat32, ntfs, ufs, hpfs, ext3, xfs etc.

=item options

The options that the filesystem was mounted with.
This may commonly contain information such as read-write,
user and group settings and permissions.

=back

=item filesysdf

Table containing group informations.

Columns:

=over 12

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

=back

=head1 PREREQUISITES

C<Sys::Filesystem> and C<Filesys::DfPortable> are required in order to
run this module.

=head1 BUGS & LIMITATIONS

No known bugs at this moment. This module will be advanced in future to work
even if the required modules (see PREREQUISITES) are not present.

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

#################### main pod documentation end ###################

my $haveSysFilesystem     = 0;
my $haveFilesysDfPortable = 0;
my %supportedTables       = ();

eval {
    require Sys::Filesystem;
    $haveSysFilesystem = 1;
    $supportedTables{filesystems} = 'DBD::Sys::Plugin::Any::FileSys';
};
eval {
    require Filesys::DfPortable;
    $haveFilesysDfPortable = 1;
    $supportedTables{filesysdf} = 'DBD::Sys::Plugin::Any::FileSysDf';
} if ($haveSysFilesystem);

sub getSupportedTables() { %supportedTables }

package DBD::Sys::Plugin::Any::FileSys;

use vars qw(@colNames);

use base qw(DBD::Sys::Table);

@colNames = qw(mountpoint mounted label volume device special type options);

sub getColNames() { @colNames }

sub collect_data()
{
    my @data;

    my $fs          = Sys::Filesystem->new();
    my @filesystems = $fs->filesystems();

    foreach my $filesys (@filesystems)
    {
        my @row;
        @row = (
                 $fs->mount_point($filesys), $fs->mounted($filesys),
                 $fs->label($filesys),       $fs->volume($filesys),
                 $fs->device($filesys),      $fs->special($filesys),
                 $fs->type($filesys),        $fs->options($filesys)
               );
        push( @data, \@row );
    }

    \@data;
}

package DBD::Sys::Plugin::Any::FileSysDf;

use vars qw(@colNames);

use base qw(DBD::Sys::Table);
if ($haveFilesysDfPortable) { import Filesys::DfPortable; }

@colNames = qw(mountpoint blocks bfree bavail bused bper files ffree favail fused fper);

sub getColNames() { @colNames }

sub collect_data()
{
    my $self = $_[0];
    my @data;

    my $fs = Sys::Filesystem->new();
    my @filesystems = $fs->filesystems( mounted => 1 );
    my $blocksize = $self->{attrs}->{blocksize} || 1;

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

    \@data;
}

1;    # every module must end like this
