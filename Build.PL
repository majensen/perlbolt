use lib '.';
use Builder;
use ExtUtils::CChecker;
use Try::Tiny;

my $DEFAULT_URL = "bolt://localhost:7687";

my $cc = ExtUtils::CChecker->new( quiet => 1);
my $code_cc = <<CC;
#include <neo4j-client.h>
int main(int argc, char *argv[]) {
  return neo4j_type(neo4j_null);
}
CC
my $build = Builder->new(
  dist_name => "Neo4j-Bolt",
  dist_version_from => "lib/Neo4j/Bolt.pm",
  dist_abstract => "Neo4j server agent using Bolt protocol",
  configure_requires => {
    'Module::Build' => '0.36_14',
    'ExtUtils::CChecker' => 0,
    'Try::Tiny' => 0,
  },
  requires => {
    'Inline::C' => 0,
  },
  build_requires => {
    'Inline' => 0,
    'Try::Tiny' => 0,
  },
  recommends => {
    Pod::Markdown => 0,
   },
  license => 'Apache_2_0',
  # inline_modules is a property added in the subclass 'Builder.pm'
  inline_modules => [
    # note: the commented modules get built automatically as require'd deps
    # all can be uncommented, but Inline will redundantly compile, build, and
    # erase them from blib/lib/auto...
#    'Neo4j::Bolt::TypeHandlersC',
    'Neo4j::Bolt::NeoValue',
#    'Neo4j::Bolt::Cxn',
#    'Neo4j::Bolt::ResultStream',
    'Neo4j::Bolt',
  ],
 );

$build->add_to_cleanup("_Inline");
$build->add_to_cleanup("lib/Neo4j/Bolt/Config.pm");

# look for libneo4j-client
open my $errh, '>&STDERR';
open STDERR, '>/tmp/xxx_try_bolt_compile_run';
unless (
  $cc->try_compile_run(source => $code_cc,
		       extra_linker_flags => ['-lneo4j-client'],)
 ) {
  try {
    print "Neo4j::Bolt requires the libneo4j-client library and the header file 'neo4j-client.h'.\n";
    my $lib = $build->prompt("Enter the directory containing the library: ");
    die unless $lib && -d $lib;
    my $inc = $build->prompt("Enter the directory containing the header file: ");
    die unless $inc && -d $inc;
    $cc->push_extra_linker_flags("-L$lib", "-lneo4j-client");
    $cc->push_extra_compiler_flags("-I$inc");
    $cc->try_compile_run($code_cc) or die;
  } catch {
    print "libneo4j-client cannot be found.\n";
    print "To obtain libneo4j-client, follow the steps at https://github.com/cleishm/libneo4j-client#neo4j-client, and try the Neo4j::Bolt installation again.\n";
    exit(1);
  };
}
unlink '>/tmp/xxx_try_bolt_compile_run';
open STDERR, '>&', $errh;

#add libraries if needed
unless (grep /^-lneo4j-client$/,@{$cc->extra_linker_flags}) {
  $cc->push_extra_linker_flags('-lneo4j-client');
}

$build->notes(libneo_loc => $build->prompt("Enter local libneo4j-client build directory (req'd for some tests, RET to skip): ",undef));
if ($build->notes('libneo_loc')) {
  unless (-e File::Spec->catfile($build->notes('libneo_loc'),'lib','src','iostream.h')) {
    $build->notes(libneo_loc =>
		    $build->prompt("That doesn't look like the libneo4j-client directory. Try again (or RET to skip): ",undef));
  }
}

if ($build->notes('libneo_loc')) {
  $cc->push_extra_compiler_flags(
    "-I".File::Spec->catdir($build->notes('libneo_loc'), qw/lib src/)
     );
}

$build->extra_linker_flags(@{$cc->extra_linker_flags});
$build->extra_compiler_flags(@{$cc->extra_compiler_flags});
print join("\n",@{$build->extra_linker_flags}),"\n";
print join("\n",@{$build->extra_compiler_flags}),"\n";


if ($build->y_n("Would you like to perform read-only tests on a local database?","n")) {
  $build->notes( 'db_url' =>
		   $build->prompt("Enter local Neo4j address and bolt port: ",
				  $DEFAULT_URL));
  $build->notes( 'db_user' =>
		   $build->prompt("Enter Neo4j username for ".$build->notes('db_url')." (RET if none): ",undef) );
  if (length $build->notes('db_user')) {
    $build->notes( 'db_pass' =>
		     $build->prompt("Enter Neo4j password: ","") );
  }
}

$build->create_build_script;

