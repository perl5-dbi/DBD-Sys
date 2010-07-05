package DBD::Sys::Plugin;

use strict;
use warnings;

use vars qw($VERSION);

use Carp qw(croak);

$VERSION = "0.02";

sub getSupportedTables { croak "Abstract method 'getSupportedTables' called"; }

1;

=head1 NAME

DBD::Sys::Plugin - embed own tables to DBD::Sys

=head1 DESCRIPTION

DBD::Sys is developed to use a unique, well known interface (SQL) to access
data from underlying system which is available in tabular context (or
easily could transformed into).

The major goal of DBD::Sys is the ability to have an interface to collect
relevant data to operate a system - regardless the individual type. Therefore
it uses plugins to provide the accessible tables and can be extended by adding
plugins.

=head2 Plugin structure

Each plugin must be named C<DBD::Sys::Plugin::>I<Plugin-Name>. This package
must provide an external callable method named C<getSupportedTables> which
must return a hash containing the provided tables as key and the classes which
implement the tables as associated value, e.g.:

  package DBD::Sys::Plugin::Foo;

  use base qw(DBD::Sys::Plugin);

  sub getSupportedTables()
  {
      (
          mytable => 'DBD::Sys::Plugin::Foo::MyTable';
      )
  }

If the table is located in additional module, it must be required either by
the plugin package on loading or at least when it's returned by
C<getSupportedTables>. It's strongly recommended to derive the table classes
from L<DBD::Sys::Table>, but required is that it provides a constructor named
C<new> and satisfies the interface of L<SQL::Eval::Table|SQL::Eval>:

  package DBD::Sys::Plugin::Foo::MyTable;

  use base qw(DBD::Sys::Table);

  sub getColNames() { qw(col1 col2 col3) }

  sub collectData()
  {
      # ...

      \@data;
  }

=cut
