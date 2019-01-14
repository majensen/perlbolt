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

[Neo4j::Bolt::ResultStream](/lib/Neo4j/Bolt/ResultStream.md) objects are created by a successful query 
performed on a [Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md). They are iterated to obtain the rows
of the response as Perl arrays (not arrayrefs).

# METHODS

- fetch\_next\_()

    Obtain the next row of results as an array. Returns false when done.

- fieldnames\_()

    Obtain the column names of the response as an array.

- nfields\_()

    Obtain the number of fields in the response row as an integer.

# SEE ALSO

[Neo4j::Bolt](/lib/Neo4j/Bolt.md), [Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md).

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN
    majensen -at- cpan -dot- org

# LICENSE

This software is Copyright (c) 2019 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
