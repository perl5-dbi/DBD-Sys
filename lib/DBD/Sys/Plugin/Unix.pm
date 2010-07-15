package DBD::Sys::Plugin::Unix;

use strict;
use warnings;

use vars qw($VERSION);

use base qw(DBD::Sys::Plugin);

$VERSION = "0.02";

#################### main pod documentation start ###################

=head1 NAME

DBD::Sys::Plugin::Unix - provides tables B<available on Unix and alike systems only>.

=head1 DESCRIPTION

On Unix and unixoide systems this plugin provides access to following tables:

=over 8

=item pwent

Table containing user information.

=item grent

Table containing group information

=back

=head1 PREREQUISITES

This plugin only works on Unix or unixoide systems.

=head1 BUGS & LIMITATIONS

No known bugs at this moment.

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

sub getPriority() { return 500; }

1;    # every module must end like this
