#include <stdio.h>
#include "neo4j-client.h"
#include "serialization.h"
#include "memory.h"
#include "posix_iostream.h"

void make_bolt_testfile (char *fname) {
  FILE *f;
  neo4j_iostream_t *boltf;
  neo4j_value_t neo_int, neo_fl, neo_str, neo_map, neo_list;
  neo4j_value_t neo_node, neo_rel, neo_pth;
  f = fopen(fname, "w");
  if (!f) {
    perror("can't open bolt testfile: ");
    return;
  }
  if ( !(boltf = neo4j_posix_iostream(fileno(f))) ) {
    perror("can't create neo4j_iostream:");
    return;
  }
  neo_int = neo4j_int( 42 );
  neo_fl = neo4j_float( 3.1415927 );
  neo_str = neo4j_string( "The string's the thing.");
  
  neo4j_serialize(neo_str, boltf);
  neo4j_serialize(neo_int, boltf);
  neo4j_serialize(neo_fl, boltf);
  fclose(f);
  return;
}

int main() {
  make_bolt_testfile("testfile.blt");
  return 0;
}
