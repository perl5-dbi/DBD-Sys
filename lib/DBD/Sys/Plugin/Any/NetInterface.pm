package DBD::Sys::Plugin::Any::NetInterface;

use strict;
use warnings;
use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

$VERSION = "0.02";
my $haveNetInterface = 0;
eval {
    require Net::Interface;
    require Socket6;
    $haveNetInterface = 1;
};

if ($haveNetInterface) { import Net::Interface; }

@colNames = qw(interface address_family address netmask broadcast hwadress flags_bin flags mtu metric);

sub getTableName()  { return 'netint'; }
sub getColNames()   { @colNames }
sub getPrimaryKey() { return 'address'; }

$haveNetInterface and *getflags = sub {
    my $flags = $_[0] // 0;
    my $txt = ( $flags & eval ' Net::Interface::IFF_UP ' ) ? '<up' : '<down';
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
            my $flags = getflags( $if->{flags} );
            unless ( defined $if->{flags} && $if->{flags} & IFF_UP() )    # no flags found
            {
                push( @data, [ $if->{name}, undef, undef, undef, undef, undef, $if->{flags}, $flags, undef, undef, ] );
            }
            else                                                          # flags found
            {
                my $mac    = ( defined $if->{mac} )    ? "\n\tMAC: " . mac_bin2hex( $if->{mac} ) : '';
                my $mtu    = $if->{mtu}                ? 'MTU:' . $if->{mtu}                     : '';
                my $metric = ( defined $if->{metric} ) ? 'Metric:' . $if->{metric}               : '';

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

=pod

=head1 NAME

DBD::Sys::Plugin::Unix::netInterface - provides a table containing the known network interfaces

=head1 SYNOPSIS

  $alltables = $dbh->selectall_hashref("select * from netint", "interface");

=head1 DESCRIPTION

Columns:

=over 8

=item interface

Interface name (e.g. eth0, em0, ...)

=item address_family

Address family of following address

=item address

The address of the interface (addresses are unique, interfaces can have
multiple addresses).

=item netmask

Netmask of the address above.

=item broadcast

Broadcast address for network address

=item hwadress

Hardware address (MAC number) of the interface NIC.

=item flags_bin

Binary representation of the interface flags (at least I<up> or I<down>).

=item flags

Comma separated list of the flags.

=item mtu

MTU for this address in this interface.

=item metric

Metric for the interface/address.

=back

=head1 PREREQUISITES

The module C<Net::Interface> is required to provide data for the table.

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
