package DBD::Sys::Plugin::Unix;

use strict;
use warnings;

#################### main pod documentation start ###################

=head1 NAME

DBD::Sys::Plugin::Unix - provides tables B<available on Unix and alike systems only>.

=head1 TABLES

On Unix and unixoide systems this plugin provides access to following tables:

=over 8

=item pwent

Table containing user information.

Columns:

=over 12

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

=item grent

Table containing group information

Columns:

=over 12

=item groupname

Name of the group

=item grpass

Encrypted password of the group

=item gid

Numerical group id of the users primary group

=item members

Numerical count of the members in this group

=back

=item procs

Table containing process information

Columns:

=over 12

=item uid

UID of process

=item gid

GID of process
 
=item euid

Effective UID of process
  
=item egid

Effective GID of process
  
=item pid

Process ID
  
=item ppid

Parent process ID
  
=item pgrp

Process group
  
=item sess

Session ID

=item cpuid

CPU ID of processor running on        # FIX ME!
  
=item priority

Priority of process
  
=item ttynum

TTY number of process
  
=item flags

Flags of process
  
=item time        

User + system time                 
  
=item ctime

Child user + system time
  
=item timensec

User + system nanoseconds part        # FIX ME!
  
=item ctimensec   

Child user + system nanoseconds       # FIX ME!
  
=item qtime       

Cumulative cpu time                   # FIX ME!
  
=item size        

Virtual memory size (bytes)
  
=item rss         

Resident set size (bytes)
  
=item wchan       

Address of current system call 
  
=item fname       

File name
  
=item start       

Start time (seconds since the epoch)
  
=item pctcpu      

Percent cpu used since process started
  
=item state       

State of process
  
=item pctmem      

Percent memory                     
  
=item cmndline

Full command line of process
  
=item ttydev      

Path of process's tty
  
=item clname      

Scheduling class name                 #FIX ME!

=back

=head1 PREREQUISITES

This plugin only works on Unix or unixoide systems.
The module C<Proc::Processtable> is required to run the module C<Procs>.

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

my %supportedTables = (
                        pwent => 'DBD::Sys::Plugin::Unix::PwEnt',
                        grent => 'DBD::Sys::Plugin::Unix::GrEnt',
                      );

my $haveProcProcessTable = 0;
my $haveNetInterface     = 0;

eval {
    require Proc::ProcessTable;
    $haveProcProcessTable = 1;
    $supportedTables{procs} = 'DBD::Sys::Plugin::Unix::Procs';
};

eval {
    require Net::Interface;
    $haveNetInterface = 1;
    $supportedTables{netint} = 'DBD::Sys::Plugin::Unix::NetInterface';
};

sub getSupportedTables() { %supportedTables }

package DBD::Sys::Plugin::Unix::PwEnt;

use strict;
use warnings;
use vars qw(@colNames);

use base qw(DBD::Sys::Table);

@colNames = qw(username passwd uid gid quota comment gcos dir shell expire);

sub getColNames() { @colNames }

sub collect_data()
{
    my @data;

    endpwent();    # ensure we're starting fresh ...
    while ( my ( $name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire ) = getpwent() )
    {
        push( @data, [ $name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire ] );
    }
    endpwent();

    \@data;
}

package DBD::Sys::Plugin::Unix::GrEnt;

use strict;
use warnings;
use vars qw(@colNames);

use base qw(DBD::Sys::Table);

@colNames = qw(groupname grpass gid members);

sub getColNames() { @colNames }

sub collect_data()
{
    my @data;

    endgrent();    # ensure we're starting fresh ...
    while ( my ( $name, $grpass, $gid, $members ) = getgrent() )
    {
        push( @data, [ $name, $grpass, $gid, $members ] );
    }
    endgrent();

    \@data;
}

package DBD::Sys::Plugin::Unix::Procs;

use strict;
use warnings;
use vars qw(@colNames);

use base qw(DBD::Sys::Table);

if ($haveProcProcessTable) { import Proc::ProcessTable; }

@colNames =
  qw(uid gid euid egid pid ppid pgrp sess priority ttynum flags time ctime size rss wchan fname start pctcpu state pctmem cmndline ttydev);

sub getColNames() { @colNames }

sub collect_data()
{
    my @data;
    my $pt = Proc::ProcessTable->new();

    foreach my $proc ( @{ $pt->table } )
    {
        my @row;

        #@row = (@$pt{@colNames});      # calls an error, proc::processtable bugged, handle as seen below.
        @row = map { $proc->$_() } @colNames;

        push( @data, \@row );
    }
    \@data;
}

package DBD::Sys::Plugin::Unix::NetInterface;

use strict;
use warnings;
use vars qw(@colNames);
use vars qw(@ISA);
use Net::Interface qw(
  :afs
  :iffs
  :iftype
  mac_bin2hex);
use Socket qw(inet_ntoa);
use Socket6 qw(inet_ntop);

use base qw(DBD::Sys::Table);

if ($haveNetInterface) { import Net::Interface; }

@colNames = qw(interface address_family address netmask broadcast hwadress flags_bin flags mtu metric);

sub getColNames() { @colNames }

sub getflags($)
{
    my $flags = $_[0] // 0;
    my $txt = ( $flags & IFF_UP ) ? '<up' : '<down';
    foreach my $iffname ( sort @{ $Net::Interface::EXPORT_TAGS{iffs} } )
    {
        no strict;
        my $v = eval { &$iffname() + 0; };
        next if $v == IFF_UP;
        if ( $flags & $v )
        {
            my $x = eval { &$iffname(); };
            $txt .= ' ' . $x;
        }
        use strict;
    }
    $txt .= '>';
}

sub collect_data()
{
    my @data;
    my @ifaces = interfaces Net::Interface();
    my $num    = @ifaces;

    print "\n$num Interfaces gefunden: @ifaces\n";

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
                        my $addr_str  = inet_ntop( $af, $address[$i] );
                        my $netm_str  = inet_ntop( $af, $netmask[$i] );
                        my $broad_str = inet_ntop( $af, $broadcast[$i] ) if ( defined( $broadcast[$i] ) );

                        push( @data,
                                   [
                                   $if->{name}, $afname,
                                   $addr_str,
                                   $netm_str,
                                   $broad_str,
                                   $mac, $if->{flags}, $flags, $if->{mtu}, $if->{metric},
                                   ]
                            );
                    }
                }
            }
        }
    }
    \@data;
}
1;    # every module must end like this
