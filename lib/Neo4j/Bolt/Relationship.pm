package Neo4j::Bolt::Relationship;
# ABSTRACT: Representation of Neo4j Relationship

$Neo4j::Bolt::Relationship::VERSION = '0.02';

1;

__END__

=head1 NAME

Neo4j::Bolt::Relationship - Representation of a Neo4j Relationship

=head1 SYNOPSIS

 $q = 'MATCH ()-[r]-() RETURN r';
 $reln = ( $cxn->run_query($q)->fetch_next )[0];
 
 $reln_id       = $reln->{id};
 $reln_type     = $reln->{type};
 $start_node_id = $reln->{start};
 $end_node_id   = $reln->{end};
 $properties    = $reln->{properties} // {};
 %properties    = %$properties;
 
 $value1 = $reln->{properties}->{property1};
 $value2 = $reln->{properties}->{property2};

=head1 DESCRIPTION

L<Neo4j::Bolt::Relationship> instances are created by executing
a Cypher query that returns relationships from a Neo4j database.
Their properties and metadata can be accessed as shown in the
synopsis above.

If a query returns the same relationship twice, two separate
L<Neo4j::Bolt::Relationship> instances will be created.

=head1 SEE ALSO

L<Neo4j::Bolt>

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN
 majensen -at- cpan -dot- org

=head1 LICENSE

This software is Copyright (c) 2020 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
