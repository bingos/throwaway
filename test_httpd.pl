use strict;
use warnings;
use POE;
use lib '.';

use test_httpd;

my $test_httpd = test_httpd->new( port => 8080 );

$poe_kernel->run();
exit 0;
