# NAME

Neo4j::Bolt::NeoValue - Container to hold Bolt-encoded values

# SYNOPSIS

    use Neo4j::Bolt::NeoValue;
    
    $neo_int = Neo4j::Bolt::NeoValue->of( 42 );
    $i = $neo_int->_as_perl;
    $neo_node = Neo4j::Bolt::NeoValue->of( 
      { _node => 1,
        _labels => ['thing','chose'],
        texture => 'crunchy',
        consistency => 'gooey'}
      );
    if ($neo_node->_neotype eq 'Node') {
      print "Yep, that's a node all right."
    }

    %node = %{ Neo4j::Bolt::NeoValue->is($neo_node) };
    
    ($h,$j) = Neo4j::Bolt::NeoValue->are($neo_node, $neo_int);

# DESCRIPTION

[Neo4j::Bolt::NeoValue](/lib/Neo4j/Bolt/NeoValue.md) is an interface to convert Perl values to
Bolt protocol byte structures via
[libneo4j-client](https://github.com/cleishm/libneo4j-client). It's
useful for testing the package, but you may find it useful in other
ways.

# METHODS

- of($thing), new($thing)

    Class method. Creates a NeoValue from a Perl scalar, arrayref, or
    hashref.

- \_as\_perl()

    Returns a Perl scalar, arrayref, or hashref representing the underlying 
    Bolt data stored in the object.

- \_neotype()

    Returns a string indicating the type of object that
    [libneo4j-client](https://github.com/cleishm/libneo4j-client) thinks
    the Bolt data represents.

- is($neovalue), are(@neovalues)

    Class method. Syntactic sugar; runs [\_as\_perl()](https://metacpan.org/pod/_as_perl\(\)) on the arguments.

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN
    majensen -at- cpan -dot- org

# LICENSE

This software is Copyright (c) 2019 by Mark A. Jensen.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
