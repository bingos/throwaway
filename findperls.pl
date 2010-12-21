use strict;
use warnings;
use autodie;
use File::Spec;
use Module::CoreList;
use Perl::Version;
use Cwd;

my $path = shift || '.';
$path = Cwd::realpath($path);
die "Not a directory\n" unless -d $path;

print $path, "\n";

opendir my $dir, $path;
while (my $item = readdir $dir) {
  next if $item =~ /^(\.|devel|maint|latest)/;
  next if $item =~ /(RC|TRIAL)/;
  next unless $item =~ /\.tar\.(gz|bz2)$/;
  print $item, "\n";
}
closedir $dir;
