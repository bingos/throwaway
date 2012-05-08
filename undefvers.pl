use 5.010;
use strict;
use warnings;
use File::Fetch;
use IO::Zlib;

$|=1;

my $mirror = 'http://cpan.mirror.local/CPAN/';

my %cpan;

my $loc = fetch_indexes('.',$mirror) or die;
populate_cpan( $loc );

say for sort keys %cpan;
say "Total dists: " . scalar keys %cpan;
exit 0;

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
    next unless $version eq 'undef' or !$version;
    $cpan{ $package_path }++;
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
  warn "Downloaded '$url' to '$stat'\n";
  return $stat;
}
