use Test::More;
use lib '..';
use lib '../lib';
use Bolt;
use Bolt::TypeHandlersC;
use t::BoltTest;

my $dir = (-e 't' ? 't' : '.');


done_testing;
