# NAME

Neo4j::Bolt::Duration - Representation of a Neo4j duration structure

# SYNOPSIS

    $q = "RETURN datetime('P1Y10MT5H30S')";
    $dt = ( $cxn->run_query($q)->fetch_next )[0];

    $months = $dt->{months};
    $days = $dt->{days};
    $secs = $dt->{secs};
    $nanosecs = $dt->{nsecs};

    $perl_dt = $node->as_DTDuration;

# DESCRIPTION

[Neo4j::Bolt::Duration](/lib/Neo4j/Bolt/Duration.md) instances are created by executing
a Cypher query that returns a duration value
from the Neo4j database.

The values in the Bolt structure are described at [https://neo4j.com/docs/bolt/current/bolt/structure-semantics/](https://neo4j.com/docs/bolt/current/bolt/structure-semantics/). The Neo4j::Bolt::Duration object possesses integer values
for the keys `months`, `days`, `secs`, and `nsecs`.

Use the ["as\_DTDuration"](#as_dtduration) method to obtain an equivalent [DateTime::Duration](https://metacpan.org/pod/DateTime::Duration)
object that can be used in the [DateTime](https://metacpan.org/pod/DateTime) context (e.g., to perform time arithmetic).

# METHODS

- as\_DTDuration()

        $perl_dt  = $dt->as_DTDuration;

# SEE ALSO

[Neo4j::Bolt](/lib/Neo4j/Bolt.md), [Neo4j::Types::Duration](/lib/Neo4j/Types/Duration.md), [DateTime](https://metacpan.org/pod/DateTime), [DateTime::Duration](https://metacpan.org/pod/DateTime::Duration)

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN

# LICENSE

This software is Copyright (c) 2023 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
