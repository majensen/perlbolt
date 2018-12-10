use Module::Build;
my $build = Module::Build->new(
  dist_name => "Bolt",
  dist_version_from => "lib/Bolt.pm",
  dist_abstract => "Neo4j server agent using Bolt protocol",
  configure_requires => {
    'Module::Build' => 0,
  },
  requires => {
    'Inline::C' => 0,
  },
  build_requires => {},
 );

$build->create_build_script;
