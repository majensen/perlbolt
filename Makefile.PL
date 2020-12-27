use v5.10;
use ExtUtils::MakeMaker;
use Neo4j::Client;
use File::Spec;
use Data::Dumper qw/Dumper/;
use Try::Tiny;
use Config;
use Cwd qw/realpath/;
use strict;

# ensure that only Neo4j::Client library is used.

my $LDDLFLAGS = $Config{lddlflags};

my $META = {
  resources => {
    bugtracker => 'https://github.com/majensen/perlbolt/issues',
    repository => 'https://github.com/majensen/perlbolt.git',
  },
  x_contributors => {
    'Mark A. Jensen <majensen@cpan.org>',
    'Arne Johannessen <ajnn@cpan.org>',
   },
};

my $neo_info = prompt_for_db();
if ($neo_info) {
  try {
    if (-d 't') {
      open my $fh, ">", File::Spec->catfile('t','neo_info') or die "Can't open neo_info for writing.";
      say $fh Dumper($neo_info);
      close $fh;
    }
  } catch {
    print STDERR "$_; skipping live db tests\n";
  };
}

WriteMakefile(
  NAME => 'Neo4j::Bolt',
  VERSION_FROM => 'lib/Neo4j/Bolt.pm',
  PREREQ_PM => {
    'JSON::PP' => 0,
    'URI' => 0,
  },
  ABSTRACT => "Neo4j server agent using Bolt protocol",
  AUTHOR => ['Mark A. Jensen (majensen -at- cpan -dot- org)'],
  LICENSE => 'apache_2_0',
  BUILD_REQUIRES => {
    'ExtUtils::MakeMaker' => '7.12',
    'Test::Exception' => 0,
    'Pod::Usage' => 0,
    'Neo4j::Client' => '0.42',
  },
  # RECOMMENDS => {
  #   'Mozilla::CA' => 0,
  #   'Pod::Markdown' => 0,
  # },
  CCFLAGS => Neo4j::Client->cflags,
  LIBS => Neo4j::Client->libs_static,
  INC => "-iquote".realpath('.')."/include",
  # avoid a factory libneo4j-client in a standard location (possibly
  # in lddlflags):
  LDDLFLAGS => join(' ',Neo4j::Client->libs_static,$LDDLFLAGS),
  test => {TESTS => 't/*.t'},
  clean => {FILES => "t/neo_info"},
  XSMULTI => 1,
  META_MERGE => $META,
    
 );

sub prompt_for_db {
  my %neo_info;
  my $ans;
  while ($ans !~ /^[yn]/i) {
    $ans = prompt("Perform read-only tests on a local database?: ", "n");
  }
  return if (lc $ans eq 'n');

  $neo_info{host} = prompt("Host:port: ", "localhost:7687");
  $neo_info{user} = prompt("User: ","");
  $neo_info{pass} = prompt("Pass: ","");
  undef $ans;
  while ($ans !~ /^[yn]/i) {
    $ans = prompt("Will you allow add/delete tests on your database (cruft will be removed)?: ", "n");
  }
  $neo_info{tests} = (lc $ans eq 'y' ? 1 : 0);
  return \%neo_info;
}
