use lib '.';
use Bolt;
  
my $c = Bolt->connect_("neo4j://127.0.0.1:7687");
my $pm;
my $rs = $c->run_query("match (a) return labels(a), a.name",$pm);
my $r = $rs->fetch_next_;
1;
