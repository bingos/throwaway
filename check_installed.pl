use strict;
use warnings;
use Module::Load::Conditional qw(check_install);

foreach my $module ( sort @ARGV ) {
  my $href = check_install( module => $module );
  next unless $href;
  print join(',',$module,(defined $href->{version} ? $href->{version} : '')), "\n";
}
