use Test::More;
use lib '../lib';
use Inline P;

pass;

done_testing;
__END__
__P__
  #include<string.h>
  int main () {
    printf("Hey dude.\n");
  }
