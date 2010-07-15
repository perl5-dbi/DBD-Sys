package DBD::Sys::Plugin::Meta::AllTables;

use strict;
use warnings;

use vars qw($VERSION @colNames);
use base qw(DBD::Sys::Table);

@colNames = qw(table_qualifier table_owner table_name table_type remarks);
$VERSION  = "0.02";

sub getColNames() { @colNames }
sub getPriority   { return 100; }

sub collectData()
{
    my @data;
    my %tables = $_[0]->{database}->{sys_pluginmgr}->getTableDetails();

    while ( my ( $table, $class ) = each(%tables) )
    {
        push( @data, [ undef, undef, $table, 'TABLE', $class ] );
    }

    return \@data;
}

=pod

=head1 NAME

DBD::Sys::Plugin::Meta::AllTables - DBD::Sys Table Overview

=head1 SYNOPSIS

  $alltables = $dbh->selectall_hashref("select * from alltables", "table_name");

=head1 DESCRIPTION

Columns:

=over 8

=item table_qualifier

Unused, I<NULL>.

=item table_owner

Unused, I<NULL>

=item table_name

Name of the table

=item table_type

Class name of the table implementation

=item remarks

Unused, I<NULL>

=back

=cut

1;
