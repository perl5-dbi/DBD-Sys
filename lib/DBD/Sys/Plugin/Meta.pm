package DBD::Sys::Plugin::Meta;

use strict;
use warnings;

#################### main pod documentation start ###################

=head1 NAME

DBD::Sys::Plugin::Meta - provides tables with meta information about DBD::Sys.

=head1 TABLES

Provided tables:

=over 8

=item alltables

Table containing the list of available tables.

Columns:

=over 12

=item tablename

Name of the table.

=back

=back

=head1 PREREQUISITES

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

my %supportedTables = ( alltables => 'DBD::Sys::Plugin::Meta::AllTables', );

sub getSupportedTables() { %supportedTables }

package DBD::Sys::Plugin::Meta::AllTables;

use strict;
use warnings;
use vars qw(@colNames);

use base qw(DBD::Sys::Table);

@colNames = qw(tablename);

sub getColNames() { @colNames }

sub collect_data()
{
    my @data = $_[0]->{owner}->getTableList();

    \@data;
}

