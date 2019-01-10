use Test::More;
use Module::Build;
use Fcntl;
use File::Spec;
use Neo4j::Bolt;
use Neo4j::Bolt::NeoValue;

BEGIN {
  unless (Module::Build->current->notes('libneo_loc')) {
    plan skip_all => "libneo4j-client build directory not set; skipping";
  }
}

use t::BoltFile;

my $dir = (-e 't' ? 't' : '.');

my $testf = File::Spec->catfile($dir,"stream_test.blt");

ok my $bf = t::BoltFile->open_bf($testf,O_WRONLY | O_CREAT), "open bolt file";

my @nv = Neo4j::Bolt::NeoValue->of(
  { _node => 1534, prop1 => 3, prop2 => "pseudo", _labels => ['thing'] },
  15,
  "a string",
  { _relationship => 343, _start => 1534, _end => 58, _type => "has_foo"},
  ["list", "of", "things"]
 );

ok $bf->write_values(@nv), "write neo values";
#$bf->close_bf;

my $bff = t::BoltFile->open_bf($testf,O_RDONLY);
is_deeply $bff->_read_value->_as_perl,{ _node => 1534, prop1 => 3, prop2 => "pseudo", _labels => ['thing'] }, "read node value";
is $bff->_read_value->_as_perl,15, "read integer";
is $bff->_read_value->_as_perl,"a string", "read string";
is_deeply $bff->_read_value->_as_perl,{ _relationship => 343, _start => 1534, _end => 58, _type => "has_foo"}, "read relationship";
is_deeply $bff->_read_value->_as_perl,  ["list", "of", "things"], "read list";
$bff->close_bf;

unlink $testf;
done_testing;
