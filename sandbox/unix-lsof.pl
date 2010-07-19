#!/usr/pkg/bin/perl

use strict;
use warnings;

use Unix::Lsof;
use Data::Dumper;

my ( $output, $error ) = lsof("afile.txt");
print Dumper $output;
my @pids = keys %$output;
my @commands = map { $_->{"command name"} } values %$output;

( $output, $error ) = lsof(  );
print Dumper $output;
my @filenames;
for my $pid ( keys %$output )
{
    for my $f ( @{ $output->{$pid}{files} } )
    {
        push @filenames, $f->{"file name"};
    }
}

my $lr = lsof( "-p", $$ );    # see Unix::Lsof::Result
@filenames = $lr->get_filenames();
print Dumper \@filenames;
my @inodes    = $lr->get_values("inode number");

# With options
# $lr = lsof( "-p", $$, { binary => "/opt/bin/lsof" } );
