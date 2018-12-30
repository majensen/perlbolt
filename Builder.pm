package Builder;
use File::Spec;
use Try::Tiny;
use base 'Module::Build';
__PACKAGE__->add_property( 'inline_modules' );

# use Inline compile/install
sub ACTION_build {
  my $self = shift;
  my $mod_ver = $self->dist_version;
  $self->SUPER::ACTION_build;
  for my $m (@{$self->inline_modules}) {
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
