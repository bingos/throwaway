use strict;
use warnings;
use DateTime::Format::Strptime;

#my $date = 'Mon, 14 Dec 2009 13:39:44 GMT';
my $pattern = '%a, %d %b %Y %T %Z';

my $strp = DateTime::Format::Strptime->new(
                    pattern => $pattern,
#                    locale  => 'en_GB',
#                    time_zone => 'Europe/London',
                    on_error => 'croak',
);

while (<>) {
  chomp;
  if ( my ($date) = $_ =~ /^Last-Updated:\s+(.+)$/i ) {
    my $dt = $strp->parse_datetime( $date );
    print $dt->epoch, "\n";
    last;
  }
}

