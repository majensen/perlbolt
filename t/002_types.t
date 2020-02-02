use Test::More;
use Neo4j::Bolt::NeoValue;

diag "create neo4j_values from SVs";
my $i = 100;
my $v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Integer", "Integer";
is $v->_as_perl, $i, "roundtrip";
$i = 100.1;
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Float", "Float";
is $v->_as_perl, $i, "roundtrip";
$i = "Hey dude";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "String", "String";
is $v->_as_perl, $i, "roundtrip";
$i = \0;
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Boolean", "Boolean";
ok ! $v->_as_perl, "Boolean false is not truthy";
is ref($v->_as_perl), "JSON::PP::Boolean", "Boolean false defined and blessed";
$v = Neo4j::Bolt::NeoValue->_new_from_perl(["this", "is",1,"array"]);
is $v->_neotype, "List", "List";
is_deeply $v->_as_perl,["this", "is",1,"array"],"roundtrip";
$v = Neo4j::Bolt::NeoValue->_new_from_perl({ this => "is", a => 5, hash => "map"});
is $v->_neotype, "Map", "Map";
is_deeply $v->_as_perl,{ this => "is", a => 5, hash => "map"}, "roundtrip";
$v = Neo4j::Bolt::NeoValue->_new_from_perl({ _node => 154732534 });
is $v->_neotype, "Node", "Empty node";
is_deeply $v->_as_perl,{ _node => 154732534 },"roundtrip";
$v = Neo4j::Bolt::NeoValue->_new_from_perl({ _node => 154732534, these => "are", some => "props" });
is $v->_neotype, "Node", "Node with Props";
is_deeply $v->_as_perl,{ _node => 154732534, these => "are", some => "props" },"roundtrip";
$v = Neo4j::Bolt::NeoValue->_new_from_perl({ _node => 154732534, _labels=>['lab','el'], these => "are", some => "props" });
is $v->_neotype, "Node", "Node with Props & Labels";
is_deeply $v->_as_perl,{ _node => 154732534, _labels=>['lab','el'], these => "are", some => "props" },"roundtrip";
$v = Neo4j::Bolt::NeoValue->_new_from_perl({ _relationship => 154732534, _start => 53243, _end => 235367, _type => "IS_THING", these => "are", some => "props" });
is $v->_neotype, "Relationship", "Relationship with Type and Props";
is_deeply $v->_as_perl,{ _relationship => 154732534, _start => 53243, _end => 235367, _type => "IS_THING", these => "are", some => "props" },"roundtrip";
$v = Neo4j::Bolt::NeoValue->_new_from_perl({ _relationship => 154732534, _start => 53243, _end => 235367, _type => "IS_THING"});
is $v->_neotype, "Relationship", "Relationship with Type only";
is_deeply $v->_as_perl,{ _relationship => 154732534, _start => 53243, _end => 235367, _type => "IS_THING"},"roundtrip";
$v = Neo4j::Bolt::NeoValue->_new_from_perl({ _relationship => 154732534, _start => 53243, _end => 235367});
is $v->_neotype, "Relationship", "Relationship with no type";
is_deeply $v->_as_perl,{ _relationship => 154732534, _start => 53243, _end => 235367},"roundtrip";

TODO: {
  local $TODO = "Implement paths";
  $v = Neo4j::Bolt::NeoValue->_new_from_perl( [ {_node => 1234}, {_relationship=>523, _start => 1234, _end => 5678, _type => "try"}, {_node => 5678} ] );
  is $v->_neotype, "Path", "Path";
}


done_testing;
