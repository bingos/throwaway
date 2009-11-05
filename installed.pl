use strict;
use warnings;
use ExtUtils::Installed;
use Module::Load::Conditional qw(check_install);

foreach my $module ( sort ExtUtils::Installed->new->modules() ) {
  my $href = check_install( module => $module );
  next unless $href;
  print join(',',$module,(defined $href->{version} ? $href->{version} : '')), "\n";
}
