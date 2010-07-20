#!/usr/pkg/bin/perl

use strict;
use warnings;

use Data::Dumper;
use DBI;

my $dbh = DBI->connect( "DBI:Sys:", undef, undef );
my $sth = $dbh->prepare( 'select uid,pid,fulltime,virtsize,rss,fname,pctcpu,pctmem,cmndline,username from procs, pwent where procs.uid=pwent.uid' ) or die $dbh->errstr;
$sth->execute() or die $sth->errstr;
while( my $row = $sth->fetchrow_arrayref() )
{
    print Dumper $row;
}

