package Neo4j::Bolt::Cxn;
BEGIN {
  our $VERSION = "0.01";
  require Neo4j::Bolt::TypeHandlersC;
  eval 'require Neo4j::Bolt::Config; 1';
}
use Inline C => Config => LIBS => $Neo4j::Bolt::Config::extl,
  INC => $Neo4j::Bolt::Config::extc,
  version => $VERSION,
  name => __PACKAGE__;
  
use Inline C => <<'END_BOLT_CXN_C';
#include <neo4j-client.h>
#define RSCLASS  "Neo4j::Bolt::ResultStream"
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))
#define BUFLEN 100

neo4j_value_t SV_to_neo4j_value(SV *sv);

struct rs_obj {
  neo4j_result_stream_t *res_stream;
  int succeed;
  int fail;
  struct neo4j_failure_details *failure_details;
  char *eval_errcode;
  char *eval_errmsg;
  int errnum;
  const char *strerror;
};

typedef struct rs_obj rs_obj_t;

void new_rs_obj (rs_obj_t **rs_obj) {
  Newx(*rs_obj, 1, rs_obj_t);
  (*rs_obj)->succeed = -1;  
  (*rs_obj)->fail = -1;  
  (*rs_obj)->failure_details = (struct neo4j_failure_details *) NULL;
  (*rs_obj)->eval_errcode = (char *) NULL;
  (*rs_obj)->eval_errmsg = (char *) NULL;
  (*rs_obj)->errnum = 0;
  (*rs_obj)->strerror = (char *) NULL;
  return;
}

SV *run_query_( SV *cxn_ref, const char *cypher_query, SV *params_ref)
{
  neo4j_result_stream_t *res_stream;
  rs_obj_t *rs_obj;
  char buf[BUFLEN];
  SV *rs;
  SV *rs_ref;
  neo4j_connection_t *cxn;
  neo4j_value_t params_p;
  new_rs_obj(&rs_obj);
  // extract connection
  cxn = C_PTR_OF(cxn_ref,neo4j_connection_t);
  // extract params
  if (SvROK(params_ref) && (SvTYPE(SvRV(params_ref))==SVt_PVHV)) {
    params_p = SV_to_neo4j_value(params_ref);
  }
  else {
    perror("Parameter arg must be a hash reference\n");
    return &PL_sv_undef;
  }
  res_stream = neo4j_run(cxn, cypher_query, params_p);
  rs_obj->res_stream = res_stream;
  if (res_stream == NULL) {
    rs_obj->succeed=0;
    rs_obj->fail=1;
    rs_obj->errnum = errno;
    rs_obj->strerror = neo4j_strerror( errno, buf, BUFLEN );
  }
  rs = newSViv((IV) rs_obj);
  rs_ref = newRV_noinc(rs);
  sv_bless(rs_ref, gv_stashpv(RSCLASS, GV_ADD));
  SvREADONLY_on(rs);
  return rs_ref;
}

void reset_ (SV *cxn_ref) 
{
  int rc;
  rc = neo4j_reset( C_PTR_OF(cxn_ref,neo4j_connection_t) );
  if (rc < 0) {
    neo4j_perror(stderr,errno,"Problem resetting connection");
  } 
  return;
}

void DESTROY (SV *cxn_ref)
{
  neo4j_close( C_PTR_OF(cxn_ref,neo4j_connection_t) );
  return;
}

END_BOLT_CXN_C

=head1 NAME

Neo4j::Bolt::Cxn - Container for a Neo4j Bolt connection

=head1 SYNOPSIS

 use Neo4j::Bolt;
 $cxn = Neo4j::Bolt->connect_("bolt://localhost:7687");
 $stream = $cxn->run_query_(
   "MATCH (a) RETURN head(labels(a)) as lbl, count(a) as ct",
   {} # parameter hash required
 );

=head1 DESCRIPTION

L<Neo4j::Bolt::Cxn> is a container for a Bolt connection, instantiated by
a call to C<Neo4j::Bolt::connect_()>.

=head1 METHODS

=over

=item run_query_( $cypher_query, $param_hash )

Run a L<Cypher|https://neo4j.com/docs/cypher-manual/current/> query on
the server. Returns a L<Neo4j::Bolt::ResultStream> which can be iterated
to retrieve query results as Perl types and structures. C<$param_hash> is
a hashref of the form C<{ param => $value, ... }>. If there are no params
to be set, use C<{}>.

=item reset_()

Send a RESET message to the Neo4j server. According to the L<Bolt
protocol|https://boltprotocol.org/v1/>, this should force any currently
processing query to abort, forget any pending queries, clear any 
failure state, dispose of outstanding result records, and roll back 
the current transaction.

=back

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN
 majensen -at- cpan -dot- org

=head1 LICENSE

This software is Copyright (c) 2019 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

1;
