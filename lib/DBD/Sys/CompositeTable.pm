package DBD::Sys::CompositeTable;

use strict;
use warnings;
use vars qw(@ISA $VERSION);

require SQL::Eval;
require DBI::DBD::SqlEngine;
use Scalar::Util qw(blessed weaken);
use Clone qw(clone);

@ISA     = qw(DBD::Sys::Table);
$VERSION = "0.02";

my %compositedInfo;

sub new
{
    my ( $proto, $tableInfo, $attrs ) = @_;

    my @tableClasses =
      sort { ( $a->getPriority() <=> $b->getPriority() ) || ( blessed($a) cmp blessed($b) ) } @$tableInfo;

    my $compositeName = join( "-", @tableClasses );
    my ( @embed, %allColNames, @allColNames, $allColIdx, %mergeCols, %enhanceCols, $primaryKey );
    $allColIdx = 0;
    foreach my $tblClass (@tableClasses)
    {
        my %embedAttrs = %$attrs;
        my $embedded   = $tblClass->new( \%embedAttrs );
        push( @embed, $embedded );
        next if ( defined( $compositedInfo{$compositeName} ) );

        my @embedColNames = $embedded->getColNames();
        if ($allColIdx)
        {
            my $embedPK = $embedded->getPrimaryKey();
            $primaryKey eq $embedPK
              or croak( "Primary key ($embedPK) of '$tblClass' differs from primary key ($primaryKey) of "
                        . join( ", ", keys %mergeCols ) );
            $mergeCols{$tblClass} = [];
            foreach my $colIdx ( 0 .. $#embedColNames )
            {
                my $colName = $embedColNames[$colIdx];
                if ( exists( $allColNames{$colName} ) )
                {
                    $enhanceCols{$tblClass}->{ $allColNames{$colName} } = $colIdx;
                }
                else
                {
                    push( @allColNames,               $colName );
                    push( @{ $mergeCols{$tblClass} }, $colIdx );
                    $allColNames{$colName} = $allColIdx++;
                }
            }
        }
        else
        {
            %allColNames          = map { $_ => $allColIdx++ } @embedColNames;
            @allColNames          = @embedColNames;
            $mergeCols{$tblClass} = [ 0 .. $#embedColNames ];
            $primaryKey           = $embedded->getPrimaryKey();
        }
    }

    defined( $compositedInfo{$compositeName} )
      or $compositedInfo{$compositeName} = {
                                             col_names    => \@allColNames,
                                             primary_key  => $primaryKey,
                                             merge_cols   => \%mergeCols,
                                             enhance_cols => \%enhanceCols,
                                           };

    $attrs->{meta} = {
                       composite_name => $compositeName,
                       embed          => \@embed,
                       primary_key    => $compositedInfo{$compositeName}->{primary_key},
                       merge_cols     => $compositedInfo{$compositeName}->{merge_cols},
                       enhance_cols   => $compositedInfo{$compositeName}->{enhance_cols},
                     };
    $attrs->{col_names} = clone( $compositedInfo{$compositeName}->{col_names} );

    return $proto->SUPER::new($attrs);
}

sub getColNames
{
    return @{ $_[0]->{col_names} };
}

sub collectData
{
    my $self = $_[0];
    my %data;

    my $meta          = $self->{meta};
    my $compositeName = $meta->{composite_name};
    my $rowOffset     = 0;
    foreach my $embedded ( @{ $meta->{embed} } )
    {
        my $nextRowOffset;
        my $pkIdx       = $embedded->column_num( $meta->{primary_key} );
        my $mergeCols   = $meta->{merge_cols}->{ blessed($embedded) };
        my $enhanceCols = $meta->{enhance_cols}->{ blessed($embedded) };
        while ( my $row = $embedded->fetch_row() )
        {
            $nextRowOffset ||= $rowOffset + scalar(@$mergeCols);
            my $pk = $row->[$pkIdx];
            if ( $data{$pk} )
            {
                if ( scalar( @{ $data{$pk} } ) == $nextRowOffset )
                {
                    warn "primary key '" . $meta->{primary_key} . "' is not unique for " . blessed($embedded);
                }
                else
                {
                    push( @{ $data{$pk} }, @$row[@$mergeCols] );
                }
            }
            else
            {
                if ( 0 == $rowOffset )
                {
                    $data{$pk} = [@$row];
                }
                else
                {
                    my @entry = (undef) x $rowOffset;
                    @entry[ keys %{$enhanceCols} ] = @$row[ values %{$enhanceCols} ];
                    push( @entry, @$row[@$mergeCols] );
                    $data{$pk} = \@entry;
                }
            }
        }
    }

    my @data = values %data;

    return \@data;
}

=pod

=head1 NAME

DBD::Sys::CompositeTable - Table implementation to compose different sources into one table

=head1 ISA

  DBD::Sys::CompositeTable
  ISA DBD::Sys::Table
    ISA DBI::DBD::SqlEngine::Table

=head1 DESCRIPTION

DBD::Sys::CompositeTable provides a composite for tables which can
have different sources (e.g. table C<procs> can fetch data from
a later version of L<Proc::ProcessTable> and L<Win32::Process::Info>).

=head2 Methods of DBD::Sys::Table

=over 8

=item new

Constructor - called from C<DBD::Sys::PluginManager::getTable> when
C<getTable()> is called for a table which has multiple implementors.

=item fetch_row

Called by C<SQL::Statement> to fetch the single rows. This method return the
rows contained in the C<data> attribute of the individual instance.

=back

=head2 Methods provided by derived classes

=over 8

=item getColNames

This method is called during the construction phase of the table. It must be
a I<static> method - the called context is the class name of the constructed
object.

=item collect_data

This method is called when the table is constructed but before the first row
shall be delivered via C<fetch_row()>.

=back

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

1;
