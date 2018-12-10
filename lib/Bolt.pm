package Bolt;
our $VERSION = "0.01";
use Inline C => Config => LIBS => '-lneo4j-client -lssl -lcrypto';
use Inline C => <<'END_BOLT_C';
#include <neo4j-client.h>

#define CXNCLASS "Bolt::Cxn"

SV* connect_ ( const char* classname, const char* neo4j_url )
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

END_BOLT_C

1;

package Bolt::Cxn;

use Inline C => Config => LIBS => '-lneo4j-client -lssl -lcrypto';
use Inline C => <<'END_BOLT_CXN_C';
#include <neo4j-client.h>
#define RSCLASS  "Bolt::ResultStream"
#define PARMCLASS "Bolt::Parameters"

SV *run_query( SV *cxn_ref, const char *cypher_query, SV *params_ref)
{
  neo4j_result_stream_t *res_stream;
  SV *rs;
  SV *rs_ref;
  neo4j_connection_t *cxn;
  neo4j_value_t params_p;
  // extract connection
  cxn = (neo4j_connection_t*) SvIV(SvRV(cxn_ref));
  // extract params
  if (SvOK(params_ref)) {
    params_p = *((neo4j_value_t*) SvIV(SvRV(params_ref)));
    res_stream = neo4j_run(cxn, cypher_query, params_p);
  }
  else {
    res_stream = neo4j_run(cxn, cypher_query, neo4j_null);
  }

  if (res_stream == NULL) {
    neo4j_perror(stderr, errno, "Failed to run statement");
    return (SV *) NULL;
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
  rc = neo4j_reset( (neo4j_connection_t *)SvIV(SvRV(cxn_ref)) );
  if (rc < 0) {
    neo4j_perror(stderr,errno,"Problem resetting connection");
  } 
  return;
}

void DESTROY (SV *cxn_ref)
{
  neo4j_close( (neo4j_connection_t *)SvIV(SvRV(cxn_ref)) );
  return;
}

END_BOLT_CXN_C

1;

package Bolt::ResultStream;

use Inline C => Config => LIBS => '-lneo4j-client -lssl -lcrypto';
use Inline C => <<'END_BOLT_RS_C';
#include <neo4j-client.h>
#define RSCLASS  "Bolt::ResultStream"
#define RCLASS  "Bolt::Result"
#define PARMCLASS "Bolt::Parameters"

struct neo4j_rs_result {
  neo4j_result_stream_t *rs;
  neo4j_result_t *r;
};

typedef struct neo4j_rs_result neo4j_rs_result_t;

SV *fetch_next_ (SV *rs_ref) {
  SV *r;
  SV *r_ref;
  neo4j_result_t *result;
  neo4j_rs_result_t *rs_result;
  neo4j_result_stream_t *rs;
  rs = (neo4j_result_stream_t *) SvIV(SvRV(rs_ref));
  result = neo4j_fetch_next(rs);
  if (result == NULL) {
    if (errno) {
      neo4j_perror(stderr,errno,"Fetch failed");
    }
    return (SV *) NULL;
  }
  Newx(rs_result, 1, neo4j_rs_result_t);
  rs_result->rs = rs;
  rs_result->r = result;
  r = newSViv((IV) rs_result);
  r_ref = newRV_noinc(r);
  sv_bless(r_ref, gv_stashpv(RCLASS, GV_ADD));
  SvREADONLY_on(r);
  return r_ref;
}

int nfields_(SV *rs_ref) {
  return neo4j_nfields((neo4j_result_stream_t *)SvIV(SvRV(rs_ref)));
}

void fieldnames_ (SV *rs_ref) {
  neo4j_result_stream_t *rs;
  int nfields;
  int i;
  rs = (neo4j_result_stream_t *)SvIV(SvRV(rs_ref));
  nfields = neo4j_nfields(rs);
  Inline_Stack_Vars;
  Inline_Stack_Reset;
  for (i = 0; i < nfields; i++) 
    Inline_Stack_Push(sv_2mortal(newSVpv(neo4j_fieldname(rs,i),0)));
  Inline_Stack_Done;
  return;
}

void DESTROY (SV *rs_ref) {
  neo4j_close_results((neo4j_result_stream_t *)SvIV(SvRV(rs_ref)));
  return;
}

END_BOLT_RS_C

1;

package Bolt::Result;
use lib '../lib';
use Bolt::TypeHandlersC;

# building libneo4j-client
# adding function prototypes to neo4j-client.h.in to expose them in the
# libraries properly
#   struct neo4j_iostream *neo4j_posix_iostream(int fd);
#   int neo4j_serialize(struct neo4j_value v, struct neo4j_iostream *stream);
#   neo4j_value_t neo4j_identity(long long);               
#   neo4j_value_t neo4j_node(const neo4j_value_t*);	      
#   neo4j_value_t neo4j_relationship(const neo4j_value_t*);

# ./configure --without-tls<FIXME> --disable-tools

# Result = Row
# for a neo4j_result_t, need to parse the fields:
#  - identify the neo4j_type of the field value
#  - extract the value into a perly structure suited to the type
#  
# return an array of perly values (each of which may be a hash)
# return an array of fieldnames in order (suitable for creating set of keys
#  for a hash of returned values)

use Inline C => Config => LIBS => '-lneo4j-client -lssl -lcrypto';
use Inline C => <<'END_BOLT_R_C';
#include <neo4j-client.h>

// neo4j_type_t neo4j_type( neo4j_value_t value ) - integer code
// const char* neo4j_fieldname (neo4j_result_stream_t *, unsigned int idx)
// unsigned int neo4j_nfields ( neo4j_results_stream_t * )
// neo4j_value_t neo4j_result_field ( const neo4j_result_t *, unsigned int idx)
// neo4j_map()

struct neo4j_rs_result {
  neo4j_result_stream_t *rs;
  neo4j_result_t *r;
};

typedef struct neo4j_rs_result neo4j_rs_result_t;

int nfields_(SV *r_ref) {
  return neo4j_nfields( ((neo4j_rs_result_t *) SvIV(SvRV(r_ref)))->rs );
}

int _r_nfields_(neo4j_rs_result_t *rsr) {
  return neo4j_nfields( rsr->rs );
}

const char* _r_fieldname_ (neo4j_rs_result_t *rsr, unsigned int i) {
  return neo4j_fieldname( rsr->rs, i );
}

void DESTROY (SV *r_ref) {
  neo4j_rs_result_t *rsr;
  rsr = (neo4j_rs_result_t *) SvIV(SvRV(r_ref));
  Safefree(rsr);
}

END_BOLT_R_C
1;
