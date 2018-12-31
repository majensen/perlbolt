package Builder;
use File::Spec;
use Try::Tiny;
use base 'Module::Build';
__PACKAGE__->add_property( 'inline_modules' );

# These are kludges to get Inline to create Inline modules that
# * have dependencies on one another
# * Module::Build can test and install properly
# * have runtime config dependencies (user-provided libneo4j-client build
# *  location)

# use Inline compile/install
sub ACTION_build {
  my $self = shift;
  my $mod_ver = $self->dist_version;
  $self->SUPER::ACTION_build;
  for my $m (@{$self->inline_modules}) {
    # this is an undocumented function (_INSTALL_) of Inline
    # that will likely not change, since it is integral to
    # Inline::MakeMaker
    $self->do_system( $^X, '-Mblib', '-MInline=NOISY,_INSTALL_',
		      "-MInline=Config,name,$m,version,$mod_ver",
		      "-M$m", "-e", "1", $mod_ver, 'blib/arch');
  }
}

sub ACTION_test {
  my $self = shift;
  my $dir = File::Spec->catdir(qw/t BoltFile/);
  if (-d 't') {
    unless (-d $dir) {
      mkdir $dir;
    }
    unless (-e File::Spec->catfile($dir,'Config.pm')) {
      # this is in order to set a user-provided variable early enough
      # that "use Inline => C => Config => ..." can see it in
      # t/BoltFile.pm
      try {
	open my $cf, ">", File::Spec->catfile($dir,'Config.pm') or die $!;
	my $loc = $self->notes('libneo_loc') // '/usr/local';
	print $cf "package t::BoltFile::Config;\n\$libneo_loc='$loc';\n1;\n";
	close $cf;
      } catch {
	printf STDERR "Builder failed to create t::BoltFile::Config: $_\n";
      };
    }
  }
  $self->SUPER::ACTION_test;
}
1;
