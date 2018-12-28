package Builder;
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

1;
