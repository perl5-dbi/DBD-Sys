#netinterface.pl
# 	- Displays network interfaces and information
#       - Alexander Breibach, 2010-01-05

use DBI;
use Getopt::Long;
use Text::TabularDisplay;

my @opt_uid = ();    # setting the option blank, so the SQL statement runs for all users.

my $dbh = DBI->connect("DBI:Sys:");
my $st  =
         $dbh->prepare("SELECT interface, address_family, address, netmask, broadcast, hwadress, flags, mtu, metric "
                     . "FROM netint ");

my $num = $st->execute();

my $table = Text::TabularDisplay->new( qw(Interface AddressFamily Address Netmask Broadcast MacAddress Flags MTU Metric));
   $table->add(@row)
           while (@row = $st->fetchrow);
    print $table->render . "\n";

# GetOpt succeed, else failed
