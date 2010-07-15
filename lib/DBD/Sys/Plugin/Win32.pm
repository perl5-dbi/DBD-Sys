package DBD::Sys::Plugin::Win32;

use strict;
use warnings;

use vars qw($VERSION);

use base qw(DBD::Sys::Plugin);

$VERSION = "0.02";

sub getPriority() { return 500; }

=head1 NAME

DBD::Sys::Plugin::Win32 - provides tables B<available on Windows only>.

=head1 DESCRIPTION

On Windows this module provides following tables:

=over 8

=item pwent

Table containing user information.

=item grent

Table containing group information

=item procs

Table containing process information

=back

=head1 PREREQUISITES

This plugin only works on Windows.

=head1 BUGS & LIMITATIONS

No known bugs at this moment.

The implementation of L<Proc::ProcessTable> is very limited for several
platforms and should improved. L<Net::Interface> lacks MSWin32 support
and needs help porting from autoconf to hints framework.

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
