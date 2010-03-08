use strict;
use warnings;
use Getopt::Long;
use Module::Load::Conditional qw(check_install);

my $mi;

GetOptions( 'mi' => \$mi );

foreach my $module ( sort @ARGV ) {
  my $href = check_install( module => $module );
  next unless $href;
  if ( $mi ) {
    print join(' ', 'requires', qq{'$module'}, '=>', (defined $href->{version} ? qq{'$href->{version}'} : q{'0'}) ), "\n";
  } 
  else {
    print join(',',$module,(defined $href->{version} ? $href->{version} : '')), "\n";
  }
}
