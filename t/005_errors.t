use Test::More;
use Module::Build;
use Try::Tiny;
use URI::bolt;
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

unless (defined $build->notes('db_url')) {
  plan skip_all => "Local db tests not requested.";
}

my $url = URI->new($build->notes('db_url'));

if ($build->notes('db_user')) {
  $url->userinfo($build->notes('db_user').':'.$build->notes('db_pass'));
}

ok my $badcxn = Neo4j::Bolt->connect_("bolt://localhost:16444");
ok !$badcxn->connected;
$badcxn->run_query_("match (a) return count(a)",{});
like $badcxn->err_info_->{client_errmsg}, qr/Not connected/, "client error msg correct";

ok my $cxn = Neo4j::Bolt->connect_($url->as_string);
unless ($cxn->connected) {
  diag $cxn->err_info_->{client_errmsg};
}

SKIP: {
  skip "Couldn't connect to server", 1 unless $cxn->connected;
  ok my $stream = $cxn->run_query_(
    "MATCH (a) RETURN labels(a) piece of crap doesn't work",
    {}
   ), 'label count query';
  ok !$stream->success_, "Not Succeeded";
  ok $stream->failure_, "Failure";
  like $stream->err_info_->{eval_errcode}, qr/SyntaxError/, "got syntax error code";
  ok !$stream->err_info_->{client_errno};
  ok !$stream->err_info_->{client_errmsg};
}

done_testing;

