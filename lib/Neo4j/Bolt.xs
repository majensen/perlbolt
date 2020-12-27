#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ingyINLINE.h"
// #include <neo4j_config_struct.h>
#include <neo4j-client.h>
#include "connection.h"
#define CXNCLASS "Neo4j::Bolt::Cxn"
#define BUFLEN 100

struct cxn_obj {
  neo4j_connection_t *connection;
  int connected;
  int major_version;
  int minor_version;
  int errnum;
  const char *strerror;
};

typedef struct cxn_obj cxn_obj_t;

void new_cxn_obj(cxn_obj_t **cxn_obj) {
  Newx(*cxn_obj, 1, cxn_obj_t);
  (*cxn_obj)->connection = (neo4j_connection_t *)NULL;
  (*cxn_obj)->connected = 0;
  (*cxn_obj)->errnum = 0;
  (*cxn_obj)->major_version = 0;
  (*cxn_obj)->minor_version = 0;
  (*cxn_obj)->strerror = "";
  return;
}

SV* connect_ ( const char* classname, const char* neo4j_url,
               int timeout, bool encrypt,
               const char* tls_ca_dir, const char* tls_ca_file,
               const char* tls_pk_file, const char* tls_pk_pass )
{
  SV *cxn;
  SV *cxn_ref;
  cxn_obj_t *cxn_obj;
  char *climsg, *s;
  neo4j_config_t *config;
  new_cxn_obj(&cxn_obj);
  neo4j_client_init();
  config = neo4j_new_config();
  config->connect_timeout = (time_t) timeout;
  if (strlen(tls_ca_dir)) {
    neo4j_config_set_TLS_ca_dir(config, tls_ca_dir);
  }
  if (strlen(tls_ca_file)) {
    neo4j_config_set_TLS_ca_file(config, tls_ca_file);
  }
  if (strlen(tls_pk_file)) {
    neo4j_config_set_TLS_private_key(config, tls_pk_file);
  }
  if (strlen(tls_pk_pass)) {
    neo4j_config_set_TLS_private_key_password(config, tls_pk_pass);
  }

  cxn_obj->connection = neo4j_connect( neo4j_url, config,
                                       encrypt ? 0 : NEO4J_INSECURE );

  if (cxn_obj->connection == NULL) {
    cxn_obj->errnum = errno;
    Newx(climsg, BUFLEN, char);
    cxn_obj->strerror = neo4j_strerror(errno, climsg, BUFLEN);
  } else {
    if ( encrypt && ! neo4j_connection_is_secure(cxn_obj->connection) ) {
      warn("Bolt connection not secure!");
    }
    cxn_obj->major_version = cxn_obj->connection->version;
    cxn_obj->minor_version = cxn_obj->connection->minor_version;
    cxn_obj->connected = 1;
    cxn_obj->strerror = "";
  }
  cxn = newSViv((IV) cxn_obj);
  cxn_ref = newRV_noinc(cxn);
  sv_bless(cxn_ref, gv_stashpv(CXNCLASS, GV_ADD));
  SvREADONLY_on(cxn);
  return cxn_ref;
}


MODULE = Neo4j::Bolt  PACKAGE = Neo4j::Bolt  

PROTOTYPES: DISABLE


SV *
connect_ (classname, neo4j_url, timeout, encrypt, tls_ca_dir, tls_ca_file, tls_pk_file, tls_pk_pass)
	const char *	classname
	const char *	neo4j_url
	int	timeout
	bool	encrypt
	const char *	tls_ca_dir
	const char *	tls_ca_file
	const char *	tls_pk_file
	const char *	tls_pk_pass

