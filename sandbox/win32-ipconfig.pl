#!/usr/pkg/bin/perl

use strict;
use warnings;

use Win32::IPConfig;

my $host = shift || Win32::NodeName;
my $ipconfig = Win32::IPConfig->new($host) or die "Unable to connect to $host\n";

print "hostname=", $ipconfig->get_hostname, "\n";

print "domain=", $ipconfig->get_domain, "\n";

my @searchlist = $ipconfig->get_searchlist;
print "searchlist=@searchlist (", scalar @searchlist, ")\n";

print "nodetype=", $ipconfig->get_nodetype, "\n";

print "IP routing enabled=", $ipconfig->is_router ? "Yes" : "No", "\n";

print "WINS proxy enabled=",
    $ipconfig->is_wins_proxy ? "Yes" : "No", "\n";

print "LMHOSTS enabled=",
    $ipconfig->is_lmhosts_enabled ? "Yes" : "No", "\n";

print "DNS enabled for netbt=",
    $ipconfig->is_dns_enabled_for_netbt ? "Yes" : "No", "\n";

foreach my $adapter ($ipconfig->get_adapters) {
    print "\nAdapter '", $adapter->get_name, "':\n";

    print "Description=", $adapter->get_description, "\n";

    print "DHCP enabled=",
        $adapter->is_dhcp_enabled ? "Yes" : "No", "\n";

    my @ipaddresses = $adapter->get_ipaddresses;
    print "IP addresses=@ipaddresses (", scalar @ipaddresses, ")\n";

    my @subnet_masks = $adapter->get_subnet_masks;
    print "subnet masks=@subnet_masks (", scalar @subnet_masks, ")\n";

    my @gateways = $adapter->get_gateways;
    print "gateways=@gateways (", scalar @gateways, ")\n";

    print "domain=", $adapter->get_domain, "\n";

    my @dns = $adapter->get_dns;
    print "dns=@dns (", scalar @dns, ")\n";

    my @wins = $adapter->get_wins;
    print "wins=@wins (", scalar @wins, ")\n";
}

__END__
C:\Projekte\OSS\DBD-Sys>perl -Mlocal::lib sandbox\win32-ipconfig.pl
Attempting to create directory C:\Dokumente und Einstellungen\Administrator\perl5
Attempting to create file C:\DOKUME~1\ADMINI~1\perl5\.modulebuildrc
hostname=bert
domain=muppets.liwing.de
searchlist= (0)
nodetype=B-node
IP routing enabled=No
WINS proxy enabled=No
LMHOSTS enabled=Yes
DNS enabled for netbt=No

Adapter 'LAN-Verbindung':
Description=Intel(R) 82566MM Gigabit Network Connection
DHCP enabled=Yes
IP addresses=10.62.10.45 (1)
subnet masks=255.255.255.0 (1)
gateways=10.62.10.12 (1)
domain=muppets.liwing.de
dns=10.62.10.12 (1)
wins= (0)

Adapter 'Drahtlose Netzwerkverbindung':
Description=Intel(R) Wireless WiFi Link 4965AGN
DHCP enabled=Yes
IP addresses= (0)
subnet masks= (0)
gateways= (0)
domain=
dns= (0)
wins= (0)

Adapter '1394-Verbindung 2':
Description=1394-Netzwerkadapter
DHCP enabled=Yes
IP addresses= (0)
subnet masks= (0)
gateways= (0)
domain=
dns= (0)
wins= (0)

Adapter '1394-Verbindung':
Description=1394-Netzwerkadapter
DHCP enabled=Yes
IP addresses= (0)
subnet masks= (0)
gateways= (0)
domain=
dns= (0)
wins= (0)

