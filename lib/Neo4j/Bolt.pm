package Neo4j::Bolt;
BEGIN {
  our $VERSION = "0.01";
}
use Inline 
  C => Config => LIBS => '-lneo4j-client -lssl -lcrypto',
  version => $VERSION,
  name => __PACKAGE__;

use Inline C => <<'END_BOLT_C';
#include <neo4j-client.h>

#define CXNCLASS "Neo4j::Bolt::Cxn"

SV* connect_ ( const char* classname, const char* neo4j_url )
{
  SV *cxn;
  SV *cxn_ref;
  neo4j_client_init();
  neo4j_connection_t *connection = neo4j_connect(neo4j_url,NULL,
						 NEO4J_INSECURE);
  if (connection == NULL) {
    neo4j_perror(stderr, errno, "Connection failed");
    return &PL_sv_undef;
  }
  else {
    cxn = newSViv((IV) connection);
    cxn_ref = newRV_noinc(cxn);
    sv_bless(cxn_ref, gv_stashpv(CXNCLASS, GV_ADD));
    SvREADONLY_on(cxn);
    return cxn_ref;
  }
}

END_BOLT_C

require Neo4j::Bolt::Cxn;
require Neo4j::Bolt::ResultStream;
require Neo4j::Bolt::TypeHandlersC;

=head1 NAME

Neo4j::Bolt - query Neo4j using Bolt protocol

=head1 SYNOPSIS

 use Neo4j::Bolt;
 $cxn = Neo4j::Bolt->connect_("bolt://localhost:7687");
 $stream = $cxn->run_query_(
   "MATCH (a) RETURN head(labels(a)) as lbl, count(a) as ct",
   {} # parameter hash required
 );
 @names = $stream->fieldnames_;
 while ( my @row = $stream->fetch_next_ ) {
   print "For label '$row[0]' there are $row[1] nodes.\n";
 }
 $stream = $cxn->run_query_(
   "MATCH (a) RETURN labels(a) as lbls, count(a) as ct",
   {} # parameter hash required
 );
 while ( my @row = $stream->fetch_next_ ) {
   print "For label set [".join(',',@{$row[0]})."] there are $row[1] nodes.\n";
 }


=head1 DESCRIPTION

L<Neo4j::Bolt> is a Perl wrapper around Chris Leishmann's excellent
L<libneo4j-client|https://github.com/cleishm/libneo4j-client> library
implementing the Neo4j L<Bolt|https://boltprotocol.org/> network
protocol. It uses Ingy's L<Inline::C> to do all the hard XS work.

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN
 majensen -at- cpan -dot- org

=head1 LICENSE


=cut

1;
