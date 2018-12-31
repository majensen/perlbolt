use Test::More;
use Module::Build;
use Try::Tiny;
use Neo4j::Bolt;
use strict;

my $build;
try {
  $build = Module::Build->current();
} catch {
  undef $build;
};

unless (defined $build) {
  plan skip_all => "No build context. Run tests with ./Build test.";
}

ok my $cxn = Neo4j::Bolt->connect_($build->notes('db_url'));
ok my $stream = $cxn->run_query_(
  "MATCH (a) RETURN labels(a) as lbl, count(a) as ct",
  {}
 ), 'label count query';
ok my @names = $stream->fieldnames_;
is_deeply \@names, [qw/lbl ct/], 'col names';
my $total_nodes = 0;
while ( my @row = $stream->fetch_next_ ) {
  unless ($total_nodes) {
    is ref $row[0], 'ARRAY', 'got array for labels()';
  }
    $total_nodes += $row[1];
}

ok $stream = $cxn->run_query_("MATCH (a) RETURN count(a)", {}), 'total count query';
is (($stream->fetch_next_)[0], $total_nodes, "total nodes check");

ok $stream = $cxn->run_query_(
  "MATCH p = (a)-->(b) RETURN p LIMIT 1",
  {}
 ), 'path query';

my ($pth) = $stream->fetch_next_;
is ref $pth, 'ARRAY', 'got path as ARRAY';
is scalar @$pth, 3, 'path array length';
ok defined $pth->[0]->{_node}, 'start node';
ok defined $pth->[2]->{_node}, 'end node';
ok defined $pth->[1]->{_relationship}, 'relationship';
is $pth->[1]->{_start}, $pth->[0]->{_node}, 'relationship start correct';
is $pth->[1]->{_end},$pth->[2]->{_node}, 'relationship end correct';

ok $stream = $cxn->run_query_(
  "MATCH p = (a)<--(b) RETURN p LIMIT 1",
  {}
 ), 'path query 2';

($pth) = $stream->fetch_next_;
is ref $pth, 'ARRAY', 'got path as ARRAY';
is scalar @$pth, 3, 'path array length';
ok defined $pth->[0]->{_node}, 'start node';
ok defined $pth->[2]->{_node}, 'end node';
ok defined $pth->[1]->{_relationship}, 'relationship';
is $pth->[1]->{_end}, $pth->[0]->{_node}, 'relationship start correct';
is $pth->[1]->{_start},$pth->[2]->{_node}, 'relationship end correct';

ok $stream = $cxn->run_query_(
  "CALL db.labels()", {} ), 'call db.labels()';
my @lbl;
while ( my @row = $stream->fetch_next_ ) {
  push @lbl, $row[0];
}

for (@lbl) {
  ok $stream = $cxn->run_query_(
    'MATCH (a) WHERE $lbl in labels(a) RETURN count(a)',
    { lbl => $_} ), 'query w/parameters';
  my $ct = ($stream->fetch_next_)[0];
  cmp_ok( $ct, ">", 0, "label '$_' count positive ($ct)");
}
	  


done_testing;

