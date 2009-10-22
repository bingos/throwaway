use 5.11.1;
use strict;
use warnings;
use Module::CoreList;
use Module::Load::Conditional qw[check_install];
use Config;

my $mod = shift || die "usage: deprecated.pl <module>\n";

unless ( exists $Module::CoreList::version{ 0+$] }{$mod} ) {
  warn "That is not a core module\n";
  exit 0;
}

unless ( Module::CoreList::is_deprecated( $mod, $] ) ) {
  warn "That core module is not deprecated in $]\n";
  exit 0;
}

my $ref = check_install( module => $mod, verbose => 0 );
if ( $Config{privlibexp} eq $ref->{dir} ) {
  warn "That core module was so loaded from 'privlibexp'\n"
}
else {
  warn "Cool, it must have loaded from somewhere else\n";
}
