package DBD::Sys::Table;

use strict;
use warnings;
use vars qw(@ISA $VERSION);

require SQL::Eval;
require DBI::DBD::SqlEngine;
use Scalar::Util qw(weaken);

@ISA = qw(DBI::DBD::SqlEngine::Table);
$VERSION = 0.02;

sub new
{
    my ( $className, $owner, $attrs ) = @_;
    my %table = (
                  col_names => [ $className->getColNames() ],
                  pos       => 0,
                  owner     => $owner,
                  attrs     => $attrs,
                );

    my $self = $className->SUPER::new( \%table );

    weaken( $self->{owner} );

    $self->{data} = $self->collect_data();

    return $self;
}

sub fetch_row
{
    $_[0]->{row} = undef;
    if ( $_[0]->{pos} < scalar( @{ $_[0]->{data} } ) )
    {
        $_[0]->{row} = $_[0]->{data}->[ ( $_[0]->{pos} )++ ];
    }

    $_[0]->{row};
}

#################### main pod documentation start ###################

=head1 NAME

DBD::Sys::Table - abstract base class of tables used in DBD::Sys

=head1 ISA

  DBD::Sys::Table
  ISA SQL::Eval::Table

=head1 DESCRIPTION

DBD::Sys::Table provides an abstract base class to wrap the requirements
of SQL::Statement on a table around the pure data collecting actions.

=head2 Methods of DBD::Sys::Table

=over 8

=item new

Constructor - called from C<DBD::Sys::Statement::open_table> when called
from C<SQL::Statement::opentables>. The constructor is always invoked with
the owning statement instance as first argument.

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

#################### main pod documentation end ###################

1;
