use strict;
use warnings;
use Parse::CPAN::MirroredBy;
use POE qw(Component::SmokeBox::Recent::HTTP);
use File::Spec::Unix;
use URI;

my $mirroredby = shift || die;

my @mirrors;

foreach my $mirror ( Parse::CPAN::MirroredBy->new()->parse_file( $mirroredby ) ) {
   my $type;
   $type = 'both' if $mirror->{dst_ftp} and $mirror->{dst_http};
   $type = 'http' if $mirror->{dst_http} and !$mirror->{dst_ftp};
   $type = 'ftp' if $mirror->{dst_ftp} and !$mirror->{dst_http};
   print $mirror->{dst_ftp}, ' ', $type, "\n" if $mirror->{dst_ftp};
   print $mirror->{dst_http}, ' ', $type, "\n" if $mirror->{dst_http};
   push @mirrors, $mirror->{dst_http} if $mirror->{dst_http};
}

POE::Session->create(
  package_states => [
      main => [qw(_start _launch http_sockerr http_timeout http_response)],
  ],
  heap => { mirrors => \@mirrors, },
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->yield( '_launch' );
  return;
}

sub _launch {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $url = shift @{ $heap->{mirrors} };
  return unless $url;
  my $uri = URI->new( $url );
  $uri->path( File::Spec::Unix->catfile( $uri->path(), 'modules', '02packages.details.txt.gz' ) );
  POE::Component::SmokeBox::Recent::HTTP->spawn(
      uri => $uri,
  );
  $kernel->yield( '_launch' );
  return;
}

sub http_sockerr {
  warn join ' ', @_[ARG0..$#_];
  return;
}
   
sub http_timeout {
  warn $_[ARG0], "\n";
  return;
}
   
sub http_response {
  my $http_response = $_[ARG0];
  print $http_response->as_string;
  return;
}
