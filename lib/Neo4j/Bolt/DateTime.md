# NAME

Neo4j::Bolt::DateTime - Representation of a Neo4j date/time related structure

# SYNOPSIS

    $q = "RETURN datetime('2021-01-21T12:00:00-0500')";
    $dt = ( $cxn->run_query($q)->fetch_next )[0];

    $neo4j_type = $dt->{neo4j_type}; # Date, Time, DateTime, LocalDateTime, LocalTime
    $epoch_days = $dt->{epoch_days};
    $epoch_secs = $dt->{epoch_secs};
    $secs = $dt->{secs};
    $nanosecs = $dt->{nsecs};
    $offset_secs = $dt->{offset_secs};

    $perl_dt = $node->as_DateTime;

# DESCRIPTION

[Neo4j::Bolt::DateTime](/lib/Neo4j/Bolt/DateTime.md) instances are created by executing
a Cypher query that returns one of the date/time Bolt structures
from the Neo4j database.

The values in the Bolt structures are described at [https://neo4j.com/docs/bolt/current/bolt/structure-semantics/](https://neo4j.com/docs/bolt/current/bolt/structure-semantics/). The Neo4j::Bolt::DateTime objects possess values
for the keys that are relevant to the underlying date/time structure.

Use the ["as\_DateTime"](#as_datetime) method to obtain an equivalent [DateTime](https://metacpan.org/pod/DateTime)
object that is probably easier to use.

# METHODS

- as\_DateTime()

        $perl_dt  = $dt->as_DateTime;
        
        $node_id = $simple->{_node};
        @labels  = @{ $simple->{_labels} };
        $value1  = $simple->{property1};
        $value2  = $simple->{property2};

    Obtain a [DateTime](https://metacpan.org/pod/DateTime) object equivalent to the Neo4j structure returned
    by the database. Time and LocalTime objects generate a DateTime whose date is the
    first day of the Unix epoch (1970-01-01).

# SEE ALSO

[Neo4j::Bolt](/lib/Neo4j/Bolt.md), [Neo4j::Types::DateTime](/lib/Neo4j/Types/DateTime.md), [DateTime](https://metacpan.org/pod/DateTime)

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN

# LICENSE

This software is Copyright (c) 2023 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
