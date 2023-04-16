package Neo4j::Bolt::Point;
# ABSTRACT: Representation of Neo4j geographic point structs

$Neo4j::Bolt::Node::VERSION = '0.5000';

use strict;
use warnings;

use parent 'Neo4j::Types::Point';

1;

__END__

=head1 NAME

Neo4j::Bolt::Point - Representation of a Neo4j geographic point structure

=head1 SYNOPSIS

 $q = "RETURN point({latitude:55.944167, longitude:-3.161944});"
 $point = ( $cxn->run_query($q)->fetch_next )[0];

 $srid = $point->{srid};
 $latitude = $point->{y};
 $longitude = $point->{x};
 
=head1 DESCRIPTION

L<Neo4j::Bolt::Point> instances are created by executing
a Cypher query that returns a location value
from the Neo4j database.

The values in the Bolt structure are described at
L<https://neo4j.com/docs/bolt/current/bolt/structure-semantics/>. The
Neo4j::Bolt::Point object possesses number values for the keys C<x>,
C<y>, and C<z> (if present, and an integer code for C<srid>.

=head1 SEE ALSO

L<Neo4j::Bolt>, L<Neo4j::Types::Point>

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN

=head1 LICENSE

This software is Copyright (c) 2023 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
