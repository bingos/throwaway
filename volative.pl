use strict;
use warnings;
use CPANDB;
 
print "$_\n" for map { $_->release }
  CPANDB::Distribution->select('order by volatility desc limit 100');

print CPANDB->sqlite, "\n";
