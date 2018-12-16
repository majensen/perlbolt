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

1;

package Bolt::Cxn;

use Inline C => Config => LIBS => '-lneo4j-client -lssl -lcrypto';
use Inline C => <<'END_BOLT_CXN_C';
#include <neo4j-client.h>
#define RSCLASS  "Bolt::ResultStream"
#define PARMCLASS "Bolt::Parameters"
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))

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
  if (params_ref && SvOK(params_ref)) {
    params_p = *C_PTR_OF(params_ref,neo4j_value_t);
    if ( neo4j_type(params_p) != NEO4J_MAP ) { // ignore
      params_p = neo4j_null;
    }
  }
  else {
    params_p = neo4j_null;
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

1;

package Bolt::ResultStream;

use Inline C => Config => LIBS => '-lneo4j-client -lssl -lcrypto';
use Inline C => <<'END_BOLT_RS_C';
#include <neo4j-client.h>
#define RSCLASS  "Bolt::ResultStream"
#define RCLASS  "Bolt::Result"
#define PARMCLASS "Bolt::Parameters"
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))

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
  rs = C_PTR_OF(rs_ref,neo4j_result_stream_t);
  result = neo4j_fetch_next(rs);
  if (result == NULL) {
    if (errno) {
      neo4j_perror(stderr,errno,"Fetch failed");
    }
    return &PL_sv_undef;
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
  return neo4j_nfields( C_PTR_OF(rs_ref,neo4j_result_stream_t) );
}

void fieldnames_ (SV *rs_ref) {
  neo4j_result_stream_t *rs;
  int nfields;
  int i;
  rs = C_PTR_OF(rs_ref,neo4j_result_stream_t);
  nfields = neo4j_nfields(rs);
  Inline_Stack_Vars;
  Inline_Stack_Reset;
  for (i = 0; i < nfields; i++) 
    Inline_Stack_Push(sv_2mortal(newSVpv(neo4j_fieldname(rs,i),0)));
  Inline_Stack_Done;
  return;
}

void DESTROY (SV *rs_ref) {
  neo4j_close_results(C_PTR_OF(rs_ref,neo4j_result_stream_t));
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
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))

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
  return neo4j_nfields( C_PTR_OF(r_ref,neo4j_rs_result_t)->rs );
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
