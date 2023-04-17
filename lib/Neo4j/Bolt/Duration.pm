package Neo4j::Bolt::Duration;
# ABSTRACT: Representation of Neo4j duration struct

$Neo4j::Bolt::Node::VERSION = '0.5000';

use strict;
use warnings;
use DateTime;

# use parent 'Neo4j::Types::Duration';

sub as_DTDuration {
  my ($self) = @_;
  return DateTime::Duration->new(
    months => $self->{months},
    days => $self->{days},
    seconds => $self->{secs},
    nanoseconds => $self->{nsecs},
    );
}

1;

__END__

=head1 NAME

Neo4j::Bolt::Duration - Representation of a Neo4j duration structure

=head1 SYNOPSIS

 $q = "RETURN datetime('P1Y10MT5H30S')";
 $dt = ( $cxn->run_query($q)->fetch_next )[0];

 $months = $dt->{months};
 $days = $dt->{days};
 $secs = $dt->{secs};
 $nanosecs = $dt->{nsecs};

 $perl_dt = $node->as_DTDuration;

=head1 DESCRIPTION

L<Neo4j::Bolt::Duration> instances are created by executing
a Cypher query that returns a duration value
from the Neo4j database.

The values in the Bolt structure are described at L<https://neo4j.com/docs/bolt/current/bolt/structure-semantics/>. The Neo4j::Bolt::Duration object possesses integer values
for the keys C<months>, C<days>, C<secs>, and C<nsecs>.

Use the L</as_DTDuration> method to obtain an equivalent L<DateTime::Duration>
object that can be used in the L<DateTime> context (e.g., to perform time arithmetic).

=head1 METHODS

=over

=item as_DTDuration()

 $perl_dt  = $dt->as_DTDuration;

=back

=head1 SEE ALSO

L<Neo4j::Bolt>, L<Neo4j::Types::Duration>, L<DateTime>, L<DateTime::Duration>

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN

=head1 LICENSE

This software is Copyright (c) 2023 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
