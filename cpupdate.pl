use strict;
use CPANPLUS::Backend;
my $cb = CPANPLUS::Backend->new();
my @rv; my %seen;
for my $mod ( @{$cb->_all_installed} ) {
  next if $mod->is_uptodate;
  next if $mod->package_is_perl_core;
  push @rv, $mod if !$seen{$mod->package}++;
}
$_->install for sort { $a->module cmp $b->module } @rv;
