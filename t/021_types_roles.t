use strict;
use warnings;
use Test::More;
use Test::Neo4j::Types;
use Neo4j::Bolt;

# Conformance to Neo4j::Types requirements

plan tests => 3;


neo4j_node_ok 'Neo4j::Bolt::Node', sub { bless pop, shift };


neo4j_relationship_ok 'Neo4j::Bolt::Relationship', sub {
	my ($class, $params) = @_;
	return bless {
		%$params,
		start => $params->{start_id},
		end   => $params->{end_id},
	}, $class;
};


neo4j_path_ok 'Neo4j::Bolt::Path', sub {
	my ($class, $params) = @_;
	return bless [@{ $params->{elements} }], $class;
};


done_testing;
