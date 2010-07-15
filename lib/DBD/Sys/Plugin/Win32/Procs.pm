package DBD::Sys::Plugin::Win32::Procs;

use strict;
use warnings;
use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

$VERSION  = "0.02";
@colNames = qw(pid ppid uid sess cmndline start fulltime virtsize fname state threads);

my ( $have_win32_process_info, $have_win32_process_commandline ) = ( 0, 0 );
eval { require Win32::Process::Info;        $have_win32_process_info        = 1; };
eval { require Win32::Process::CommandLine; $have_win32_process_commandline = 1; };

Win32::Process::Info->import( 'NT', 'WMI' ) if ($have_win32_process_info);
Win32::Process::CommandLine->import() if ($have_win32_process_commandline);

sub getColNames()   { @colNames }
sub getPrimaryKey() { return 'pid'; }

use Data::Dumper;

sub collectData
{
    my $self = $_[0];
    my @data;

    if ($have_win32_process_info)
    {
        for my $procInfo ( Win32::Process::Info->new()->GetProcInfo() )
        {
            ( my $uid = $procInfo->{OwnerSid} || 0 ) =~ s/.*-//;
            my $cli = "";
            Win32::Process::CommandLine::GetPidCommandLine( $procInfo->{ProcessId}, $cli )
              if ($have_win32_process_commandline);
            $cli ||= "";
            $cli =~ s{^\S+\\}{};
            $cli =~ s{\s+$}{};
            push( @data,
                  $procInfo->{ProcessId},
                  $procInfo->{ParentProcessId} || 0,
                  $uid,
                  $procInfo->{SessionId} || 0,
                  $cli || $procInfo->{Name} || "<dead>",
                  $procInfo->{CreationDate},
                  int( ( $procInfo->{KernelModeTime} || 0 ) + ( $procInfo->{UserModeTime} || 0 ) + .499 ),
                  $procInfo->{VirtualSize} || $procInfo->{WorkingSetSize},
                  $procInfo->{ExecutablePath},
                  $procInfo->{_status} || $procInfo->{Status} || $procInfo->{ExecutionState},
                  $procInfo->{ThreadCount} || 1,
                );
        }
    }

    return \@data;
}

=pod

=head1 NAME

DBD::Sys::Plugin::Win32::Procs - provides a table containing running processes

=head1 SYNOPSIS

  $alltables = $dbh->selectall_hashref("select * from procs", "pid");

=head1 DESCRIPTION

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

