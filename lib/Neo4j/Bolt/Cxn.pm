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

neo4j_value_t SV_to_neo4j_value(SV *sv);

SV *run_query_( SV *cxn_ref, const char *cypher_query, SV *params_ref)
{
  neo4j_result_stream_t *res_stream;
  SV *rs;
  SV *rs_ref;
  neo4j_connection_t *cxn;
  neo4j_value_t params_p;
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

  if (res_stream == NULL) {
    neo4j_perror(stderr, errno, "Failed to run statement");
    return &PL_sv_undef;
  }
  else {
    rs = newSViv((IV) res_stream);
    rs_ref = newRV_noinc(rs);
    sv_bless(rs_ref, gv_stashpv(RSCLASS, GV_ADD));
    SvREADONLY_on(rs);
    return rs_ref;
  }
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

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN
 majensen -at- cpan -dot- org

=head1 LICENSE

=cut

1;
