package Neo4j::Bolt;
use Cwd qw/realpath getcwd/;

BEGIN {
  our $VERSION = "0.4203";
  require Neo4j::Bolt::Cxn;
  require Neo4j::Bolt::Txn;
  require Neo4j::Bolt::ResultStream;
  require Neo4j::Bolt::CTypeHandlers;
  require XSLoader;
  XSLoader::load();

}
our $DEFAULT_DB = "neo4j";

sub connect {
  $_[0]->connect_( $_[1], $_[2] // 0, 0, "", "", "", "" );
}

sub connect_tls {
  my $self = shift;
  my ($url, $tls) = @_;
  unless ($tls && (ref($tls) == 'HASH')) {
    die "Arg 1 should URL and Arg 2 a hashref with keys 'ca_dir','ca_file','pk_file','pk_pass'"
  }
  my %default_ca = ();
  eval {
    require IO::Socket::SSL;
    %default_ca = IO::Socket::SSL::default_ca();
  };
  eval {
    require Mozilla::CA;
    $default_ca{SSL_ca_file} = Mozilla::CA::SSL_ca_file();
  } unless %default_ca;
  return $self->connect_(
    $url,
    $tls->{timeout},
    1,  # encrypt
    $tls->{ca_dir}  // $default_ca{SSL_ca_path} // "",
    $tls->{ca_file} // $default_ca{SSL_ca_file} // "",
    $tls->{pk_file} || "",
    $tls->{pk_pass} || ""
   );
}



=head1 NAME

Neo4j::Bolt - query Neo4j using Bolt protocol

=for markdown [![Build Status](https://travis-ci.org/majensen/perlbolt.svg?branch=master)](https://travis-ci.org/majensen/perlbolt)

=head1 SYNOPSIS

 use Neo4j::Bolt;
 $cxn = Neo4j::Bolt->connect("bolt://localhost:7687");
 $stream = $cxn->run_query(
   "MATCH (a) RETURN head(labels(a)) as lbl, count(a) as ct",
   {} # parameter hash required
 );
 @names = $stream->field_names;
 while ( my @row = $stream->fetch_next ) {
   print "For label '$row[0]' there are $row[1] nodes.\n";
 }
 $stream = $cxn->run_query(
   "MATCH (a) RETURN labels(a) as lbls, count(a) as ct",
   {} # parameter hash required
 );
 while ( my @row = $stream->fetch_next ) {
   print "For label set [".join(',',@{$row[0]})."] there are $row[1] nodes.\n";
 }

=head1 DESCRIPTION

L<Neo4j::Bolt> is a Perl wrapper around Chris Leishmann's excellent
L<libneo4j-client|https://github.com/cleishm/libneo4j-client> library
implementing the Neo4j L<Bolt|https://boltprotocol.org/> network
protocol. It uses Ingy's L<Inline::C> to do all the hard XS work.

=head2 Return Types

L<Neo4j::Bolt::ResultStream> returns rows resulting from queries made 
via a L<Neo4j::Bolt::Cxn>. These rows are simple arrays of scalars and/or
references. These represent Neo4j types according to the following:

 Neo4j type       Perl representation
 ----- ----       ---- --------------
 Null             undef
 Bool             JSON::PP::Boolean (acts like 0 or 1)
 Int              scalar
 Float            scalar
 String           scalar
 Bytes            scalar
 List             arrayref
 Map              hashref
 Node             hashref  (Neo4j::Bolt::Node)
 Relationship     hashref  (Neo4j::Bolt::Relationship)
 Path             arrayref (Neo4j::Bolt::Path)

L<Nodes|Neo4j::Bolt::Node>, L<Relationships|Neo4j::Bolt::Relationship> and
L<Paths|Neo4j::Bolt::Path> are represented in the following formats:

 # Node:
 bless {
   id => $node_id,  labels => [$label1, $label2, ...],
   properties => {prop1 => $value1, prop2 => $value2, ...}
 }, 'Neo4j::Bolt::Node'

 # Relationship:
 bless {
   id => $reln_id,  type => $reln_type,
   start => $start_node_id,  end => $end_node_id,
   properties => {prop1 => $value1, prop2 => $value2, ...}
 }, 'Neo4j::Bolt::Relationship'

 # Path:
 bless [
   $node1, $reln12, $node2, $reln23, $node3, ...
 ], 'Neo4j::Bolt::Path'

=head1 METHODS

=over 

=item connect($url), connect_tls($url,$tls_hash)

Class method, connect to Neo4j server. The URL scheme must be C<'bolt'>, as in

  $url = 'bolt://localhost:7687';

Returns object of type L<Neo4j::Bolt::Cxn>, which accepts Cypher queries and
returns a L<Neo4j::Bolt::ResultStream>.

To connect by SSL/TLS, use connect_tls, with a hashref with keys as follows

  ca_dir => <path/to/dir/of/CAs
  ca_file => <path/to/file/of/CAs
  pk_file => <path/to/private/key.pm
  pk_pass => <private/key.pm passphrase>

Example:

  $cxn = Neo4j::Bolt->connect_tls('bolt://all-the-young-dudes.us:7687', { ca_cert => '/etc/ssl/cert.pem' });

When neither C<ca_dir> nor C<ca_file> are specified, an attempt will
be made to use the default trust store instead.
This requires L<IO::Socket::SSL> or L<Mozilla::CA> to be installed.

=item set_log_level($LEVEL)

When $LEVEL is set to one of the strings C<ERROR WARN INFO DEBUG> or C<TRACE>,
libneo4j-client native logger will emit log messages at or above the given
level, on STDERR.

Set to C<NONE> to turn off completely (the default).

=back

=head1 INSTALLATION

Visit L<Neo4j::Bolt|https://metacpan.org/pod/Neo4j::Bolt> on CPAN
for the newest released version and installation instructions.

=head1 SEE ALSO

L<Neo4j::Bolt::Cxn>, L<Neo4j::Bolt::ResultStream>.

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN
 majensen -at- cpan -dot- org

=head1 CONTRIBUTORS

=over

=item Arne Johannessen (@johannessen)

=back

=head1 LICENSE

This software is Copyright (c) 2019-2021 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004


=cut

1;
