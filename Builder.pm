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
  my $libdir = '/usr/local/lib';
  open my $cf, ">", File::Spec->catfile($self->base_dir,qw/lib Neo4j Bolt Config.pm/) or die $!;
  my $liba = "$libdir/libneo4j-client.a";
  for my $L (@{$self->extra_linker_flags}) {
    if ($L =~ /^-L(.*)$/) {
      my $l = $1;
      $liba =~ s/$libdir\//$l/;
    }
  }

  my $extl = join(" ", @{$self->extra_linker_flags});
  my $extc = join(" ", @{$self->extra_compiler_flags});
  print $cf "package Neo4j::Bolt::Config;\n\$extl = '$extl';\n\$extc = '$extc';\n\$liba='$liba';\n1;\n";
  close $cf;
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
   unless (-d File::Spec->catdir(qw/blib arch auto Neo4j Bolt/)) {
     $self->depends_on('build');
   }
   $self->SUPER::ACTION_test;
 }



1;
