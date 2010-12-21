use strict;
use warnings;
use File::Spec;
use File::Spec::Unix;
use File::Fetch;
use IO::Zlib;
use version;
use Module::Load::Conditional qw[check_install];

my $mirror = 'http://cpan.hexten.net/';

my $loc = fetch_indexes('.',$mirror) or die;

my $fh = IO::Zlib->new( $loc, "rb" ) or die "$!\n";

my %counts;

while (<$fh>) {
  last if /^\s*$/;
}
while (<$fh>) {
  chomp;
  my ($module,$version,$package_path) = split ' ', $_;
  my $count = split /::/, $module;
  push @{ $counts{ $count } }, $module;
}

print "$_,", join(',', sort @{ $counts{$_} } ), "\n" for sort { scalar @{ $counts{$b} } <=> scalar @{ $counts{$a} } } keys %counts;
exit 0;

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
