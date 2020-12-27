use Test::More;
use Try::Tiny;
use URI::bolt;
use Cwd qw/getcwd/;
use Neo4j::Bolt;
use File::Spec;
use strict;

my $neo_info;
my $nif = File::Spec->catfile('t','neo_info');
if (-e $nif ) {
    local $/;
    open my $fh, "<", $nif or die $!;
    my $val = <$fh>;
    $val =~ s/^.*?(=.*)$/\$neo_info $1/s;
    eval $val;
}

unless (defined $neo_info) {
  plan skip_all => "DB tests not requested";
}

my $url = URI->new($neo_info->{host});

if ($neo_info->{user}) {
  $url->userinfo($neo_info->{user}.':'.$neo_info->{pass});
}

ok my $badcxn = Neo4j::Bolt->connect("bolt://localhost:16444");
ok !$badcxn->connected;
$badcxn->run_query("match (a) return count(a)");
like $badcxn->errmsg, qr/Not connected/, "client error msg correct";

ok my $cxn = Neo4j::Bolt->connect($url->as_string);
unless ($cxn->connected) {
  diag $cxn->errmsg;
}

SKIP: {
  skip "Couldn't connect to server", 1 unless $cxn->connected;
  ok my $stream = $cxn->run_query(
    "MATCH (a) RETURN labels(a) piece of crap doesn't work",
   ), 'label count query';
  ok !$stream->success, "Not Succeeded";
  ok $stream->failure, "Failure";
  like $stream->server_errcode, qr/SyntaxError/, "got syntax error code";

  $cxn = Neo4j::Bolt->connect('snarf://localhost:7687');
  like $cxn->errmsg, qr/scheme/, "got errmsg";
  is $cxn->errnum, -12, "got error";
  diag $cxn->errmsg;

}

done_testing;

