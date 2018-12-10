
use Inline C => <<'ENDC';

void tryh(SV* rv) {
  HE *ent;
  HV* hv;
  char *k;
  I32 retlen;
  hv = (HV*)SvRV(rv);
  hv_iterinit(hv);
  for (ent=hv_iternext(hv);ent != NULL;ent=hv_iternext(hv)) {
    k = hv_iterkey(ent,&retlen);
    printf("key: %s (%d)\n",k,retlen );
  }
  return;
}

ENDC

%h = ( this => "that", is => "some", key => "dude" );
tryh(\%h);
1;
