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
#include <errno.h>
#define RSCLASS  "Neo4j::Bolt::ResultStream"
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))
#define BUFLEN 100

neo4j_value_t SV_to_neo4j_value(SV *sv);

struct cxn_obj {
  neo4j_connection_t *connection;
  int connected;
  int errnum;
  const char *strerror;
};

typedef struct cxn_obj cxn_obj_t;

struct rs_obj {
  neo4j_result_stream_t *res_stream;
  int succeed;
  int fail;
  const struct neo4j_failure_details *failure_details;
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
  cxn_obj_t *cxn_obj;
  rs_obj_t *rs_obj;
  const char *evalerr, *evalmsg;
  char *climsg;
  char *s, *t;
  int fail;
  SV *rs;
  SV *rs_ref;
  neo4j_connection_t *cxn;
  neo4j_value_t params_p;
  new_rs_obj(&rs_obj);
  // extract connection
  cxn_obj = C_PTR_OF(cxn_ref,cxn_obj_t);
  if (!cxn_obj->connected) {
    cxn_obj->errnum = ENOTCONN;
    cxn_obj->strerror = "Not connected";
    return &PL_sv_undef;    
  }

  // extract params
  if (SvROK(params_ref) && (SvTYPE(SvRV(params_ref))==SVt_PVHV)) {
    params_p = SV_to_neo4j_value(params_ref);
  }
  else {
    perror("Parameter arg must be a hash reference\n");
    return &PL_sv_undef;
  }
  res_stream = neo4j_run(cxn_obj->connection, cypher_query, params_p);
  fail = neo4j_check_failure(res_stream);
  rs_obj->res_stream = res_stream;
  if (res_stream == NULL) {
    rs_obj->succeed=0;
    rs_obj->fail=1;
    rs_obj->errnum = errno;
    Newx(climsg, BUFLEN, char);
    rs_obj->strerror = neo4j_strerror(errno, climsg, BUFLEN);

  } else if (fail) {
      rs_obj->succeed=0;
      rs_obj->fail=1;
      rs_obj->errnum = errno;
      if (fail == NEO4J_STATEMENT_EVALUATION_FAILED) {
        rs_obj->failure_details = neo4j_failure_details(res_stream);
        evalerr = neo4j_error_code(res_stream);
        Newx(s, strlen(evalerr)+1,char);
        rs_obj->eval_errcode = strcpy(s,evalerr);
        evalmsg = neo4j_error_message(res_stream);
        Newx(t, strlen(evalmsg)+1,char);
        rs_obj->eval_errmsg = strcpy(t,evalmsg);
      } else {
        Newx(climsg, BUFLEN, char);
        rs_obj->strerror = neo4j_strerror(errno, climsg, BUFLEN);
      }
  } else {
    rs_obj->succeed=1;
    rs_obj->fail=0;
  }
  rs = newSViv((IV) rs_obj);
  rs_ref = newRV_noinc(rs);
  sv_bless(rs_ref, gv_stashpv(RSCLASS, GV_ADD));
  SvREADONLY_on(rs);
  return rs_ref;
}

int connected(SV *cxn_ref) {
  return C_PTR_OF(cxn_ref,cxn_obj_t)->connected;
}

SV *err_info_ (SV *cxn_ref) {
  cxn_obj_t *cxn_obj;
  HV *hv;
  cxn_obj = C_PTR_OF(cxn_ref,cxn_obj_t);
  hv = newHV();
  hv_stores(hv, "client_errno", newSViv((IV) cxn_obj->errnum));
  hv_stores(hv, "client_errmsg", cxn_obj->strerror ? newSVpv(cxn_obj->strerror, strlen(cxn_obj->strerror)): &PL_sv_undef );
  return newRV_noinc( (SV*) hv );
}

void reset_ (SV *cxn_ref) 
{
  int rc;
  char *climsg;
  cxn_obj_t *cxn_obj;
  cxn_obj = C_PTR_OF(cxn_ref,cxn_obj_t);
  rc = neo4j_reset( cxn_obj->connection );
  if (rc < 0) {
    cxn_obj->errnum = errno;
    Newx(climsg, BUFLEN, char);
    cxn_obj->strerror = neo4j_strerror(errno, climsg, BUFLEN);
  } 
  return;
}

void DESTROY (SV *cxn_ref)
{
  neo4j_close( C_PTR_OF(cxn_ref,cxn_obj_t)->connection );
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
