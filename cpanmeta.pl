use 5.010;
use strict;
use warnings;
use CPAN::Meta;
use File::Spec;

my $cpan = '/home/ftp/CPAN';


my %packages;

{
  my $packages = File::Spec->catfile( $cpan, 'modules', '02packages.details.txt' );
  open my $fh, '<', $packages or die "$!\n";

  while (<$fh>) {
    last if /^\s*$/;
  }
  while (<$fh>) {
    chomp;
    my ($module,$version,$package_path) = split ' ', $_;
    next unless $version eq 'undef' or !$version;
    $packages{ $package_path } = undef;
  }
}

foreach my $package ( sort keys %packages ) {
  ( my $meta = $package ) =~ s!\.(zip|tgz|tar\.gz|tar\.bz2)!!;
  $meta .= '.meta';
  my $metafile = File::Spec->catfile( $cpan, 'authors', 'id', $meta );
  next unless -e $metafile;
  my $metastr = do { local $/; open my $fh, '<', $metafile or die "$!\n"; <$fh> };
  my $data;
  if ( $metastr =~ m!^\{! ) {
    $data = eval { CPAN::Meta->load_json_string( $metastr ) };
    next unless $data;
  }
  else {
    # assume yml
    $data = eval { CPAN::Meta->load_yaml_string( $metastr ) };
    next unless $data;
  }
  $packages{ $package } = $data->dynamic_config;
}

say "Total indexed dists: " . scalar keys %packages;
say "Total dynamic: " . scalar grep { $packages{$_} } keys %packages;
