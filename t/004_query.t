use Test::More;
use lib '../lib';
use Neo4j::Bolt;
use strict;

my $url = "bolt://localhost:7687";

ok my $cxn = Neo4j::Bolt->connect_("bolt://localhost:7687");
ok my $stream = $cxn->run_query_(
  "MATCH (a) RETURN head(labels(a)) as lbl, count(a) as ct",
  {}
 );
ok my @names = $stream->fieldnames_;
is_deeply \@names, [qw/lbl ct/], 'col names';
while ( my @row = $stream->fetch_next_ ) {
  print "For label '$row[0]' there are $row[1] nodes.\n";
}
ok $stream = $cxn->run_query_(
   "MATCH (a) RETURN labels(a) as lbls, count(a) as ct",
   {} # parameter hash required
 );
 while ( my @row = $stream->fetch_next_ ) {
   print "For label set [".join(',',@{$row[0]})."] there are $row[1] nodes.\n";
 }

done_testing;

