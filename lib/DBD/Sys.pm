use DBI ();

package DBD::Sys;

use strict;
use vars qw( @ISA $VERSION $drh $valid_attrs );

$VERSION = "0.01";

$drh = undef;    # holds driver handle(s) once initialised

sub driver($;$)
{
    my ( $class, $attr ) = @_;

    $drh->{$class} and return $drh->{$class};

    DBI->setup_driver('DBD::Sys');    # only needed once but harmless to repeat
    $attr ||= {};
    {
        no strict "refs";
        $attr->{Version} ||= ${ $class . "::VERSION" };
        $attr->{Name} or ( $attr->{Name} = $class ) =~ s/^DBD\:\://;
    }

    $drh->{$class} = DBI::_new_drh( $class . "::dr", $attr );
    return $drh->{$class};
}    # driver

sub CLONE
{
    undef $drh;
}    # CLONE

package DBD::Sys::dr;

$DBD::Sys::dr::imp_data_size = 0;

sub connect
{
    my ( $drh, $dr_dsn, $user, $auth, $attr ) = @_;

    # Some database specific verifications, default settings
    # and the like can go here. This should only include
    # syntax checks or similar stuff where it's legal to
    # 'die' in case of errors.
    # For example, many database packages requires specific
    # environment variables to be set; this could be where you
    # validate that they are set, or default them if they are not set.

    # Get the attributes we'll use to connect.
    # We use delete here because these no need to STORE them
    #      my $db = delete $attr->{drv_database} || delete $attr->{drv_db}
    #          or return $drh->set_err($DBI::stderr, "No database name given in DSN '$dr_dsn'");
    #      my $host = delete $attr->{drv_host} || 'localhost';
    #      my $port = delete $attr->{drv_port} || 123456;

    # Assume you can attach to your database via drv_connect:
    #      my $connection = drv_connect($db, $host, $port, $user, $auth)
    #          or return $drh->set_err($DBI::stderr, "Can't connect to $dr_dsn: ...");

    # create a 'blank' dbh (call superclass constructor)
    my ( $outer, $dbh ) = DBI::_new_dbh( $drh, { Name => $dr_dsn } );

    $dbh->STORE( 'Active', 1 );

    #      $dbh->{drv_connection} = $connection;

    my $driver_prefix = "sys_";    # the assigned prefix for this driver

    # Process attributes from the DSN; we assume ODBC syntax
    # here, that is, the DSN looks like var1=val1;...;varN=valN
    foreach my $var ( split /;/, $dr_dsn )
    {
        my ( $attr_name, $attr_value ) = split( '=', $var, 2 );
        return $drh->set_err( $DBI::stderr, "Can't parse DSN part '$var'" )
          unless defined $attr_value;

        # add driver prefix to attribute name if it doesn't have it already
        $attr_name = $driver_prefix . $attr_name
          unless $attr_name =~ /^$driver_prefix/o;

        # Store attribute into %$attr, replacing any existing value.
        # The DBI will STORE() these into $dbh after we've connected
        $dbh->{$attr_name} = $attr_value;
    }

    return $outer;
}

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

$DBD::Sys::db::imp_data_size = 0;

sub ping
{
    return ( $_[0]->FETCH('Active') ) ? 1 : 0;
}    # ping

sub prepare ($$;@)
{
    my ( $dbh, $statement, @attribs ) = @_;

    # create a 'blank' sth
    my $sth = DBI::_new_sth( $dbh, { Statement => $statement } );

    if ($sth)
    {
        my $class = $sth->FETCH('ImplementorClass');
        $class =~ s/::st$/::Statement/;
        my $stmt;

        eval {
            my $parser = $dbh->{sql_parser_object};
            $parser ||= $dbh->func('cache_sql_parser_object');
            $stmt = eval { $class->new( $statement, $parser, $dbh ) };
        };

        if ($@)
        {
            $dbh->set_err( $DBI::stderr, $@ );
            undef $sth;
        }
        else
        {
            $sth->STORE( 'sys_stmt', $stmt );
            $sth->STORE( 'sys_params', [] );
            $sth->STORE( 'NUM_OF_PARAMS', scalar( $stmt->params() ) );
        }
    }

    $sth;
}

sub STORE
{
    my ( $dbh, $attr, $val ) = @_;
    if ( $attr eq 'AutoCommit' )
    {

        # AutoCommit is currently the only standard attribute we have
        # to consider.
        if ( !$val ) { die q{Can't disable AutoCommit}; }
        return 1;
    }
    if ( $attr =~ m/^sys_/ )
    {

        # Handle only our private attributes here
        # Note that we could trigger arbitrary actions.
        # Ideally we should warn about unknown attributes.
        $dbh->{$attr} = $val;    # Yes, we are allowed to do this,
        return 1;                # but only for our private attributes
    }

    # Else pass up to DBI to handle for us
    $dbh->SUPER::STORE( $attr, $val );
}

sub FETCH
{
    my ( $dbh, $attr ) = @_;
    if ( $attr eq 'AutoCommit' ) { return 1; }
    if ( $attr =~ m/^sys_/ )
    {

        # Handle only our private attributes here
        # Note that we could trigger arbitrary actions.
        return $dbh->{$attr};    # Yes, we are allowed to do this,
                                 # but only for our private attributes
    }

    # Else pass up to DBI to handle
    $dbh->SUPER::FETCH($attr);
}

sub cache_sql_parser_object
{
    my $dbh = shift;
    my $parser = {
                   dialect    => 'ANSI',
                   RaiseError => $dbh->FETCH('RaiseError'),
                   PrintError => $dbh->FETCH('PrintError'),
                 };
    my $sql_flags = $dbh->FETCH("sql_flags") || {};
    %$parser = ( %$parser, %$sql_flags );
    $dbh->{sql_parser_object} = $parser = SQL::Parser->new( $parser->{dialect}, $parser );
    return $parser;
}

sub quote($$;$)
{
    my ( $self, $str, $type ) = @_;
    defined $str or return 'NULL';
    defined $type && (    $type == DBI::SQL_NUMERIC()
                       || $type == DBI::SQL_DECIMAL()
                       || $type == DBI::SQL_INTEGER()
                       || $type == DBI::SQL_SMALLINT()
                       || $type == DBI::SQL_FLOAT()
                       || $type == DBI::SQL_REAL()
                       || $type == DBI::SQL_DOUBLE()
                       || $type == DBI::SQL_TINYINT() )
      and return $str;

    $str =~ s/\\/\\\\/sg;
    $str =~ s/\0/\\0/sg;
    $str =~ s/\'/\\\'/sg;
    $str =~ s/\n/\\n/sg;
    $str =~ s/\r/\\r/sg;
    "'$str'";
}

sub disconnect($)
{
    $_[0]->STORE( 'Active', 0 );
    1;
}

sub DESTROY ($)
{
    my $dbh = $_[0];
    $dbh->SUPER::FETCH('Active') and $dbh->disconnect();
    undef $dbh->{sql_parser_object};
}

package DBD::Sys::st;
$DBD::Sys::st::imp_data_size = 0;

use Params::Util qw(_ARRAY0);

sub bind_param
{
    my ( $sth, $pNum, $val, $attr ) = @_;
    my $type = ( ref $attr ) ? $attr->{TYPE} : $attr;
    if ($type)
    {
        if (    $type == DBI::SQL_BIGINT()
             || $type == DBI::SQL_INTEGER()
             || $type == DBI::SQL_SMALLINT()
             || $type == DBI::SQL_TINYINT() )
        {
            $val += 0;
        }
        elsif (    $type == DBI::SQL_DECIMAL()
                || $type == DBI::SQL_DOUBLE()
                || $type == DBI::SQL_FLOAT()
                || $type == DBI::SQL_NUMERIC()
                || $type == DBI::SQL_REAL() )
        {
            $val += 0.;
        }
        else
        {
            my $dbh = $sth->{Database};
            $val = $dbh->quote( $sth, $type );
        }
    }
    my $params = $sth->{sys_params};
    $params->[ $pNum - 1 ] = $val;
    1;
}

sub execute
{
    my ( $sth, @bind_values ) = @_;
    my $bind_values = @bind_values ? ( $sth->{sys_params} = [@bind_values] ) : $sth->{sys_params};

    # start of by finishing any previous execution if still active
    $sth->finish if $sth->FETCH('Active');

    my $stmt = $sth->{sys_stmt};
    unless ( $sth->{sys_params_checked}++ )
    {

        # bug in SQL::Statement 1.20 and below causes breakage
        # on all but the first call
        unless ( ( my $req_prm = $stmt->params() ) == ( my $nbind_values = @$bind_values ) )
        {
            my $msg = "You passed $nbind_values parameters where $req_prm required";
            $sth->set_err( $DBI::stderr, $msg );
            return;
        }
    }

    my @err;
    my $result = eval {
        local $SIG{__WARN__} = sub { push @err, @_ };
        $stmt->execute( $sth, $bind_values );
    };
    if ( $@ || @err )
    {
        $sth->set_err( $DBI::stderr, $@ || $err[0] );
        return undef;
    }

    if ( $stmt->{NUM_OF_FIELDS} )
    {    # is a SELECT statement
        $sth->STORE( Active => 1 );
        $sth->FETCH('NUM_OF_FIELDS')
          or $sth->STORE( 'NUM_OF_FIELDS', $stmt->{NUM_OF_FIELDS} );
    }
    return $result;
}

sub finish
{
    my $sth = $_[0];
    $sth->SUPER::STORE( Active => 0 );
    delete $sth->{sys_stmt}->{data};
    return 1;
}

sub fetch($)
{
    my $sth  = $_[0];
    my $data = $sth->{sys_stmt}->{data};
    unless ( _ARRAY0($data) )
    {
        $sth->set_err( $DBI::stderr,
                       'Attempt to fetch row without a preceeding execute () call or from a non-SELECT statement' );
        return;
    }
    my $dav = shift @$data;
    unless ($dav)
    {
        $sth->finish;
        return;
    }
    if ( $sth->FETCH('ChopBlanks') )
    {
        $_ && $_ =~ s/\s+$// for @$dav;
    }
    $sth->_set_fbav($dav);
}

*fetchrow_arrayref = \&fetch;

my %unsupported_attrib = map { $_ => 1 } qw(TYPE PRECISION);

sub FETCH($$)
{
    my ( $sth, $attrib ) = @_;
    exists $unsupported_attrib{$attrib} and return undef;    # Workaround for a bug in DBI 0.93
    $attrib eq 'NAME' and return $sth->FETCH('sys_stmt')->{NAME};
    if ( $attrib eq 'NULLABLE' )
    {
        my ($meta) = $sth->FETCH('sys_stmt')->{NAME};        # Intentional !
        $meta or return undef;
        return [ (1) x @$meta ];
    }
    if ( $attrib =~ m/^sys_/ )
    {
        return $sth->{$attrib};
    }

    # else pass up to DBI to handle
    return $sth->SUPER::FETCH($attrib);
}

sub STORE($$$)
{
    my ( $sth, $attrib, $value ) = @_;
    exists $unsupported_attrib{$attrib} and return;    # Workaround for a bug in DBI 0.93
    if ( $attrib =~ m/^sys_/ )
    {

        # Private driver attributes are lower cased
        $sth->{$attrib} = $value;
        return 1;
    }
    return $sth->SUPER::STORE( $attrib, $value );
}

sub DESTROY($)
{
    my $sth = $_[0];
    $sth->SUPER::FETCH('Active') and $sth->finish();
}

sub rows ($)
{
    $_[0]->{sys_stmt}->{NUM_OF_ROWS};
}

package DBD::Sys::Statement;

use base qw(SQL::Statement);
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
    $self;
}

sub initTables2Classes()
{
    my $self = $_[0];

    foreach my $plugin ( $self->plugins() )
    {
        my %pluginTables = $plugin->getSupportedTables();
        %tables2classes = ( %tables2classes, map { lc $_ => $pluginTables{$_} } keys %pluginTables );
    }

    $self;
}

sub getTableList()
{
    $_[0]->initTables2Classes() unless ( _HASH( \%tables2classes ) );
    keys %tables2classes;
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

    $tbl;
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

        my $username = getpwuid($<);
        my $groupname = getgrgid($();

        my $dbh = DBI->connect('DBI:Sys:');
        $st  = $dbh->prepare( 'SELECT DISTINCT username, uid FROM pwent WHERE uid=?' );
        $num = $st->execute($<);
                while( $row = $st->fetchrow_hashref() )
                {       
                    print( "Found result row: uid = $uid, username = $username\n"  );
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

Free support can be requested via regular CPAN bug-tracking system. There is
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

# The preceding line will help the module return a true value

