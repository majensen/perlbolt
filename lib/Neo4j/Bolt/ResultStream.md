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
    # check that the stream emptied cleanly...
    if ( $stream->failure_ ) {
      print STDERR "Uh oh: ".($stream->client_errmsg_ || $stream->server_errmsg_);
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

- success\_(), failure\_()

    Use these to check whether fetch\_next() succeeded. They indicate the 
    current error state of the result stream. If 

        $stream->success_ == $stream->failure_ == -1

    then the stream has not yet been accessed.

- client\_errnum\_(), client\_errmsg\_(), server\_errcode\_(),
server\_errmsg\_()

    If `$stream-`failure\_> is true, these will indicate what happened.

    If the error occurred within the `libneo4j-client` code,
    `client_errnum_()` will provide the `errno` and `client_errmsg_()`
    the associated error message. This is a probably a good time to file a
    bug report.

    If the error occurred at the server, `server_errcode_()` and
    `server_errmsg_()` will contain information sent by the server. In
    particular, Cypher syntax errors will appear here.

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
