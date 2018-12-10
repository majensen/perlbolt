package t::BoltFile;
use Inline C => Config => LIBS  => '-L/usr/local/lib -lneo4j-client -lssl -lcrypto', INC => "-I$ENV{HOME}/Code/libneo4j-client/lib/src -I$ENV{HOME}/Code/libneo4j-client/lib";
use Inline C => <<'END_BOLTFILE_C';

#include <neo4j-client.h>
#include "src/memory.h"
#include <posix_iostream.h>
#include <stdio.h>
#define NEO4J_DEFAULT_MPOOL_BLOCK_SIZE 128
#define BFCLASS "t::BoltFile"
#define NVCLASS "t::NeoValue"
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))

struct bolt_file {
  char * fn;
  FILE * fh;
  neo4j_iostream_t *fs;
};
typedef struct bolt_file bolt_file_t;
static void *perlapi_alloc(neo4j_memory_allocator_t *allocator, void *context, size_t size);
static void *perlapi_calloc(neo4j_memory_allocator_t *allocator, void *context, size_t size);
static void perlapi_free(neo4j_memory_allocator_t *allocator, void *ptr);
static void perlapi_vfree(neo4j_memory_allocator_t *allocator, void **ptrs, size_t n);


static void *perlapi_alloc(neo4j_memory_allocator_t *allocator, void *context, size_t size)
{
  void *ptr;
  assert(allocator != NULL);
  Newx(ptr, size, char);
  return ptr;
}

static void *perlapi_calloc(neo4j_memory_allocator_t *allocator, void *context, size_t size)
{
  void *ptr;
  assert(allocator != NULL);
  Newxz(ptr, size, char);
  return ptr;
}

static void perlapi_free(neo4j_memory_allocator_t *allocator, void *ptr)
{
  assert(allocator != NULL);
  Safefree(ptr);
}

static void perlapi_vfree(neo4j_memory_allocator_t *allocator, void **ptrs, size_t n)
{
    assert(allocator != NULL);
    for (; n > 0; --n, ++ptrs)
    {
        Safefree(*ptrs);
    }
}

struct neo4j_memory_allocator neo4j_perlapi_memory_allocator = {
  .alloc = perlapi_alloc,
  .calloc =  perlapi_calloc,
  .free =  perlapi_free,
  .vfree =  perlapi_vfree
  };


SV* open_bf(const char *classname, const char *fn, const char *mode) {
  bolt_file_t *bf;
  SV *bsv, *bsv_ref;
  Newx(bf,1,bolt_file_t);
  bf->fn = savepv(fn);
  bf->fh = fopen(fn, mode);
  if (!bf->fh) {
    perror(sprintf("can't open bolt file %s: ",bf->fn));
    return &PL_sv_undef;
  }
  if ( !(bf->fs = neo4j_posix_iostream(fileno(bf->fh))) ) {
    perror(sprintf("can't create neo4j_iostream (%s): ",bf->fn));
    return &PL_sv_undef;
  }
  bsv = newSViv((IV) bf);
  bsv_ref = newRV_noinc(bsv);
  sv_bless(bsv_ref, gv_stashpv(BFCLASS, GV_ADD));
  SvREADONLY_on(bsv);
  return bsv_ref;
}

FILE *get_fh (SV* obj) {
  return C_PTR_OF(obj,bolt_file_t)->fh;
}

void close_bf (SV* obj) {
  fclose(C_PTR_OF(obj,bolt_file_t)->fh);
  return;
}
const char *get_fn (SV* obj) {
  return C_PTR_OF(obj,bolt_file_t)->fn;
}

SV *_create_neovalue (SV *obj, neo4j_value_t *v) {
   SV *neosv, *neosv_ref;;
   neosv = newSViv((IV) v);
   neosv_ref = newRV_noinc(neosv);
   sv_bless(neosv_ref, gv_stashpv(NVCLASS, GV_ADD));
   SvREADONLY_on(neosv);
   return neosv_ref;
}

SV *next_value (SV *obj) {
  bolt_file_t *bf;
  neo4j_value_t *value;
  struct neo4j_mpool bt_mpool;
  bf = C_PTR_OF(obj,bolt_file_t);
  bt_mpool = neo4j_mpool(&neo4j_perlapi_memory_allocator,NEO4J_DEFAULT_MPOOL_BLOCK_SIZE);
  if (neo4j_deserialize(bf->fs,&bt_mpool,value)==0) {
    return _create_neovalue(obj, value);
  }
  else {
    return &PL_sv_undef;
  }
}

void DESTROY(SV* obj) {
  bolt_file_t* bf = C_PTR_OF(obj,bolt_file_t);
  fclose(bf->fh);
  Safefree(bf->fn);
  Safefree(bf);
}

END_BOLTFILE_C

1;

