package Neo4j::Bolt::ResultStream;
BEGIN {
  our $VERSION = "0.01";
  eval 'require Neo4j::Bolt::Config; 1';
}
use Inline C => Config =>
  LIBS => $Neo4j::Bolt::Config::extl,
  INC => $Neo4j::Bolt::Config::extc,  
  version => $VERSION,
  name => __PACKAGE__;


use Inline C => <<'END_BOLT_RS_C';
#include <neo4j-client.h>
#define RSCLASS  "Neo4j::Bolt::ResultStream"
#define RCLASS  "Neo4j::Bolt::Result"
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))

SV* neo4j_value_to_SV( neo4j_value_t value);

void fetch_next_ (SV *rs_ref) {
  SV *r;
  SV *r_ref;
  SV *perl_value;
  neo4j_result_t *result;
  neo4j_result_stream_t *rs;
  neo4j_value_t value;
  int i,n;
  Inline_Stack_Vars;
  Inline_Stack_Reset;

  rs = C_PTR_OF(rs_ref,neo4j_result_stream_t);
  n = neo4j_nfields(rs);
  if (!n) {
    if (errno) {
      neo4j_perror(stderr,errno,"Result stream");
    }
    else {
     Inline_Stack_Done;
     return;
    }
  }  
  result = neo4j_fetch_next(rs);
  if (result == NULL) {
    if (errno) {
      neo4j_perror(stderr,errno,"Fetch failed");
    }
    Inline_Stack_Done;
    return;
  }

  for (i=0; i<n; i++) {
    value = neo4j_result_field(result, i);
    perl_value = neo4j_value_to_SV(value);
    Inline_Stack_Push( perl_value );
  }
  Inline_Stack_Done;
  return;
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

=head1 NAME

Neo4j::Bolt::ResultStream - Iterator on Neo4j Bolt query response

=head1 SYNOPSIS

 use Neo4j::Bolt;
 $cxn = Neo4j::Bolt->connect_("bolt://localhost:7687");

 $stream = $cxn->run_query_(
   "MATCH (a) RETURN labels(a) as lbls, count(a) as ct",
   {} # parameter hash required
 );
 while ( my @row = $stream->fetch_next_ ) {
   print "For label set [".join(',',@{$row[0]})."] there are $row[1] nodes.\n";
 }

=head1 DESCRIPTION

L<Neo4j::Bolt::ResultStream> objects are created by a successful query 
performed on a L<Neo4j::Bolt::Cxn>. They are iterated to obtain the rows
of the response as Perl arrays (not arrayrefs).

=head1 METHODS

=over

=item fetch_next_()

Obtain the next row of results as an array. Returns false when done.

=item fieldnames_()

Obtain the column names of the response as an array.

=item nfields_()

Obtain the number of fields in the response row as an integer.

=back

=head1 SEE ALSO

L<Neo4j::Bolt>, L<Neo4j::Bolt::Cxn>.

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
