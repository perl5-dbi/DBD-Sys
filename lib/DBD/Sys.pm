use DBI ();

package DBD::Sys;

use strict;
use vars qw(@ISA $VERSION $drh);
use base qw(DBI::DBD::SqlEngine);

$VERSION = "0.02";

$drh = undef;    # holds driver handle(s) once initialised

sub driver($;$)
{
    my ( $class, $attr ) = @_;

    $drh->{$class} and return $drh->{$class};

    $attr ||= {};
    {
        no strict "refs";
        $attr->{Version} ||= ${ $class . "::VERSION" };
        $attr->{Name} or ( $attr->{Name} = $class ) =~ s/^DBD\:\://;
	$attr->{Attribution} ||= 'DBD::Sys by Jens Rehsack';
    }

    $drh = $class->SUPER::driver($attr);
    return $drh;
}    # driver

sub CLONE
{
    undef $drh;
}    # CLONE

package DBD::Sys::dr;

use strict;
use warnings;

use vars qw(@ISA $imp_data_size);

@ISA = qw(DBI::DBD::SqlEngine::dr);
$DBD::Sys::dr::imp_data_size = 0;

sub data_sources
{
    my ( $drh, $attr ) = @_;
    my (@list) = ();

    # You need more sophisticated code than this to set @list...
    push( @list, 'dbi:Sys:' );

    # End of code to set @list
    return @list;
}

package DBD::Sys::db;

use strict;
use warnings;

use vars qw(@ISA $imp_data_size);

@ISA = qw(DBI::DBD::SqlEngine::db);
$DBD::Sys::db::imp_data_size = 0;

sub set_versions
{
    my $dbh = shift;
    $dbh->{sys_version} = $DBD::Sys::VERSION;

    return $dbh->SUPER::set_versions ();
    }

sub init_valid_attributes
{
    my $dbh = shift;

    $dbh->{sys_valid_attrs} = {
	sys_version        => 1, # DBD::File version
	sys_valid_attrs    => 1, # File valid attributes
	sys_readonly_attrs => 1, # File readonly attributes
	};
    $dbh->{f_readonly_attrs} = {
	sys_version        => 1, # DBD::File version
	sys_valid_attrs    => 1, # File valid attributes
	sys_readonly_attrs => 1, # File readonly attributes
	};

    return $dbh;
    }

sub init_default_attributes
{
    my $dbh = shift;

    # must be done first, because setting flags implicitly calls $dbdname::db->STORE
    $dbh->SUPER::init_default_attributes ();

    return $dbh;
}

sub validate_STORE_attr
{
    my ($dbh, $attrib, $value) = @_;

    return $dbh->SUPER::validate_STORE_attr ($attrib, $value);
}

sub get_sys_versions
{
    my ($dbh, $table) = @_;

    my $class = $dbh->{ImplementorClass};

    return $dbh->{sys_version}; # sprintf "%s using %s", $dbh->{sys_version}, $dtype;
    } # get_f_versions

sub get_avail_tables
{
    my ($dbh) = @_;
    my @tables = (
	$dbh->SUPER::get_avail_tables(),
	$dbh->selectrow_array("SELECT * FROM alltables"),
    );
    return @tables;
}

sub disconnect ($)
{
    return $_[0]->SUPER::disconnect ();
}

package DBD::Sys::st;

use strict;
use warnings;

use vars qw(@ISA $imp_data_size);

@ISA = qw(DBI::DBD::SqlEngine::st);
$DBD::Sys::st::imp_data_size = 0;

package DBD::Sys::Statement;

use strict;
use warnings;

use vars qw(@ISA $imp_data_size);

@ISA = qw(DBI::DBD::SqlEngine::Statement);

use Carp qw(croak);
use Scalar::Util qw(weaken);

use Module::Pluggable
  require     => 1,
  search_path => ['DBD::Sys::Plugin'],
  inner       => 0;
use Params::Util qw(_HASH);

my %tables2classes;

sub new($$)
{
    my ( $class, $statement, $parser, $dbh ) = @_;
    my $self = $class->SUPER::new( $statement, $parser );
    $self->{dbh} = $dbh;
    weaken( $self->{dbh} );
    return $self;
}

sub initTables2Classes()
{
    my $self = $_[0];

    foreach my $plugin ( $self->plugins() )
    {
        my %pluginTables = $plugin->getSupportedTables();
        %tables2classes = ( %tables2classes, map { lc $_ => $pluginTables{$_} } keys %pluginTables );
    }

    return $self;
}

sub getTableList()
{
    $_[0]->initTables2Classes() unless ( _HASH( \%tables2classes ) );
    return keys %tables2classes;
}

sub getTableDetails()
{
    $_[0]->initTables2Classes() unless ( _HASH( \%tables2classes ) );
    return %tables2classes;
}

sub open_table($$$$$)
{
    my ( $self, $data, $table, $createMode, $lockMode ) = @_;
    $self->initTables2Classes() unless ( _HASH( \%tables2classes ) );

    my $attr_prefix = 'sys_' . lc($table) . '_';
    my $attrs       = {};
    foreach my $attr ( keys %{ $self->{dbh} } )
    {
        next unless ( $attr =~ m/^$attr_prefix(.+)$/ );
        $attrs->{$1} = $self->{dbh}->{$attr};
    }
    my $tblClass = $tables2classes{ lc $table };
    croak("Specified table '$table' not known") unless ($tblClass);

    my $tbl = $tblClass->new( $self, $attrs );

    return $tbl;
}

#################### main pod documentation start ###################

=head1 NAME

DBD::Sys - System tables interface via DBI

=head1 SYNOPSIS

  use DBI;
  my $dbh = DBI->connect('DBI::Sys:');
  my $st  = $dbh->prepare('select distinct * from filesystems join filesysdf on mountpoint');
  my $num = $st->execute();
  if( $num > 0 )
  {
      while( my $row = $st->fetchrow_hashref() )
      {
          # ...
      }
  }

=head1 DESCRIPTION

DBD::Sys is a so called database driver for L<DBI> designed to request
information from system tables using SQL. It's based on L<SQL::Statement> as
SQL engine and allows to be extended by L<DBD::Sys::Plugins>.

=head2 Prerequisites

Of course, a DBD requires L<DBI> to run. Further, L<SQL::Statement> as SQL
engine is required, L<Module::Pluggable> to manage the plugin's and
L<Module::Build> for installation. Finally, to speed up some checks,
L<Params::Util> is needed.

All these modules are mandatory and DBD::Sys will fail when they are not
available.

To request system information, existing modules from CPAN are used - there
are available ones to provide access to some system tables. These modules are
optional, but recommended. It wouldn't make much sense to use DBD::Sys without
the ability to access the tables from the (operating) system.

To get an overview which dependencies are there, please check the plugins
or take a look into META.yml.

=head1 USAGE

=head2 Installation

We chose C<Module::Build> installation, because not every system has a
suitable make utility - but at least everyone who's using perl modules has
a running perl. So installing can be done after extracting

  gzip -dc DBD-Sys-${VERSION}.tar.gz | tar xvf -

without too much extra effort:

  1  cd DBD-Sys-${VERSION}
  2  perl Build.PL
  3  ./Build
  4  ./Build test
  5  ./Build install

If you want to skip the tests (not recommended), you can skip over lines 3
and 4.

=head2 Fetching data

To retrieve data, you can use the following example:

        my $dbh = DBI->connect('DBI:Sys:');
        $st  = $dbh->prepare( 'SELECT DISTINCT username, uid FROM pwent WHERE username=?' );
        $num = $st->execute(getlogin() || $ENV{USER} || $ENV{USERNAME});
	while( $row = $st->fetchrow_hashref() )
	{       
	    printf( "Found result row: uid = %d, username = %s\n", $row->{uid}, $row->{username} );
	}       

=head2 Error handling

Following soon...

=head2 Metadata

Not yet implemented, but following soon: Block-Sizing, LsoF, Directories, etc.

=head2 Restrictions

e.g. No modifying of system tables ...

=head1 BUGS & LIMITATIONS

This module does not support any changes to the provided tables in order
to prevent inconsistant data.

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

Free support can be requested via regular CPAN bug-tracking system at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBD-Sys>. There is
no guaranteed reaction time or solution time. It depends on business load.
That doesn't mean that ticket via rt aren't handles as soon as possible,
that means that soon depends on how much I have to do.

Business and commercial support should be aquired from the authors via
preferred freelancer agencies.

=head1 SEE ALSO

perl(1), L<DBI>, L<Module::Build>, L<Module::Pluggable>, L<Params::Util>,
L<SQL::Statement>.

=cut

#################### main pod documentation end ###################

1;
