use strict;
use warnings;
use Test::More;
use Test::Neo4j::Types;
use Neo4j::Bolt;

# Conformance to Neo4j::Types requirements

plan tests => 3;


neo4j_node_ok 'Neo4j::Bolt::Node', sub {
	my ($class, $params) = @_;
	my $self = bless { %$params }, $class;
	# Neo4j::Bolt represents an unavailable element ID by using the legacy ID in its place
	$self->{element_id} //= $params->{id};
	return $self;
};


neo4j_relationship_ok 'Neo4j::Bolt::Relationship', sub {
	my ($class, $params) = @_;
	my $self = bless {
		%$params,
		start => $params->{start_id},
		end   => $params->{end_id},
	}, $class;
	# Neo4j::Bolt represents an unavailable element ID by using the legacy ID in its place
	$self->{element_id}       //= $params->{id};
	$self->{start_element_id} //= $params->{start_id};
	$self->{end_element_id}   //= $params->{end_id};
	return $self;
};


neo4j_path_ok 'Neo4j::Bolt::Path', sub {
	my ($class, $params) = @_;
	return bless [@{ $params->{elements} }], $class;
};


done_testing;
