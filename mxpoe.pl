use strict;
use warnings;
use lib '.';
use POE;
use mxpoet;

my $mxpoe = mxpoet->new();

$poe_kernel->run();
exit 0;
