package Neo4j::Bolt::TypeHandlersC;
BEGIN {
  our $VERSION = "0.01";
  eval 'require Neo4j::Bolt::Config; 1';
}
use Inline 'global';
use Inline C => Config =>
  LIBS => $Neo4j::Bolt::Config::extl,
  INC => $Neo4j::Bolt::Config::extc,
  optimize => '-g',
  myextlib => $Neo4j::Bolt::Config::liba,
  ccflagsex => '-Wno-comment',
  version => $VERSION,
  name => __PACKAGE__;

use Inline C => <<'END_TYPE_HANDLERS_C';

#include <neo4j-client.h>

#include <string.h>

extern neo4j_value_t neo4j_identity(long long);               
extern neo4j_value_t neo4j_node(const neo4j_value_t*);	      
extern neo4j_value_t neo4j_relationship(const neo4j_value_t*);


struct neo4j_struct
{
    uint8_t _vt_off;
    uint8_t _type;
    uint16_t _pad1;
    uint8_t signature;
    uint8_t _pad2;
    uint16_t nfields;
    union {
        const neo4j_value_t *fields;
        union _neo4j_value_data _pad3;
    };
};

 
/**
Types
NEO4J_BOOL
NEO4J_BYTES
NEO4J_FLOAT
NEO4J_IDENTITY
NEO4J_INT
NEO4J_LIST
NEO4J_MAP
NEO4J_NODE
NEO4J_NULL
NEO4J_PATH
NEO4J_RELATIONSHIP
NEO4J_STRING 
**/

neo4j_value_t SViv_to_neo4j_bool (SV *sv);
neo4j_value_t SViv_to_neo4j_int (SV *sv);
neo4j_value_t SVnv_to_neo4j_float (SV *sv);
neo4j_value_t SVpv_to_neo4j_string (SV *sv);
neo4j_value_t AV_to_neo4j_list(AV *av);
neo4j_value_t HV_to_neo4j_map(HV *hv);
neo4j_value_t HV_to_neo4j_node(HV *hv);
neo4j_value_t HV_to_neo4j_relationship(HV *hv);
neo4j_value_t AV_to_neo4j_path(HV *hv);
neo4j_value_t SV_to_neo4j_value(SV *sv);

SV* neo4j_bool_to_SViv( neo4j_value_t value );
SV* neo4j_bytes_to_SVpv( neo4j_value_t value );
SV* neo4j_float_to_SVnv( neo4j_value_t value );
SV* neo4j_int_to_SViv( neo4j_value_t value );
SV* neo4j_string_to_SVpv( neo4j_value_t value );
HV* neo4j_node_to_HV( neo4j_value_t value );
HV* neo4j_relationship_to_HV( neo4j_value_t value );
AV* neo4j_path_to_AV( neo4j_value_t value);
AV* neo4j_list_to_AV( neo4j_value_t value );
HV* neo4j_map_to_HV( neo4j_value_t value );
SV* neo4j_value_to_SV( neo4j_value_t value );

long long neo4j_identity_value(neo4j_value_t value);
char *neo4j_string_to_alloc_str(neo4j_value_t value);

char *neo4j_string_to_alloc_str(neo4j_value_t value) {
  assert(neo4j_type(value) == NEO4J_STRING);
  char *s;  
  int nlength;
  nlength = (int) neo4j_string_length(value);
  Newx(s,nlength+1,char);
  return neo4j_string_value(value,s,(size_t) nlength+1);
}

neo4j_value_t SViv_to_neo4j_bool (SV *sv) {
  return neo4j_bool( (bool) SvIV(sv) );
}

neo4j_value_t SViv_to_neo4j_int (SV *sv) {
  return neo4j_int( (long long) SvIV(sv) );
}

neo4j_value_t SVnv_to_neo4j_float (SV *sv) {
  return neo4j_float( SvNV(sv) );
}

neo4j_value_t SVpv_to_neo4j_string (SV *sv) {
  STRLEN len;
  char *k0,*k;
  k = SvPV(sv,len);
  Newx(k0,len+1,char);
  strncpy(k0,k,(size_t) len);
  *(k0+len) = 0;
  return neo4j_string(k0);
}

neo4j_value_t SV_to_neo4j_value(SV *sv) {
  int t;
  SV *thing;
  HV *hv;

  if (!SvOK(sv) ) {
    return neo4j_null;
  }
  if (SvROK(sv)) { // a ref
    thing = SvRV(sv);
    t = SvTYPE(thing);
    if ( t < SVt_PVAV) { // scalar ref
      return SV_to_neo4j_value(thing);
    }
    else if (t == SVt_PVAV) { //array
      return AV_to_neo4j_list( (AV*) thing );
    }
    else if (t == SVt_PVHV) { //hash
      // determine if is a map, node, or reln
      hv = (HV *)thing;
      if (hv_exists(hv, "_node", 5)) { // node
        return HV_to_neo4j_node(hv);
      }
      else if (hv_exists(hv, "_relationship", 13)) { // reln
        return HV_to_neo4j_relationship(hv);
      }
      else if (hv_exists(hv, "_nodes", 6)) { // path
        return AV_to_neo4j_path(hv);
      }
      else { // map
        return HV_to_neo4j_map(hv);
      }
    }
  }
  else {
   if (SvIOK(sv)) {
     return SViv_to_neo4j_int(sv);
   }
   else if (SvNOK(sv)) {
     return SVnv_to_neo4j_float(sv);
   } 
   else if (SvPOK(sv)) {
     return SVpv_to_neo4j_string(sv);
   }
   else {
     perror("Can't handle this scalar");
     return neo4j_null;
   }
  }
 return neo4j_null;
}

neo4j_value_t AV_to_neo4j_list(AV *av) {
  int i,n;
  neo4j_value_t *items;
  n = av_top_index(av);
  if (n < 0) {
    return neo4j_null;
  }
  Newx(items, n+1, neo4j_value_t);
  for (i=0;i<=n;i++) {
   items[i] = SV_to_neo4j_value( *(av_fetch(av,i,0)) );
  }
  return neo4j_list(items, n+1);
}

neo4j_value_t HV_to_neo4j_map (HV *hv) {
  HE *ent;
  char *k,*k0;
  SV *v;
  int n,retlen;
  neo4j_map_entry_t *map_ents;
  if (!HvTOTALKEYS(hv)) {
    return neo4j_null;
  }
  Newx(map_ents,HvTOTALKEYS(hv),neo4j_map_entry_t);
  hv_iterinit(hv);
  n=0;
  while ((ent = hv_iternext(hv))) {
    k = hv_iterkey(ent,&retlen);
    Newx(k0,retlen+1,char);
    strncpy(k0,k,retlen);
    *(k0+retlen)=0;
    map_ents[n] = neo4j_map_entry( k0, SV_to_neo4j_value(hv_iterval(hv,ent)));
    n++;
  }
  return neo4j_map( map_ents, HvTOTALKEYS(hv) );
}

// neo4j_node(neo4j_value_t fields[3]) is not exposed in the API
// fields[0] is a NEO4J_IDENTITY
// fields[1] is a NEO4J_LIST of node labels (NEO4J_STRINGs)
//   (note REST::Neo4p::Node doesn't store a list of labels in the 
//   simple rendering! Fix!)
// fields[2] is a NEO4J_MAP of properties
neo4j_value_t HV_to_neo4j_node(HV *hv) {
  HV *hv_cpy;
  SV *node_id, *lbls_ref;
  AV *lbls;
  neo4j_value_t *fields;
  neo4j_map_entry_t null_ent;
  char *k;
  int len;
  SV *v;
  
  Newx(fields, 3, neo4j_value_t);
  hv_cpy = newHV();
  hv_iterinit(hv);
  while( (v=hv_iternextsv(hv,&k,&len)) ) {
    SvREFCNT_inc(v);
    if (!hv_store(hv_cpy, k, len, v, 0)) {
      SvREFCNT_dec(v);
    }
  }
  sv_2mortal((SV*)hv_cpy);

  node_id = hv_delete( hv_cpy, "_node", 5, 0);
  lbls_ref = hv_delete( hv_cpy, "_labels", 7, 0);
  if (lbls_ref) {
    lbls = (AV*) SvRV(lbls_ref);
  } else {
    lbls = NULL;
  }
  if (lbls) {
    fields[1] = AV_to_neo4j_list(lbls);
  } else {
    fields[1] = neo4j_list( &neo4j_null, 0 );
  }
  fields[0] = neo4j_identity( SvIV(node_id) );

  if (HvTOTALKEYS(hv_cpy)) {
    fields[2] = HV_to_neo4j_map(hv_cpy);
  } else {
    null_ent = neo4j_map_entry( "", neo4j_null );
    fields[2] = neo4j_map( &null_ent, 0 );
  }
  return neo4j_node(fields);
}


// neo4j_relationship( neo4j_value_t fields[5] ) is not exposed in API
// field[0] is NEO4J_IDENTITY (id of the relationship)
// field[1] is NEO4J_IDENTITY (id of the start node))
// field[2] is NEO4J_IDENTITY (id of the end node))
// field[3] is NEO4J_STRING (relationship type)
// field[4] is NEO4J_MAP (properties)

neo4j_value_t HV_to_neo4j_relationship(HV *hv) {
  HV *hv_cpy;
  SV *reln_id,*start_id,*end_id,*type;
  AV *lbls;
  neo4j_value_t *fields;
  neo4j_map_entry_t null_ent;
  char *k,*k0;
  int len;
  SV *v;

  Newx(fields, 5, neo4j_value_t);
  hv_cpy = newHV();
  hv_iterinit(hv);
  while( (v=hv_iternextsv(hv,&k,&len)) ) {
    SvREFCNT_inc(v);
    Newx(k0,len,char);
    strncpy(k0,k,len);
    if (!hv_store(hv_cpy, k0, len, v, 0)) {
      SvREFCNT_dec(v);
      Safefree(k0);
    }
  }
  sv_2mortal((SV*)hv_cpy);

  reln_id = hv_delete( (HV*) hv_cpy, "_relationship", 13, 0);
  start_id = hv_delete( (HV*) hv_cpy, "_start", 6, 0);
  end_id = hv_delete( (HV*) hv_cpy, "_end", 4, 0);
  type = hv_delete( (HV*) hv_cpy, "_type", 5, 0);

  fields[0] = neo4j_identity( SvIV(reln_id) );
  fields[1] = neo4j_identity( SvIV(start_id) );
  fields[2] = neo4j_identity( SvIV(end_id) );
  if (type) {
    fields[3] = SVpv_to_neo4j_string(type);
  } else {
    fields[3] = neo4j_string("");
  }
  if (HvTOTALKEYS(hv_cpy)) {
    fields[4] = HV_to_neo4j_map(hv_cpy);
  } else {
    null_ent = neo4j_map_entry( "", neo4j_null );
    fields[4] = neo4j_map( &null_ent, 0 );
  }
  return neo4j_relationship(fields);
}

neo4j_value_t AV_to_neo4j_path(HV *hv) {
  fprintf(stderr, "Not yet implemented");
  return neo4j_null;
}

long long neo4j_identity_value(neo4j_value_t value)
{
  value._type = NEO4J_INT;
  return neo4j_int_value(value);
}


SV* neo4j_bool_to_SViv( neo4j_value_t value) {
  return newSViv( (IV) neo4j_bool_value(value));
}

SV* neo4j_bytes_to_SVpv( neo4j_value_t value ) {
  return newSVpvn( neo4j_bytes_value(value),
		   neo4j_bytes_length(value) );
}

SV* neo4j_float_to_SVnv( neo4j_value_t value ) {
  return newSVnv( neo4j_float_value( value ) );
}

SV* neo4j_int_to_SViv( neo4j_value_t value ) {
  return newSViv( (IV) neo4j_int_value( value ) );
}

SV* neo4j_string_to_SVpv( neo4j_value_t value ) {
  SV* pv;
  pv = newSVpv(neo4j_string_to_alloc_str(value), 0);
  SvUTF8_on(pv);  // depends on libneo4j-client output being valid UTF-8, always
  return pv;
}

SV* neo4j_value_to_SV( neo4j_value_t value ) {
  neo4j_type_t the_type;
  the_type = neo4j_type( value );
  if ( the_type ==  NEO4J_BOOL) {
    return neo4j_bool_to_SViv(value);
  } else if ( the_type ==  NEO4J_BYTES) {
    return neo4j_bytes_to_SVpv(value);
  } else if ( the_type ==  NEO4J_FLOAT) {
    return neo4j_float_to_SVnv(value);
  } else if ( the_type ==  NEO4J_INT) {
    return neo4j_int_to_SViv(value);
  } else if ( the_type ==  NEO4J_NODE) {
    return newRV_noinc((SV*)neo4j_node_to_HV( value ));;
  } else if ( the_type ==  NEO4J_RELATIONSHIP) {
    return newRV_noinc((SV*)neo4j_relationship_to_HV( value ));;
  } else if ( the_type ==  NEO4J_NULL) {
    return newSV(0);
  } else if ( the_type ==  NEO4J_LIST) {
    return newRV_noinc((SV*)neo4j_list_to_AV( value ));
  } else if ( the_type ==  NEO4J_MAP) {
    return newRV_noinc( (SV*)neo4j_map_to_HV( value ));
  } else if ( the_type == NEO4J_PATH ){
    return newRV_noinc( (SV*)neo4j_path_to_AV( value ));

  } else if ( the_type ==  NEO4J_STRING) {
    return neo4j_string_to_SVpv(value);
  } else {
    warn("Unknown neo4j_value type encountered");
    return newSV(0);
  }
}

AV* neo4j_list_to_AV( neo4j_value_t value ) {
  int i,n;
  AV* av;
  neo4j_value_t entry;
  n = neo4j_list_length( value );
  av = newAV();
  for (i=0;i<n;i++) {
    entry = neo4j_list_get(value, i);
    av_push(av, neo4j_value_to_SV( entry ));
  }
  return av;
}

HV* neo4j_map_to_HV( neo4j_value_t value ) {
  int i,n;
  char *ks;
  const neo4j_map_entry_t *entry;
  HV *hv;
  SV *sv;
  hv = newHV();
  n = (int) neo4j_map_size(value);
  for (i=0;i<n;i++) {
    entry = neo4j_map_getentry(value,i);
    ks = neo4j_string_to_alloc_str(entry->key);
    sv = neo4j_value_to_SV(entry->value);
    SvREFCNT_inc(sv);
    if (hv_store(hv, ks, neo4j_string_length(entry->key), sv,0) ==
	NULL) {
      SvREFCNT_dec(sv);
      fprintf(stderr, "Failed to create hash entry for key '%s'\n",ks);
    }
  }
  return hv;
}
 
HV* neo4j_node_to_HV( neo4j_value_t value ) {
  HV *hv, *props_hv;
  char *k;
  SV *v;
  I32 retlen;
  long long id;
  neo4j_value_t labels,props;
  // const struct neo4j_struct *V;
  // V = (const struct neo4j_struct *)&value;
  // printf(neo4j_typestr(neo4j_type(V->fields[0])));

  hv = newHV();
  id = neo4j_identity_value(neo4j_node_identity(value));
  labels = neo4j_node_labels(value);
  props_hv = neo4j_map_to_HV(neo4j_node_properties(value));
  hv_stores(hv, "_node", newSViv( (IV) id ));
  if (neo4j_list_length(labels)) {
    hv_stores(hv, "_labels", neo4j_value_to_SV(labels));
  }
  hv_iterinit(props_hv);
  while ((v = hv_iternextsv(props_hv, &k, &retlen))) {
    hv_store(hv, k, retlen, v, 0);
  }
  hv_undef(props_hv);
  return hv;
}

HV* neo4j_relationship_to_HV( neo4j_value_t value ) {
  HV *hv, *props_hv;
  char *k;
  SV *type,*v;
  STRLEN len;
  I32 retlen;
  long long reln_id,start_id,end_id;
  hv = newHV();
  reln_id = neo4j_identity_value(neo4j_relationship_identity(value));
  start_id = neo4j_identity_value(neo4j_relationship_start_node_identity(value));
  end_id = neo4j_identity_value(neo4j_relationship_end_node_identity(value));
  type = neo4j_string_to_SVpv(neo4j_relationship_type(value));
  props_hv = neo4j_map_to_HV(neo4j_relationship_properties(value));
  hv_stores(hv, "_relationship", newSViv( (IV) reln_id ));
  hv_stores(hv, "_start", newSViv( (IV) start_id ));
  hv_stores(hv, "_end", newSViv( (IV) end_id ));
  SvPV(type,len);
  retlen = (I32) len;
  if (retlen) {
    hv_stores(hv, "_type", type);
  }
  hv_iterinit(props_hv);
  while ((v = hv_iternextsv(props_hv, &k, &retlen))) {
    hv_store(hv, k, retlen, v, 0);
  }
  hv_undef(props_hv);
  return hv;
}

AV* neo4j_path_to_AV( neo4j_value_t value) {
  int i,n,last_node_id,node_id;
  AV* av;
  struct neo4j_struct *v;
  _Bool dir;
  SV* rel_sv;
  neo4j_value_t node;
  av = newAV();
  n = neo4j_path_length(value);
  node = neo4j_path_get_node(value, 0);
  av_push(av, neo4j_value_to_SV( node ));
  last_node_id = neo4j_identity_value( neo4j_node_identity(node) );
  if (n==0) {
    return av;
  } else {
    for (i=1; i<=n; i++) {
      node = neo4j_path_get_node(value,i);
      node_id = neo4j_identity_value( neo4j_node_identity(node) );
      rel_sv = neo4j_value_to_SV(neo4j_path_get_relationship(value,i-1,&dir));
      hv_stores( (HV*) SvRV(rel_sv), "_start", newSViv( (IV) (dir ? last_node_id : node_id)));
      hv_stores( (HV*) SvRV(rel_sv), "_end", newSViv( (IV) (dir ? node_id : last_node_id)));
      av_push(av, rel_sv);
      av_push(av, neo4j_value_to_SV(node));
      last_node_id = node_id;
    }
    return av;
  }
}

END_TYPE_HANDLERS_C

=head1 NAME

Neo4j::Bolt::TypeHandlersC - Low level Perl to Bolt converters

=head1 SYNOPSIS

 // how Neo4j::Bolt::ResultStream uses it
  for (i=0; i<n; i++) {
    value = neo4j_result_field(result, i);
    perl_value = neo4j_value_to_SV(value);
    Inline_Stack_Push( perl_value );
  }

=head1 DESCRIPTION

L<Neo4j::Bolt::TypeHandlersC> is all C code, managed by L<Inline::C>. 
It tediously defines methods to convert Perl structures to Bolt
representations, and also tediously defines methods convert Bolt
data to Perl representations.

=head1 METHODS

=over

=item neo4j_value_t SV_to_neo4j_value(SV *sv)

Attempt to create the appropriate
L<libneo4j-client|https://github.com/cleishm/libneo4j-client>
representation of the Perl SV argument.

=item SV* neo4j_value_to_SV( neo4j_value_t value )

Attempt to create the appropriate Perl SV representation of the 
L<libneo4j-client|https://github.com/cleishm/libneo4j-client> 
neo4j_value_t argument.

=back

=head1 SEE ALSO

L<Neo4j::Bolt>, L<Neo4j::Bolt::Value>, L<Inline::C>, 
L<libneo4j-client API|http://neo4j-client.net/doc/latest/neo4j-client_8h.html>.

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

