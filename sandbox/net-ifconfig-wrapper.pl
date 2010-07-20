#!/usr/pkg/bin/perl

use strict;
use warnings;

use Net::Ifconfig::Wrapper;
use Data::Dumper;

  my $Info = Net::Ifconfig::Wrapper::Ifconfig('list', '', '', '')
        or die $@;

    or die $@;

print Dumper $Info;
