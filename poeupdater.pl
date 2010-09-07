use strict;
use warnings;
use ExtUtils::Installed;
use Module::Load::Conditional qw[check_install];

my %installed;

foreach my $module ( sort ExtUtils::Installed->new->modules() ) {
  my $href = check_install( module => $module );
  next unless $href;
  print "$module is core\n" if supplied_with_core( $module );
  #print join(',',$module,(defined $href->{version} ? $href->{version} : '')), "\n";
  $installed{ $module } = defined $href->{version} ? $href->{version} : '';
}

exit 0;

sub supplied_with_core {
  my $name = shift;
  my $ver = shift || $];
  require Module::CoreList;
  return $Module::CoreList::version{ 0+$ver }->{ $name };
}

sub _vcmp {
  my ($x, $y) = @_;
  s/_//g foreach $x, $y;
  return $x <=> $y;
}
