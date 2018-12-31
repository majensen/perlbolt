use lib '.';
use Builder;

my $DEFAULT_URL = "bolt://localhost:7687";
my $build = Builder->new(
  dist_name => "Neo4j-Bolt",
  dist_version_from => "lib/Neo4j/Bolt.pm",
  dist_abstract => "Neo4j server agent using Bolt protocol",
  configure_requires => {
    'Module::Build' => 0,
  },
  requires => {
    'Inline::C' => 0,
  },
  build_requires => {
    'Inline' => 0,
    'Try::Tiny' => 0,
  },
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

$build->notes(libneo_loc => $build->prompt("Enter local libneo4j-client build directory: ","."));

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

# perl -Mblib -MInline=NOISY,_INSTALL_ -MInline=Config,name,Neo4j::Bolt::TypeHandlersC,version,0.01 -MNeo4j::Bolt::TypeHandlersC -e 1 0.01 blib/arch
