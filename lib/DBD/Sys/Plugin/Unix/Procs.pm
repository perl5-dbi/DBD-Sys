package DBD::Sys::Plugin::Unix::Procs;

use strict;
use warnings;
use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

$VERSION = "0.02";
@colNames =
  qw(uid gid euid egid pid ppid pgrp sess priority ttynum flags fulltime ctime virtsize rss wchan fname start pctcpu state pctmem cmndline ttydev);

my $haveProcProcessTable = 0;

eval {
    require Proc::ProcessTable;
    $haveProcProcessTable = 1;
};

my %knownCols;

sub getColNames()   { @colNames }
sub getPrimaryKey() { return 'pid'; }

my %colMap = (
               fulltime => 'time',
               virtsize => 'size',
             );

sub _init_knownCols
{
    my $table = $_[0];
    unless ( 0 == scalar(@$table) )
    {
        %knownCols = map {
            defined $colMap{$_} or $colMap{$_} = $_;
            my $fn = $colMap{$_};
            $_ => ( eval { $table->[0]->$fn() } || 0 )
        } @colNames;
    }
}

sub collectData()
{
    my @data;

    if ($haveProcProcessTable)
    {
        my $pt    = Proc::ProcessTable->new();
        my $table = $pt->table();

        _init_knownCols($table) if ( 0 == scalar( keys %knownCols ) );

        foreach my $proc ( @{$table} )
        {
            my @row;

            #@row = (@$pt{@colNames});      # calls an error, proc::processtable bugged, handle as seen below.
            @row = map { my $fn = $colMap{$_}; $knownCols{$_} ? $proc->$fn() : undef } @colNames;

            push( @data, \@row );
        }
    }

    return \@data;
}

=pod

=head1 NAME

DBD::Sys::Plugin::Unix::Procs - provides a table containing running processes

=head1 SYNOPSIS

  $alltables = $dbh->selectall_hashref("select * from procs", "pid");

=head1 DESCRIPTION

Columns:

=over 8

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
  
=item fulltime        

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
