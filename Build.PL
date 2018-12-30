use lib '.';
use Builder;

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
  },
  inline_modules => [
    'Neo4j::Bolt::TypeHandlersC',
    'Neo4j::Bolt::NeoValue',
    'Neo4j::Bolt::Cxn',
    'Neo4j::Bolt::ResultStream',
    'Neo4j::Bolt',
  ],
 );

$build->add_to_cleanup("_Inline");

$build->notes(libneo_loc => $build->prompt("Enter local libneo4j-client build directory: ","."));

$build->create_build_script;

# perl -Mblib -MInline=NOISY,_INSTALL_ -MInline=Config,name,Neo4j::Bolt::TypeHandlersC,version,0.01 -MNeo4j::Bolt::TypeHandlersC -e 1 0.01 blib/arch
