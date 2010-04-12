use strict;
use warnings;
use ExtUtils::Installed;
use File::Spec;
use File::Fetch;
use IO::Zlib;
use version;
use Module::Load::Conditional qw[check_install];

my $mirror = 'http://cpan.hexten.net/';

my %installed;
my %cpan;
my %seen;

foreach my $module ( sort ExtUtils::Installed->new->modules() ) {
  my $href = check_install( module => $module );
  next unless $href;
  $installed{ $module } = defined $href->{version} ? $href->{version} : 'undef';
}

my $loc = fetch_indexes('.',$mirror) or die;
populate_cpan( $loc );
foreach my $module ( sort keys %installed ) {
  # Eliminate core modules
  if ( supplied_with_core( $module ) and !$cpan{ $module } ) { 
    delete $installed{ $module };
    next;
  }
}

# Further eliminate choices.

foreach my $mod ( sort keys %installed ) {
  $seen{ $cpan{ $mod } }++;
}

print $_, "\n" for sort keys %seen;
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
  return version->parse($x) <=> version->parse($y);
}

sub populate_cpan {
  my $pfile = shift;
  my $fh = IO::Zlib->new( $pfile, "rb" ) or die "$!\n";
  my %dists;

  while (<$fh>) {
    last if /^\s*$/;
  }
  while (<$fh>) {
    chomp;
    my ($module,$version,$package_path) = split ' ', $_;
    $cpan{ $module } = $package_path;
  }
  return 1;
}

sub fetch_indexes {
  my ($location,$mirror) = @_;
  my $packages = 'modules/02packages.details.txt.gz';
  my $url = join '', $mirror, $packages;
  my $ff = File::Fetch->new( uri => $url );
  my $stat = $ff->fetch( to => $location );
  return unless $stat;
  print "Downloaded '$url' to '$stat'\n";
  return $stat;
}
