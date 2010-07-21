package DBD::Sys::Plugin::Any::NetIfconfigWrapper;

use strict;
use warnings;
use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

=pod

=head1 NAME

DBD::Sys::Plugin::Any::NetIfconfigWrapper - provides a table containing the known network interfaces

=head1 SYNOPSIS

  $netifs = $dbh->selectall_hashref("select * from netint", "interface");

$VERSION = "0.02";
=head1 ISA

  DBD::Sys::Plugin::Any::NetIfconfigWrapper
  ISA DBD::Sys::Table

=cut

my $haveNetIfconfigWrapper = 0;
eval {
    require Net::Ifconfig::Wrapper;
    $haveNetIfconfigWrapper = 1;
};

@colNames = qw(interface address_family address netmask hwadress flags_bin flags);

=head1 DESCRIPTION

This module provides the table C<netint> which contains the network
interfaces configured on a host and it's assigned addresses.

=head2 COLUMNS

=head3 interface

Interface name (e.g. eth0, em0, ...)

=head3 address_family

Address family of following address

=head3 address

The address of the interface (addresses are unique, interfaces can have
multiple addresses).

=head3 netmask

Netmask of the address above.

=head3 broadcast

Broadcast address for network address

=head3 hwadress

Hardware address (MAC number) of the interface NIC.

=head3 flags_bin

Binary representation of the interface flags (at least I<up> or I<down>).

=head3 flags

Comma separated list of the flags.

=head3 mtu

MTU for this address in this interface.

=head3 metric

Metric for the interface/address.

=head1 METHODS

=head2 getTableName

Returns 'netint'.

=cut

sub getTableName() { return 'netint'; }

=head2 getColNames

Returns the column names of the table as named in L</Columns>

=cut

sub getColNames() { @colNames }

=head2 getPrimaryKey

Returns 'address'.

=cut

sub getPrimaryKey() { return [qw(interface address_family address)]; }

=head2 getPriority

Returns 200 to let L<DBD::Sys::Plugin::Any::NetInterface> dominate.

=cut

sub getPriority() { return 200; }

=head2 collectData

Retrieves the data from L<Net::Interface> and put it into fetchable rows.

=cut

sub collectData()
{
    my @data;

    if ($haveNetIfconfigWrapper)
    {
        my $info = Net::Ifconfig::Wrapper::Ifconfig( 'list', '', '', '' ) or return [];
        foreach my $interface ( keys %$info )
        {
            my $ifdata = $info->{$interface};
            if ( exists $ifdata->{inet} )
            {
                while ( my ( $addr, $netmask ) = each %{ $ifdata->{inet} } )
                {
                    push(
                          @data,
                          [
                             $interface, 'inet', $addr, $netmask, $ifdata->{ether}, $ifdata->{status},
                             ( $ifdata->{status} ? '<up>' : '<down>' )
                          ]
                        );
                }
            }
            else
            {
                push(
                      @data,
                      [
                         $interface, undef, undef, undef, $ifdata->{ether}, $ifdata->{status},
                         ( $ifdata->{status} ? '<up>' : '<down>' )
                      ]
                    );
            }
        }

    }

    return \@data;
}

=head1 PREREQUISITES

The module L<Net::Interface> is required to provide data for the table.

=head1 AUTHOR

    Jens Rehsack			Alexander Breibach
    CPAN ID: REHSACK
    rehsack@cpan.org			alexander.breibach@googlemail.com
    http://www.rehsack.de/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SUPPORT

Free support can be requested via regular CPAN bug-tracking system. There is
no guaranteed reaction time or solution time, but it's always tried to give
accept or reject a reported ticket within a week. It depends on business load.
That doesn't mean that ticket via rt aren't handles as soon as possible,
that means that soon depends on how much I have to do.

Business and commercial support should be acquired from the authors via
preferred freelancer agencies.

=cut

1;

