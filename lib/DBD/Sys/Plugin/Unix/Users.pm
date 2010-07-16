package DBD::Sys::Plugin::Unix::Users;

use strict;
use warnings;
use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

$VERSION  = "0.02";
@colNames = qw(username passwd uid gid quota comment gcos dir shell expire);

sub getTableName() { return 'pwent'; }
sub getColNames()  { @colNames }

my $havepwent = 0;

eval { setpwent(); my @pwentry = getpwent(); endpwent(); $havepwent = 1; };

sub collectData()
{
    my @data;

    if ($havepwent)
    {
        setpwent();    # rewind to ensure we're starting fresh ...
        while ( my ( $name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire ) = getpwent() )
        {
            push( @data, [ $name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire ] );
        }
	setpwent();
        endpwent();
    }

    return \@data;
}

=pod

=head1 NAME

DBD::Sys::Plugin::Unix::Users - provides a table containing a list of operating system users

=head1 SYNOPSIS

  $alltables = $dbh->selectall_hashref("select * from pwent", "username");

=head1 DESCRIPTION

Columns:

=over 8

=item username

Name of the user in this row how he/she authenticates himself/herself to
the system.

=item passwd

Encrypted password of the user - typically accessible by root only.

=item uid

Numerical user id

=item gid

Numerical group id of the users primary group

=item quota

Quota, when supported by this system and set

=item comment

Comment, when set

=item gcos

General information about the user

=item dir

Users home directory

=item shell

Users default login shell

=item expire

Account expiration time, when available

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
