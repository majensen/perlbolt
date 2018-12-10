package t::NeoValue;
use lib '../lib';
use lib '../../lib';
use Bolt::TypeHandlersC;
use Inline C => Config => LIBS  => '-L/usr/local/lib -lneo4j-client -lssl -lcrypto', INC => "-I$ENV{HOME}/Code/libneo4j-client/lib/src -I$ENV{HOME}/Code/libneo4j-client/lib";
use Inline C => <<'END_NEOVALUE_C';

#include <neo4j-client.h>
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))
#define NVCLASS "t::NeoValue"
extern neo4j_value_t SV_to_neo4j_value(SV*);
extern SV *neo4j_value_to_SV(neo4j_value_t);
struct neovalue {
  neo4j_value_t value;
};
typedef struct neovalue neovalue_t;

SV *_new_from_perl (const char* classname, SV *v) {
   SV *neosv, *neosv_ref;
   neovalue_t *obj;
   Newx(obj, 1, neovalue_t);
   obj->value = SV_to_neo4j_value(v);
   neosv = newSViv((IV) obj);
   neosv_ref = newRV_noinc(neosv);
   sv_bless(neosv_ref, gv_stashpv(classname, GV_ADD));
   SvREADONLY_on(neosv);
   return neosv_ref;
}

const char* _neotype (SV *obj) {
  neo4j_value_t v;
  v = C_PTR_OF(obj,neovalue_t)->value;
  return neo4j_typestr( neo4j_type( v ) ); 
}

SV* _as_perl (SV *obj) {
  SV *ret;
  ret = newSV(0);
  sv_setsv(ret,neo4j_value_to_SV( C_PTR_OF(obj, neovalue_t)->value ));
  return ret;
}

int _map_size (SV *obj) {
  return neo4j_map_size( C_PTR_OF(obj, neovalue_t)->value );
}
void DESTROY(SV *obj) {
  neo4j_value_t *val = C_PTR_OF(obj, neo4j_value_t);
  return;
}

END_NEOVALUE_C

1;

