use strict;
use warnings;
use Getopt::Long;
use Module::Load::Conditional qw(check_install);

my $mi;
my $dzil;
my $spaces = 32;

GetOptions( 'mi' => \$mi, 'dzil' => \$dzil, 'spaces=i', \$spaces );

foreach my $module ( sort @ARGV ) {
  my $href = check_install( module => $module );
  next unless $href;
  if ( $dzil ) {
    my $join = ' ' x ( $spaces - length($module) );
    print join("$join= ", $module, (defined $href->{version} ? $href->{version} : '0') ), "\n";
  }
  elsif ( $mi ) {
    print join(' ', 'requires', qq{'$module'}, '=>', (defined $href->{version} ? qq{'$href->{version}'} : q{'0'}) ), ";\n";
  } 
  else {
    print join(',',$module,(defined $href->{version} ? $href->{version} : '')), "\n";
  }
}
