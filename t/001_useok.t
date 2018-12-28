use Test::More;
use Module::Build;
use lib '../lib';
use strict;

use_ok("Neo4j::Bolt");
use_ok("Neo4j::Bolt::TypeHandlersC");
use_ok("Neo4j::Bolt::NeoValue");


done_testing;
