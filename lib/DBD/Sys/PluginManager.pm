package DBD::Sys::PluginManager;

use strict;
use warnings;

use vars qw($VERSION);

require DBD::Sys::Plugin;
require DBD::Sys::CompositeTable;

use Scalar::Util qw(weaken);
use Carp qw(croak);
use Params::Util qw(_HASH _ARRAY);
use Clone qw(clone);

use Module::Pluggable
  require     => 1,
  search_path => ['DBD::Sys::Plugin'],
  inner       => 0,
  only        => qr/^DBD::Sys::Plugin::\p{Word}+$/;

$VERSION = "0.02";

sub new
{
    my $class    = $_[0];
    my %instance = ();
    my $self     = bless( \%instance, $class );
    my @tableAttrs;

    foreach my $plugin ( $self->plugins() )
    {
        my %pluginTables = $plugin->getSupportedTables();
        foreach my $pluginTable ( keys %pluginTables )
        {
            my $pte = lc $pluginTable;
            exists( $self->{tables2classes}->{$pte} )
              and !defined( _ARRAY( $self->{tables2classes}->{$pte} ) )
              and $self->{tables2classes}->{$pte} = [ $self->{tables2classes}->{$pte} ];

            exists( $self->{tables2classes}->{$pte} )
              and push(
                        @{ $self->{tables2classes}->{$pte} },
                        defined( _ARRAY( $pluginTables{$pluginTable} ) )
                        ? @{ $pluginTables{$pluginTable} }
                        : $pluginTables{$pluginTable}
                      );

            exists( $self->{tables2classes}->{$pte} )
              or $self->{tables2classes}->{$pte} = $pluginTables{$pluginTable};

            $pluginTables{$pluginTable}->can('getAttributes')
              and push( @tableAttrs,
                        map { join( '_', 'sys', $pte, $_ ) } $pluginTables{$pluginTable}->can('getAttributes') );
        }
    }

    $self->{tables_attrs} = \@tableAttrs;

    return $self;
}

sub getTableList
{
    return keys %{ $_[0]->{tables2classes} };
}

sub getTableDetails
{
    return %{ clone( $_[0]->{tables2classes} ) };
}

sub getTablesAttrs
{
    my $self = $_[0];
    my %attrMap = map { $_ => 1 } @{ $self->{tables_attrs} };
    return \%attrMap;
}

sub getTable
{
    my ( $self, $tableName, $attrs ) = @_;
    $tableName = lc $tableName;
    exists $self->{tables2classes}->{$tableName}
      or croak("Specified table '$tableName' not known");

    my $tableInfo = $self->{tables2classes}->{$tableName};
    my $table;
    if ( ref($tableInfo) )
    {
        $table = DBD::Sys::CompositeTable->new( $tableInfo, $attrs );
    }
    else
    {
        $table = $tableInfo->new($attrs);
    }

    return $table;
}

1;
