package DBD::Sys::Plugin::Any::NetInterface;

use strict;
use warnings;
use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

=pod

=head1 NAME

DBD::Sys::Plugin::Any::NetInterface - provides a table containing the known network interfaces

=head1 SYNOPSIS

  $netifs = $dbh->selectall_hashref("select * from netint", "interface");

$VERSION = "0.02";
=head1 ISA

  DBD::Sys::Plugin::Any::NetInterface
  ISA DBD::Sys::Table

=cut

my $haveNetInterface = 0;
eval {
    require Net::Interface;
    require Socket6;
    $haveNetInterface = 1;
};

@colNames = qw(interface address_family address netmask broadcast hwaddress flags_bin flags mtu metric);

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

=head3 hwaddress

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

$haveNetInterface and *_getflags = sub {
    my $flags = $_[0] || 0;
    my $txt = ( $flags & Net::Interface::IFF_UP() ) ? '<up' : '<down';
    foreach my $iffname ( sort @{ $Net::Interface::EXPORT_TAGS{iffs} } )
    {
        no strict;
        my $v = eval { &$iffname() + 0; };
        next if $v == eval ' Net::Interface::IFF_UP ';
        if ( $flags & $v )
        {
            my $x = eval { &$iffname(); };
            $txt .= ' ' . $x;
        }
        use strict;
    }
    $txt .= '>';
};

=head2 collectData

Retrieves the data from L<Net::Interface> and put it into fetchable rows.

=cut

sub collectData()
{
    my @data;

    if ($haveNetInterface)
    {
        my @ifaces = interfaces Net::Interface();
        my $num    = @ifaces;

        foreach my $hvp (@ifaces)
        {
            my $if    = $hvp->info();
            my $flags = _getflags( $if->{flags} );
            unless ( defined $if->{flags} && $if->{flags} & Net::Interface::IFF_UP() )    # no flags found
            {
                push( @data, [ $if->{name}, undef, undef, undef, undef, undef, $if->{flags}, $flags, undef, undef, ] );
            }
            else                                                                          # flags found
            {
                my $mac    = ( defined $if->{mac} )    ? "\n\tMAC: " . Net::Interface::mac_bin2hex( $if->{mac} ) : '';
                my $mtu    = $if->{mtu}                ? 'MTU:' . $if->{mtu}                                     : '';
                my $metric = ( defined $if->{metric} ) ? 'Metric:' . $if->{metric}                               : '';

                foreach my $afname ( sort @{ $Net::Interface::EXPORT_TAGS{afs} } )
                {
                    no strict;
                    my $af = eval { &$afname() + 0; };
                    use strict;

                    next unless ( defined($af) );

                    if ( exists( $if->{$af} ) )
                    {
                        my @address   = $hvp->address($af);
                        my @netmask   = $hvp->netmask($af);
                        my @broadcast = $hvp->broadcast($af);

                        foreach my $i ( 0 .. $#address )
                        {
                            my $addr_str  = Socket6::inet_ntop( $af, $address[$i] );
                            my $netm_str  = Socket6::inet_ntop( $af, $netmask[$i] );
                            my $broad_str = Socket6::inet_ntop( $af, $broadcast[$i] ) if ( defined( $broadcast[$i] ) );

                            push(
                                  @data,
                                  [
                                     $if->{name}, $afname,      $addr_str, $netm_str,  $broad_str,
                                     $mac,        $if->{flags}, $flags,    $if->{mtu}, $if->{metric},
                                  ]
                                );
                        }
                    }
                }
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
