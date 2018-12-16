use Test::More;
use Fcntl;
use lib '..';
use lib '../lib';
use File::Spec;
use Bolt;
use Bolt::NeoValue;
use t::BoltFile;

$__SIG__{WARN} = sub { print $_[0] };
$__SIG__{DIE} = sub { print $_[0] };
my $dir = (-e 't' ? 't' : '.');

my $testf = File::Spec->catfile($dir,"samples","stream_test.blt");

ok my $bf = t::BoltFile->open_bf($testf,O_WRONLY | O_CREAT), "open bolt file";

my @nv = Bolt::NeoValue->of(
  { _node => 1534, prop1 => 3, prop2 => "pseudo" },
  15,
  "a string",
  { _relationship => 343, _start => 1534, _end => 58, _type => "has_foo"},
  ["list", "of", "things"]
 );

ok $bf->write_values(@nv), "write neo values";
#$bf->close_bf;

my $bff = t::BoltFile->open_bf($testf,O_RDONLY);
is_deeply $bff->_read_value->_as_perl,{ _node => 1534, prop1 => 3, prop2 => "pseudo" }, "read node value";
is $bff->_read_value->_as_perl,15, "read integer";
is $bff->_read_value->_as_perl,"a string", "read string";
is_deeply $bff->_read_value->_as_perl,{ _relationship => 343, _start => 1534, _end => 58, _type => "has_foo"}, "read relationship";
is_deeply $bff->_read_value->_as_perl,  ["list", "of", "things"], "read list";
$bff->close_bf;

unlink $testf;
done_testing;
