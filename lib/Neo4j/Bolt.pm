package Neo4j::Bolt;

BEGIN {
  our $VERSION = "0.01";
  eval 'require Neo4j::Bolt::Config; 1';
#  print $Neo4j::Bolt::Config::extl,"<\n";
}
use Inline 
  C => Config =>
  LIBS => $Neo4j::Bolt::Config::extl,
  INC => $Neo4j::Bolt::Config::extc,  
  version => $VERSION,
  name => __PACKAGE__;

use Inline C => <<'END_BOLT_C';
#include <neo4j-client.h>
#define CXNCLASS "Neo4j::Bolt::Cxn"
#define BUFLEN 100

struct cxn_obj {
  neo4j_connection_t *connection;
  int connected;
  int errnum;
  const char *strerror;
};

typedef struct cxn_obj cxn_obj_t;

void new_cxn_obj(cxn_obj_t **cxn_obj) {
  Newx(*cxn_obj, 1, cxn_obj_t);
  (*cxn_obj)->connection = (neo4j_connection_t *)NULL;
  (*cxn_obj)->connected = 0;
  (*cxn_obj)->errnum = 0;
  (*cxn_obj)->strerror = (char *)NULL;
  return;
}

SV* connect_ ( const char* classname, const char* neo4j_url )
{
  SV *cxn;
  SV *cxn_ref;
  cxn_obj_t *cxn_obj;
  char *climsg;
  new_cxn_obj(&cxn_obj);
  neo4j_client_init();
  cxn_obj->connection = neo4j_connect(neo4j_url,NULL,
						 NEO4J_INSECURE);
  if (cxn_obj->connection == NULL) {
    cxn_obj->errnum = errno;
    Newx(climsg, BUFLEN, char);
    neo4j_strerror(errno, climsg, BUFLEN);
    cxn_obj->strerror = climsg;
  } else {
    cxn_obj->connected = 1;
  }
  cxn = newSViv((IV) cxn_obj);
  cxn_ref = newRV_noinc(cxn);
  sv_bless(cxn_ref, gv_stashpv(CXNCLASS, GV_ADD));
  SvREADONLY_on(cxn);
  return cxn_ref;
}

END_BOLT_C

require Neo4j::Bolt::Cxn;
require Neo4j::Bolt::ResultStream;
require Neo4j::Bolt::TypeHandlersC;

sub connect { shift->connect_(@_) }

=head1 NAME

Neo4j::Bolt - query Neo4j using Bolt protocol

[![Build Status](https://travis-ci.org/majensen/perlbolt.svg?branch=master)](https://travis-ci.org/majensen/perlbolt)

=head1 SYNOPSIS

 use Neo4j::Bolt;
 $cxn = Neo4j::Bolt->connect("bolt://localhost:7687");
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

=head2 Return Types

L<Neo4j::Bolt::ResultStream> returns rows resulting from queries made 
via a L<Neo4j::Bolt::Cxn>. These rows are simple arrays of scalars and/or
references. These represent Neo4j types according to the following:

 Neo4j type       Perl representation
 ----- ----       ---- --------------
 Null             undef
 Bool             JSON::PP::Boolean (acts like 0 or 1)
 Int              scalar
 Float            scalar
 String           scalar
 Bytes            scalar
 List             arrayref
 Map              hashref
 Node             hashref
 Relationship     hashref
 Path             arrayref of hashrefs

Nodes, Relationships and Paths are represented in L<REST::Neo4p> "as_simple()"
formats:

 Node:
 { _node => $node_id, _labels => [ $label1, $label2, ...],
   prop1 => $value1, prop2 => $value2, ...}

 Relationship:
 { _relationship => $reln_id, 
   _start => $start_node_id, _end => $end_node_id,
   prop1 => $value1, prop2 => $value2, ...}

 Path:
 [ $node1, $reln12, $node2, $reln23, $node3,...]

=head1 METHODS

=over 

=item connect_($url)

Class method, connect to Neo4j server. The URL scheme must be C<'bolt'>, as in

  $cxn = bolt://localhost:7687

Returns object of type L<Neo4j::Bolt::Cxn>, which accepts Cypher queries and
returns a L<Neo4j::Bolt::ResultStream>.

=back

=head1 SEE ALSO

L<Neo4j::Bolt::Cxn>, L<Neo4j::Bolt::ResultStream>.

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN
 majensen -at- cpan -dot- org

=head1 CONTRIBUTORS

=over

=item Arne Johannessen (@johannessen)

=back

=head1 LICENSE

This software is Copyright (c) 2019 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004


=cut

1;
