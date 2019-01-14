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

[Neo4j::Bolt::Cxn](/lib/Neo4j/Bolt/Cxn.md) is a container for a Bolt connection, instantiated by
a call to `Neo4j::Bolt::connect_()`.

# METHODS

- run\_query\_( $cypher\_query, $param\_hash )

    Run a [Cypher](https://neo4j.com/docs/cypher-manual/current/) query on
    the server. Returns a [Neo4j::Bolt::ResultStream](/lib/Neo4j/Bolt/ResultStream.md) which can be iterated
    to retrieve query results as Perl types and structures. `$param_hash` is
    a hashref of the form `{ param =` $value, ... }>. If there are no params
    to be set, use `{}`.

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
