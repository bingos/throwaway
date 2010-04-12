use strict;
use warnings;
use POE qw(Component::Client::NNTP);
use Email::Simple;
use MIME::Base64;
use MIME::QuotedPrint;

my $article = shift or die;

$|=1;

POE::Component::Client::NNTP->spawn ( 'NNTP-Client', { NNTPServer => 'nntp.perl.org' } );

POE::Session->create(
  package_states => [
    main => [qw(_start nntp_200 nntp_211 nntp_220)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  $poe_kernel->post ( 'NNTP-Client' => register => 'all' );
  $poe_kernel->post ( 'NNTP-Client' => 'connect' );
  return;
}

sub nntp_200 {
  $poe_kernel->post( 'NNTP-Client' => group => 'perl.cpan.testers' );
  return;
}

sub nntp_211 {
  $poe_kernel->post( 'NNTP-Client' => article => $article );
  return;
}

sub nntp_220 {
  my ($kernel,$self,$text) = @_[KERNEL,OBJECT,ARG0];
 
  my $article = Email::Simple->new( join "\n", @{ $_[ARG1] } );
  my $from = $article->header('From');
  my $subject = $article->header('Subject');
  my $xref = $article->header('Xref');
  my $newsgroups = $article->header('Newsgroups');
  my $body = $article->body();
  my $encoding = $article->header('Content-Transfer-Encoding');
  my $xperl = $article->header('X-Test-Reporter-Perl');
  print $encoding, "\n" if $encoding;
  $body = decode_base64($body)  if($encoding && $encoding eq 'base64');
  $body = decode_qp($body)      if($encoding && $encoding eq 'quoted-printable');
  $newsgroups =~ s/^\"//;
  $newsgroups =~ s/\"$//;
  my $perl_version = $xperl || _extract_perl_version(\$body) || 'v0.0.0';
  print $perl_version, "\n";
  print $article->as_string;
  $kernel->post( $_[SENDER], 'shutdown' );
  return;
}

sub _extract_perl_version {
  my $body = shift;
 
  # Summary of my perl5 (revision 5.0 version 6 subversion 1) configuration:
  my ($rev, $ver, $sub, $extra) =
$$body =~ /Summary of my (?:perl\d+)? \((?:revision )?(\d+(?:\.\d+)?) (?:version|patchlevel) (\d+) subversion\s+(\d+) ?(.*?)\) configuration/s;
  
  return unless defined $rev;
 
  my $perl = $rev + ($ver / 1000) + ($sub / 1000000);
  $rev = int($perl);
  $ver = int(($perl*1000)%1000);
  $sub = int(($perl*1000000)%1000);
 
  my $version = sprintf "%d.%d.%d", $rev, $ver, $sub;
  $version .= " $extra" if $extra;
  return "v$version";
}
