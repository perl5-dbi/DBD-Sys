#!/usr/pkg/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Sys::Utmp;

my $utmp = Sys::Utmp->new();

while ( my $utent = $utmp->getutent() )
{
    if ( $utent->user_process )
    {
        next unless $utent->ut_user;
        print Dumper(
                      [
                        $utent->ut_user, $utent->ut_id eq "" ? undef : $utent->ut_id,
                        $utent->ut_line, $utent->ut_pid == -1 ? undef : $utent->ut_pid,
                        $utent->ut_type, $utent->ut_host eq "" ? undef : $utent->ut_host,
                        $utent->ut_time
                      ]
                    );
    }
}

$utmp->endutent;
