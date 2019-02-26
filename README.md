# NAME

Neo4j::Bolt - query Neo4j using Bolt protocol

[![Build Status](https://travis-ci.org/majensen/perlbolt.svg?branch=master)](https://travis-ci.org/majensen/perlbolt)

# SYNOPSIS

    use Neo4j::Bolt;
    $cxn = Neo4j::Bolt->connect("bolt://localhost:7687");
    $stream = $cxn->run_query_(
      "MATCH (a) RETURN head(labels(a)) as lbl, count(a) as ct",
      {} # parameter hash required
    );
    @names = $stream->fieldnames_;
    while ( my @row = $stream->fetch_next_ ) {
      print "For label '$row[0]' there are $row[1] nodes.\n";
    }
    $stream = $cxn->run_query_(
      "MATCH (a) RETURN labels(a) as lbls, count(a) as ct",
      {} # parameter hash required
    );
    while ( my @row = $stream->fetch_next_ ) {
      print "For label set [".join(',',@{$row[0]})."] there are $row[1] nodes.\n";
    }

# DESCRIPTION

[Neo4j::Bolt](/lib/Neo4j/Bolt.md) is a Perl wrapper around Chris Leishmann's excellent
[libneo4j-client](https://github.com/cleishm/libneo4j-client) library
implementing the Neo4j [Bolt](https://boltprotocol.org/) network
protocol. It uses Ingy's [Inline::C](https://metacpan.org/pod/Inline::C) to do all the hard XS work.

## Return Types

[Neo4j::Bolt::ResultStream](/lib/Neo4j/Bolt/ResultStream.md) returns rows resulting from queries made 
via a [Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md). These rows are simple arrays of scalars and/or
references. These represent Neo4j types according to the following:

    Neo4j type       Perl representation
    ----- ----       ---- --------------
    Null             undef
    Bool             scalar (0 or 1)
    Int              scalar
    Float            scalar
    String           scalar
    Bytes            scalar
    List             arrayref
    Map              hashref
    Node             hashref
    Relationship     hashref
    Path             arrayref of hashrefs

Nodes, Relationships and Paths are represented in [REST::Neo4p](https://metacpan.org/pod/REST::Neo4p) "as\_simple()"
formats:

    Node:
    { _node => $node_id, _labels => [ $label1, $label2, ...],
      prop1 => $value1, prop2 => $value2, ...}

    Relationship:
    { _relationship => $reln_id, 
      _start => $start_node_id, _end => $end_node_id,
      prop1 => $value1, prop2 => $value2, ...}

    Path:
    [ $node1, $reln12, $node2, $reln23, $node3,...]

# METHODS

- connect\_($url)

    Class method, connect to Neo4j server. The URL scheme must be `'bolt'`, as in

        $cxn = bolt://localhost:7687

    Returns object of type [Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md), which accepts Cypher queries and
    returns a [Neo4j::Bolt::ResultStream](/lib/Neo4j/Bolt/ResultStream.md).

# SEE ALSO

[Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md), [Neo4j::Bolt::ResultStream](/lib/Neo4j/Bolt/ResultStream.md).

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN
    majensen -at- cpan -dot- org

# CONTRIBUTORS

- Arne Johannessen (@johannessen)

# LICENSE

This software is Copyright (c) 2019 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
