package Neo4j::Bolt::DateTime;
# ABSTRACT: Representation of Neo4j date/time related structs

$Neo4j::Bolt::Node::VERSION = '0.5000';

use strict;
use warnings;
use DateTime;

# use parent 'Neo4j::Types::DateTime';

sub as_DateTime {
  my ($self) = @_;
  my $dt;
  for ($self->{neo4j_type}) {
    /^Date$/ && do {
      return DateTime->from_epoch( epoch => $self->{epoch_days}*86400 );
    };
    /^DateTime$/ && do {
      $dt = DateTime->from_epoch( epoch => $self->{epoch_secs} );
      $dt->set_nanosecond( $self->{nsecs} // 0 );
      $dt->set_time_zone(sprint("%+05d", $self->{offset_secs}/3600));
    };
    /^LocalDateTime$/ && do {
      $dt = DateTime->from_epoch( epoch => $self->{epoch_secs} );
      $dt->set_nanosecond( $self->{nsecs} // 0 );
      $dt->set_time_zone('floating');
    };
    /^Time$/ && do {
      $dt->DateTime->from_epoch( epoch => $self->{nsecs} / 1000000000 );
      $dt->set_nanosecond($self->{nsecs} % 1000000000);
      $dt->set_time_zone(sprint("%+05d", $self->{offset_secs}/3600));
    };
    /^LocalTime$/ && do {
      $dt->DateTime->from_epoch( epoch => $self->{nsecs} / 1000000000 );
      $dt->set_nanosecond($self->{nsecs} % 1000000000);
    };
  }
  return $dt;
}

1;

__END__

=head1 NAME

Neo4j::Bolt::DateTime - Representation of a Neo4j date/time related structure

=head1 SYNOPSIS

 $q = "RETURN datetime('2021-01-21T12:00:00-0500')";
 $dt = ( $cxn->run_query($q)->fetch_next )[0];

 $neo4j_type = $dt->{neo4j_type}; # Date, Time, DateTime, LocalDateTime, LocalTime
 $epoch_days = $dt->{epoch_days};
 $epoch_secs = $dt->{epoch_secs};
 $secs = $dt->{secs};
 $nanosecs = $dt->{nsecs};
 $offset_secs = $dt->{offset_secs};

 $perl_dt = $node->as_DateTime;

=head1 DESCRIPTION

L<Neo4j::Bolt::DateTime> instances are created by executing
a Cypher query that returns one of the date/time Bolt structures
from the Neo4j database.

The values in the Bolt structures are described at L<https://neo4j.com/docs/bolt/current/bolt/structure-semantics/>. The Neo4j::Bolt::DateTime objects possess values
for the keys that are relevant to the underlying date/time structure.

Use the L</as_DateTime> method to obtain an equivalent L<DateTime>
object that is probably easier to use.

=head1 METHODS

=over

=item as_DateTime()

 $perl_dt  = $dt->as_DateTime;
 
 $node_id = $simple->{_node};
 @labels  = @{ $simple->{_labels} };
 $value1  = $simple->{property1};
 $value2  = $simple->{property2};

Obtain a L<DateTime> object equivalent to the Neo4j structure returned
by the database. Time and LocalTime objects generate a DateTime whose date is the
first day of the Unix epoch (1970-01-01).

=back

=head1 SEE ALSO

L<Neo4j::Bolt>, L<Neo4j::Types::DateTime>, L<DateTime>

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN

=head1 LICENSE

This software is Copyright (c) 2023 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
