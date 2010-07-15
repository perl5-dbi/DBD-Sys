package DBD::Sys::Plugin::Any::FileSys;

use strict;
use warnings;

use vars qw(@colNames);

use base qw(DBD::Sys::Table);

require Sys::Filesystem;

@colNames = qw(mountpoint mounted label volume device special type options);

sub getColNames()  { @colNames }
sub getTableName() { return 'filesystems'; }

sub collectData()
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

=pod

=head1 NAME

DBD::Sys::Plugin::Any::FileSys - provides a table containing file systems

=head1 SYNOPSIS

  $alltables = $dbh->selectall_hashref("select * from filesystems", "mountpoint");

=head1 DESCRIPTION

Columns:

=over 8

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

=head1 PREREQUISITES

C<Sys::Filesystem> is required to use this table.

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
