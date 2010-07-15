package DBD::Sys::Plugin::Win32::Groups;

use strict;
use warnings;
use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);
my $haveWin32pwent = 0;
eval {
    require Win32::pwent;
    $haveWin32pwent = 1;
};

$VERSION  = "0.02";
@colNames = qw(groupname grpass gid members);

sub getTableName() { return 'grent'; }
sub getColNames()  { @colNames }

sub collectData()
{
    my @data;

    if ($haveWin32pwent)
    {
        Win32::pwent::endgrent();    # ensure we're starting fresh ...
        while ( my ( $name, $grpass, $gid, $members ) = Win32::pwent::getgrent() )
        {
            push( @data, [ $name, $grpass, $gid, $members ] );
        }
        Win32::pwent::endgrent();
    }

    \@data;
}

=pod

=head1 NAME

DBD::Sys::Plugin::Win32::Groups - provides a table containing the operating system user groups

=head1 SYNOPSIS

  $alltables = $dbh->selectall_hashref("select * from grent", "groupname");

=head1 DESCRIPTION

Columns:

=over 8

=item groupname

Name of the group

=item grpass

Encrypted password of the group - usually empty for current LANMAN functions
used to retrieve the data.

=item gid

Numerical group id of the users primary group

=item members

Numerical count of the members in this group

=back

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

