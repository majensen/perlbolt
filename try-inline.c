#include <neo4j-client.h>

#define CXNCLASS "Neo4p::Agent::Bolt::Cxn"
#define RSCLASS  "Neo4p::Agent::Bolt::ResultStream"
#define PARMCLASS "REST::Neo4p::Agent::Bolt::Parameters"

SV* connect_neo4j( const char* classname, const char* neo4j_url )
{
  SV *cxn;
  SV *cxn_ref;
  neo4j_client_init();
  neo4j_connection_t *connection = neo4j_connect(neo4j_url,NULL,
						 NEO4J_INSECURE);
  if (connection == NULL) {
    neo4j_perror(stderr, errno, "Connection failed");
    return (SV *)NULL;
  }
  else {
    cxn = newSViv((IV) connection);
    cxn_ref = newRV_noinc(cxn);
    sv_bless(cxn_ref, gv_stashpv(CXNCLASS, GV_ADD));
    SvREADONLY_on(cxn);
    return cxn_ref;
  }
}

SV *run_neo4j_query( SV *cxn_ref, const char *cypher_query, SV *params_ref)
{
  neo4j_result_stream_t *res_stream;
  SV *rs;
  SV *rs_ref;
  neo4j_connection_t *cxn;
  neo4j_value_t *params_p = NULL;
  // extract connection
  cxn = (neo4j_connection_t*) SvIV(SvRV(cxn_ref));
  // extract params
  if (params_ref == NULL) {
    params_p = (neo4j_value_t *) NULL;
  }
  else {
    params_p = (neo4j_value_t*) SvIV(SvRV(params_ref));
  }
  res_stream = neo4j_run(cxn, cypher_query, *params_p);
  if (res_stream == NULL) {
    neo4j_perror(stderr, errno, "Failed to run statement");
    return (SV *) NULL;
  }
  else {
    rs = newSViv((IV) res_stream);
    rs_ref = newRV_noinc(rs);
    sv_bless(rs_ref, gv_stashpv(RSCLASS, GV_ADD));
    SvREADONLY(rs);
    return rs_ref;
  }
}


