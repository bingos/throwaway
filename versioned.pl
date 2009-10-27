use strict;
use warnings;
use Config;

my $versiononly = $Config::Config{versiononly};
my $startperl   = $Config::Config{startperl};
my $version     = sprintf("%vd",$^V);

print "This is versioned\n"
  if $versiononly and $startperl =~ /\Q$version\E$/;
