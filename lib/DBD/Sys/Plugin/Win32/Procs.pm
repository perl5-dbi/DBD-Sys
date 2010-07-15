package DBD::Sys::Plugin::Win32::Procs;

use strict;
use warnings;
use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

$VERSION  = "0.02";
@colNames = qw(pid uid cmndline start run state);

sub getColNames()   { @colNames }
sub getPrimaryKey() { return 'pid'; }

sub collectData
{
    my $self = $_[0];
    my @data;

    eval {
        require Win32::Process::Info;
        Win32::Process::Info->import();
        require Win32::Process::CommandLine;
        Win32::Process::CommandLine->import();
        for my $procInfo ( Win32::Process::Info->new()->GetProcInfo() )
        {
            ( my $uid = $procInfo->{OwnerSid} || 0 ) =~ s/.*-//;
            my $cli = "";
            Win32::Process::CommandLine::GetPidCommandLine( $procInfo->{ProcessId}, $cli );
            $cli ||= "";
            $cli =~ s{^\S+\\}{};
            $cli =~ s{\s+$}{};
            push( @data,
                  $procInfo->{ProcessId},
                  $uid,
                  $cli || $_->{Name} || "<dead>",
                  fmt_stime( $_->{CreationDate} ),
                  fmt_time( int( ( $_->{KernelModeTime} // 0 ) + ( $_->{UserModeTime} // 0 ) + .499 ) ),
                  $procInfo->{_status},
                );
        }
    };

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

