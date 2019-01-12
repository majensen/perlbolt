# NAME

Neo4j::Bolt - query Neo4j using Bolt protocol

# SYNOPSIS

    use Neo4j::Bolt;
    $cxn = Neo4j::Bolt->connect_("bolt://localhost:7687");
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

[Neo4j::Bolt](https://metacpan.org/pod/Neo4j::Bolt) is a Perl wrapper around Chris Leishmann's excellent
[libneo4j-client](https://github.com/cleishm/libneo4j-client) library
implementing the Neo4j [Bolt](https://boltprotocol.org/) network
protocol. It uses Ingy's [Inline::C](https://metacpan.org/pod/Inline::C) to do all the hard XS work.

# METHODS

- connect\_($url)

    Class method, connect to Neo4j server. The URL scheme must be `'bolt'`, as in

        $cxn = bolt://localhost:7687

    Returns object of type [Neo4j::Bolt::Cxn](https://metacpan.org/pod/Neo4j::Bolt::Cxn), which accepts Cypher queries and
    returns a [Neo4j::Bolt::ResultStream](https://metacpan.org/pod/Neo4j::Bolt::ResultStream).

# SEE ALSO

[Neo4j::Bolt::Cxn](https://metacpan.org/pod/Neo4j::Bolt::Cxn), [Neo4j::Bolt::ResultStream](https://metacpan.org/pod/Neo4j::Bolt::ResultStream).

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN
    majensen -at- cpan -dot- org

# LICENSE

This software is Copyright (c) 2019 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004

---

# NAME

Neo4j::Bolt::Cxn - Container for a Neo4j Bolt connection

# SYNOPSIS

    use Neo4j::Bolt;
    $cxn = Neo4j::Bolt->connect_("bolt://localhost:7687");
    $stream = $cxn->run_query_(
      "MATCH (a) RETURN head(labels(a)) as lbl, count(a) as ct",
      {} # parameter hash required
    );

# DESCRIPTION

[Neo4j::Bolt::Cxn](https://metacpan.org/pod/Neo4j::Bolt::Cxn) is a container for a Bolt connection, instantiated by
a call to `Neo4j::Bolt::connect_()`.

# METHODS

- run\_query\_( $cypher\_query )

    Run a [Cypher](https://neo4j.com/docs/cypher-manual/current/) query on
    the server. Returns a [Neo4j::Bolt::ResultStream](https://metacpan.org/pod/Neo4j::Bolt::ResultStream) which can be iterated
    to retrieve query results as Perl types and structures.

- reset\_()

    Send a RESET message to the Neo4j server. According to the [Bolt
    protocol](https://boltprotocol.org/v1/), this should force any currently
    processing query to abort, forget any pending queries, clear any 
    failure state, dispose of outstanding result records, and roll back 
    the current transaction.

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN
    majensen -at- cpan -dot- org

# LICENSE

This software is Copyright (c) 2019 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004

---

# NAME

Neo4j::Bolt::ResultStream - Iterator on Neo4j Bolt query response

# SYNOPSIS

    use Neo4j::Bolt;
    $cxn = Neo4j::Bolt->connect_("bolt://localhost:7687");

    $stream = $cxn->run_query_(
      "MATCH (a) RETURN labels(a) as lbls, count(a) as ct",
      {} # parameter hash required
    );
    while ( my @row = $stream->fetch_next_ ) {
      print "For label set [".join(',',@{$row[0]})."] there are $row[1] nodes.\n";
    }

# DESCRIPTION

[Neo4j::Bolt::ResultStream](https://metacpan.org/pod/Neo4j::Bolt::ResultStream) objects are created by a successful query 
performed on a [Neo4j::Bolt::Cxn](https://metacpan.org/pod/Neo4j::Bolt::Cxn). They are iterated to obtain the rows
of the response as Perl arrays (not arrayrefs).

# METHODS

- fetch\_next\_()

    Obtain the next row of results as an array. Returns false when done.

- fieldnames\_()

    Obtain the column names of the response as an array.

- nfields\_()

    Obtain the number of fields in the response row as an integer.

# SEE ALSO

[Neo4j::Bolt](https://metacpan.org/pod/Neo4j::Bolt), [Neo4j::Bolt::Cxn](https://metacpan.org/pod/Neo4j::Bolt::Cxn).

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN
    majensen -at- cpan -dot- org

# LICENSE

This software is Copyright (c) 2019 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004

---

# NAME

Neo4j::Bolt::TypeHandlersC - Low level Perl to Bolt converters

# SYNOPSIS

    // how Neo4j::Bolt::ResultStream uses it
     for (i=0; i<n; i++) {
       value = neo4j_result_field(result, i);
       perl_value = neo4j_value_to_SV(value);
       Inline_Stack_Push( perl_value );
     }

# DESCRIPTION

[Neo4j::Bolt::TypeHandlersC](https://metacpan.org/pod/Neo4j::Bolt::TypeHandlersC) is all C code, managed by [Inline::C](https://metacpan.org/pod/Inline::C). 
It tediously defines methods to convert Perl structures to Bolt
representations, and also tediously defines methods convert Bolt
data to Perl representations.

# METHODS

- neo4j\_value\_t SV\_to\_neo4j\_value(SV \*sv)

    Attempt to create the appropriate
    [libneo4j-client](https://github.com/cleishm/libneo4j-client)
    representation of the Perl SV argument.

- SV\* neo4j\_value\_to\_SV( neo4j\_value\_t value )

    Attempt to create the appropriate Perl SV representation of the 
    [libneo4j-client](https://github.com/cleishm/libneo4j-client) 
    neo4j\_value\_t argument.

# SEE ALSO

[Neo4j::Bolt](https://metacpan.org/pod/Neo4j::Bolt), [Neo4j::Bolt::Value](https://metacpan.org/pod/Neo4j::Bolt::Value), [Inline::C](https://metacpan.org/pod/Inline::C), 
[libneo4j-client API](http://neo4j-client.net/doc/latest/neo4j-client_8h.html).

# CONTRIBUTORS

Thanks to 

=over

=item * Arne Johannessen (@johannessen)

=back

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN
    majensen -at- cpan -dot- org

# LICENSE

This software is Copyright (c) 2019 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
