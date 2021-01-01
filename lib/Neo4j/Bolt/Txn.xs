#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ingyINLINE.h"
#include <neo4j-client.h>
#include <errno.h>
#include <string.h>
#include "connection.h"
#define RSCLASS  "Neo4j::Bolt::ResultStream"
#define TXNCLASS  "Neo4j::Bolt::Txn"
#define BUFLEN 256
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))

neo4j_value_t SV_to_neo4j_value(SV *sv);

struct txn_obj {
  neo4j_transaction_t *tx;
  int errnum;
  const char* strerror;
};

typedef struct txn_obj txn_obj_t;

struct cxn_obj {
  neo4j_connection_t *connection;
  int connected;
  int errnum;
  const char *strerror;
};

void new_txn_obj( txn_obj_t **txn_obj) {
  Newx(*txn_obj,1,txn_obj_t);
  (*txn_obj)->errnum = 0;
  char *buf;
  Newx(buf, BUFLEN, char);
  stpcpy(buf,"");
  (*txn_obj)->strerror = buf;
  return;
}

typedef struct cxn_obj cxn_obj_t;

struct rs_stats {
  unsigned long long result_count;
  unsigned long long available_after;
  unsigned long long consumed_after;
  struct neo4j_update_counts *update_counts;
};

typedef struct rs_stats rs_stats_t;

struct rs_obj {
  neo4j_result_stream_t *res_stream;
  int succeed;
  int fail;
  int fetched;
  const struct neo4j_failure_details *failure_details;
  rs_stats_t *stats;
  char *eval_errcode;
  char *eval_errmsg;
  int errnum;
  const char *strerror;
};

typedef struct rs_obj rs_obj_t;
int update_errstate_rs_obj (rs_obj_t *rs_obj);
void reset_errstate_rs_obj (rs_obj_t *rs_obj);

void new_rs_uc( struct neo4j_update_counts **uc) {
  Newx(*uc, 1, struct neo4j_update_counts);
  (*uc)->nodes_created=0;
  (*uc)->nodes_deleted=0;
  (*uc)->relationships_created=0;
  (*uc)->relationships_deleted=0;
  (*uc)->properties_set=0;
  (*uc)->labels_added=0;
  (*uc)->labels_removed=0;
  (*uc)->indexes_added=0;
  (*uc)->indexes_removed=0;
  (*uc)->constraints_added=0;
  (*uc)->constraints_removed=0;
  return;
}

void new_rs_stats( rs_stats_t **stats ) {
  struct neo4j_update_counts *uc;
  new_rs_uc(&uc);
  Newx(*stats, 1, rs_stats_t);
  (*stats)->result_count = 0;
  (*stats)->available_after = 0;
  (*stats)->consumed_after = 0;
  (*stats)->update_counts = uc;
  return;
}

void new_rs_obj (rs_obj_t **rs_obj) {
  rs_stats_t *stats;
  Newx(*rs_obj, 1, rs_obj_t);
  new_rs_stats(&stats);
  (*rs_obj)->succeed = -1;
  (*rs_obj)->fail = -1;
  (*rs_obj)->fetched = 0;
  (*rs_obj)->failure_details = (struct neo4j_failure_details *) NULL;
  (*rs_obj)->stats = stats;
  (*rs_obj)->eval_errcode = "";
  (*rs_obj)->eval_errmsg = "";
  (*rs_obj)->errnum = 0;
  (*rs_obj)->strerror = "";
  return;
}

void reset_errstate_rs_obj (rs_obj_t *rs_obj) {
  rs_obj->succeed = -1;
  rs_obj->fail = -1;
  rs_obj->failure_details = (struct neo4j_failure_details *) NULL;
  rs_obj->eval_errcode = "";
  rs_obj->eval_errmsg = "";
  rs_obj->errnum = 0;
  rs_obj->strerror = "";
  return;
}

int update_errstate_rs_obj (rs_obj_t *rs_obj) {
  const char *evalerr, *evalmsg;
  char *climsg;
  char *s, *t;
  int fail;
  fail = neo4j_check_failure(rs_obj->res_stream);
  if (fail) {
    rs_obj->succeed = 0;
    rs_obj->fail = 1;
    rs_obj->fetched = -1;
    rs_obj->errnum = fail;
    Newx(climsg, BUFLEN, char);
    rs_obj->strerror = neo4j_strerror(fail, climsg, BUFLEN);
    if (fail == NEO4J_STATEMENT_EVALUATION_FAILED) {
      rs_obj->failure_details = neo4j_failure_details(rs_obj->res_stream);
      evalerr = neo4j_error_code(rs_obj->res_stream);
      Newx(s, strlen(evalerr)+1,char);
      rs_obj->eval_errcode = strcpy(s,evalerr);
      evalmsg = neo4j_error_message(rs_obj->res_stream);
      Newx(t, strlen(evalmsg)+1,char);
      rs_obj->eval_errmsg = strcpy(t,evalmsg);
    }
  }
  else {
    rs_obj->succeed = 1;
    rs_obj->fail = 0;
  }
  return fail;
}

// class method
SV *begin_( const char* classname, SV *cxn_ref, int tx_timeout, const char *mode, const char *dbname) {
  txn_obj_t *txn_obj;
  char *climsg;
  new_txn_obj(&txn_obj);
  cxn_obj_t *cxn_obj = C_PTR_OF(cxn_ref, cxn_obj_t);
  neo4j_transaction_t *tx = neo4j_begin_tx(cxn_obj->connection, tx_timeout,
                                             mode, dbname);
  txn_obj->tx = tx;
  if (tx == NULL) {
    txn_obj->errnum = errno;
    Newx(climsg, BUFLEN, char);
    txn_obj->strerror = neo4j_strerror(errno,climsg,BUFLEN);
  }
  SV *txn = newSViv((IV) txn_obj);
  SV *txn_ref = newRV_noinc(txn);
  sv_bless(txn_ref, gv_stashpv(TXNCLASS, GV_ADD));
  SvREADONLY_on(txn);
  return txn_ref;
}

int commit_(SV *txn_ref) {
  return neo4j_commit( C_PTR_OF(txn_ref,txn_obj_t)->tx );
}

int rollback_(SV *txn_ref) {
  return neo4j_rollback( C_PTR_OF(txn_ref,txn_obj_t)->tx );
}

SV *run_query_(SV *txn_ref, const char *cypher_query, SV *params_ref, int send) {
  neo4j_result_stream_t *res_stream;
  txn_obj_t *txn_obj;
  rs_obj_t *rs_obj;
  const char *evalerr, *evalmsg;
  char *climsg;
  char *s, *t;
  int fail;
  SV *rs;
  SV *rs_ref;
  neo4j_value_t params_p;

  new_rs_obj(&rs_obj);
  // extract connection
  txn_obj = C_PTR_OF(txn_ref,txn_obj_t);

  // extract params
  if (SvROK(params_ref) && (SvTYPE(SvRV(params_ref))==SVt_PVHV)) {
    params_p = SV_to_neo4j_value(params_ref);
  }
  else {
    perror("Parameter arg must be a hash reference\n");
    return &PL_sv_undef;
  }
  res_stream = neo4j_run_in_tx(C_PTR_OF(txn_ref,txn_obj_t)->tx, cypher_query, params_p);
  rs_obj->res_stream = res_stream;
  fail = update_errstate_rs_obj(rs_obj);
  if (send >= 1) {
    rs_obj->fetched = 1;
  }
  rs = newSViv((IV) rs_obj);
  rs_ref = newRV_noinc(rs);
  sv_bless(rs_ref, gv_stashpv(RSCLASS, GV_ADD));
  SvREADONLY_on(rs);
  return rs_ref;
}

int errnum_(SV *txn_ref) {
  return C_PTR_OF(txn_ref,txn_obj_t)->errnum;
}

const char *errmsg_(SV *txn_ref) {
  return C_PTR_OF(txn_ref,txn_obj_t)->strerror;
}


MODULE = Neo4j::Bolt::Txn  PACKAGE = Neo4j::Bolt::Txn  

PROTOTYPES: DISABLE


SV *
begin_ (classname, cxn_ref, tx_timeout, mode, dbname)
	const char *	classname
	SV *	cxn_ref
	int	tx_timeout
	const char *	mode
	const char *	dbname

int
commit_ (txn_ref)
	SV *	txn_ref

int
rollback_ (txn_ref)
	SV *	txn_ref

SV *
run_query_ (txn_ref, cypher_query, params_ref, send)
	SV *	txn_ref
	const char *	cypher_query
	SV *	params_ref
	int	send

int
errnum_ (txn_ref)
	SV *	txn_ref

const char *
errmsg_ (txn_ref)
	SV *	txn_ref

