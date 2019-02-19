package Neo4j::Bolt::ResultStream;
BEGIN {
  our $VERSION = "0.01";
  require Neo4j::Bolt::Cxn;
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
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))
#define BUFLEN 100

SV* neo4j_value_to_SV( neo4j_value_t value);

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
  const struct neo4j_failure_details *failure_details;
  rs_stats_t *stats;
  char *eval_errcode;
  char *eval_errmsg;
  int errnum;
  const char *strerror;
};

typedef struct rs_obj rs_obj_t;

void new_rs_obj (rs_obj_t **rs_obj);
void reset_errstate_rs_obj (rs_obj_t *rs_obj);
int update_errstate_rs_obj (rs_obj_t *rs_obj);

void fetch_next_ (SV *rs_ref) {
  SV *perl_value;
  rs_obj_t *rs_obj;
  neo4j_result_t *result;
  neo4j_result_stream_t *rs;
  neo4j_value_t value;
  struct neo4j_update_counts cts;
  int i,n,fail;
  Inline_Stack_Vars;
  Inline_Stack_Reset;

  rs_obj = C_PTR_OF(rs_ref,rs_obj_t);
  reset_errstate_rs_obj(rs_obj);

  rs = rs_obj->res_stream;
  n = neo4j_nfields(rs);
  if (!n) {
    fail = update_errstate_rs_obj(rs_obj);
    if (fail) {
      Inline_Stack_Done;
      return;
    }
  }  
  result = neo4j_fetch_next(rs);
  if (result == NULL) {
    if (errno) {
      fail = update_errstate_rs_obj(rs_obj);
    } else {
      // collect stats
      cts = neo4j_update_counts(rs);
      rs_obj->stats->result_count = neo4j_result_count(rs);
      rs_obj->stats->available_after = neo4j_results_available_after(rs);
      rs_obj->stats->consumed_after = neo4j_results_consumed_after(rs);
      memcpy(rs_obj->stats->update_counts, &cts, sizeof(struct neo4j_update_counts));
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
  return neo4j_nfields( C_PTR_OF(rs_ref,rs_obj_t)->res_stream );
}

void fieldnames_ (SV *rs_ref) {
  neo4j_result_stream_t *rs;
  int nfields;
  int i;
  rs = C_PTR_OF(rs_ref,rs_obj_t)->res_stream;
  nfields = neo4j_nfields(rs);
  Inline_Stack_Vars;
  Inline_Stack_Reset;
  for (i = 0; i < nfields; i++) 
    Inline_Stack_Push(sv_2mortal(newSVpv(neo4j_fieldname(rs,i),0)));
  Inline_Stack_Done;
  return;
}

int success_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->succeed;
}
int failure_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->fail;
}
int client_errnum_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->errnum;
}
const char *server_errcode_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->eval_errcode;
}
const char *server_errmsg_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->eval_errmsg;
}
const char *client_errmsg_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->strerror;
}

UV result_count_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->stats->result_count;
}
UV available_after_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->stats->available_after;
}
UV consumed_after_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->stats->consumed_after;
}

void update_counts_ (SV *rs_ref) {
  struct neo4j_update_counts *uc;
  Inline_Stack_Vars;
  Inline_Stack_Reset;
  uc = C_PTR_OF(rs_ref,rs_obj_t)->stats->update_counts;

  Inline_Stack_Push( newSViv( (const UV) uc->nodes_created ));
  Inline_Stack_Push( newSViv( (const UV) uc->nodes_deleted ));
  Inline_Stack_Push( newSViv( (const UV) uc->relationships_created ));
  Inline_Stack_Push( newSViv( (const UV) uc->relationships_deleted ));
  Inline_Stack_Push( newSViv( (const UV) uc->properties_set ));
  Inline_Stack_Push( newSViv( (const UV) uc->labels_added ));
  Inline_Stack_Push( newSViv( (const UV) uc->labels_removed ));
  Inline_Stack_Push( newSViv( (const UV) uc->indexes_added ));
  Inline_Stack_Push( newSViv( (const UV) uc->indexes_removed ));
  Inline_Stack_Push( newSViv( (const UV) uc->constraints_added ));
  Inline_Stack_Push( newSViv( (const UV) uc->constraints_removed ));
  Inline_Stack_Done;
  return;
}

void DESTROY (SV *rs_ref) {
  rs_obj_t *rs_obj;
  rs_obj = C_PTR_OF(rs_ref,rs_obj_t);
  neo4j_close_results(rs_obj->res_stream);
  Safefree(rs_obj->stats->update_counts);
  Safefree(rs_obj->stats);
  Safefree(rs_obj);
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
 # check that the stream emptied cleanly...
 if ( $stream->failure_ ) {
   print STDERR "Uh oh: ".($stream->client_errmsg_ || $stream->server_errmsg_);
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

=item success_(), failure_()

Use these to check whether fetch_next() succeeded. They indicate the 
current error state of the result stream. If 

  $stream->success_ == $stream->failure_ == -1

then the stream has not yet been accessed.

=item client_errnum_(), client_errmsg_(), server_errcode_(),
server_errmsg_()

If C<$stream-E<gt>failure_> is true, these will indicate what happened.

If the error occurred within the C<libneo4j-client> code,
C<client_errnum_()> will provide the C<errno> and C<client_errmsg_()>
the associated error message. This is a probably a good time to file a
bug report.

If the error occurred at the server, C<server_errcode_()> and
C<server_errmsg_()> will contain information sent by the server. In
particular, Cypher syntax errors will appear here.

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
