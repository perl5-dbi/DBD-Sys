package DBD::Sys::Table;

use strict;
use warnings;
use vars qw(@ISA $VERSION);

use Carp qw(croak);
use Scalar::Util qw(blessed);

require SQL::Eval;
require DBI::DBD::SqlEngine;

@ISA     = qw(DBI::DBD::SqlEngine::Table);
$VERSION = 0.02;

sub getColNames() { croak "Abstract method 'getColNames' called"; }
sub collectData() { croak "Abstract method 'collectData' called"; }

sub getPrimaryKey() { return ( $_[0]->getColNames() )[0]; }

sub getPriority()
{
    my $self = $_[0];
    my $proto = blessed($self) || $self;
    ( my $plugin = $proto ) =~ s/(.*)::\p{Word}+$/$1/;
    return $plugin->getPriority();
}

sub new
{
    my ( $className, $attrs ) = @_;
    my %table = (
                  pos => 0,
                  %$attrs,
                );
    exists $table{col_names}
      or $table{col_names} = [ $className->getColNames() ];

    my $self = $className->SUPER::new( \%table );

    $self->{data} = $self->collectData();

    return $self;
}

sub fetch_row
{
    unless ( blessed( $_[0] ) )
    {
        my @caller = caller();
        die "Invalid invocation on unblessed '$_[0]' from $caller[0] at $caller[2] in $caller[1]";
    }
    $_[0]->{row} = undef;
    if ( $_[0]->{pos} < scalar( @{ $_[0]->{data} } ) )
    {
        $_[0]->{row} = $_[0]->{data}->[ ( $_[0]->{pos} )++ ];
    }

    $_[0]->{row};
}

sub DESTROY
{
    my $self = $_[0];
    delete $self->{owner};
    delete $self->{database};
    delete $self->{meta};
}

#################### main pod documentation start ###################

=head1 NAME

DBD::Sys::Table - abstract base class of tables used in DBD::Sys

=head1 ISA

  DBD::Sys::Table
  ISA DBI::DBD::SqlEngine::Table

=head1 DESCRIPTION

DBD::Sys::Table provides an abstract base class to wrap the requirements
of SQL::Statement on a table around the pure data collecting actions.

=head2 Methods of DBD::Sys::Table

=over 8

=item new

Constructor - called from C<DBD::Sys::PluginManager::getTable> when called
from C<SQL::Statement::open_tables> for tables with one implementor class.
The C<$attrs> argument contains the owner statement instance in the field
C<owner> and the owning database handle in the field <database>.

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

=item collectData

This method is called when the table is constructed but before the first row
shall be delivered via C<fetch_row()>.

=item getPrimaryKey

This method returns the column name of the primary key column. If not
overwritten, the first column name is returned by C<DBD::Sys::Table>.

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

#################### main pod documentation end ###################

1;
