use strict;
use warnings;
use CGI::Simple;
use YAML::Tiny;
use POE qw(Component::FastCGI Component::EasyDBI);

use constant PORT => 1027;

my $SEPARATOR = qr/ :: | ' /x;
our $module_re = qr/[[:alpha:]_] \w* (?: $SEPARATOR \w+ )*/xo;

my $dsn = 'dbi:SQLite:dbname=cpandb.db';

POE::Component::EasyDBI->new(
        alias    => 'dbi',
        dsn      => $dsn,
        username => '',
        password => '',
);

POE::Session->create(
   package_states => [
      'main' => [qw(_start _request _mod)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$session) = @_[KERNEL,SESSION];

  POE::Component::FastCGI->new(
    Port => PORT,
    Handlers => [
        [ '.*' => $session->postback( '_request' ) ],
    ]
  );

  return;
}

sub _request {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $request = $_[ARG1]->[0];
  my $path = $request->env('REQUEST_URI');
  my ($root,$enc,$type,$search) = grep { $_ } split m#/#, $path;
  # check enc
  if ( $type eq 'mod' ) {
     if ( is_valid_mod( $search ) ) {
        # send query to dbi
        $kernel->post( 'dbi',
          arrayhash => {
            sql => 'select mods.mod_name,mods.mod_vers,mods.cpan_id,dists.dist_name,dists.dist_vers,dists.dist_file from mods,dists where mod_name = ? and mods.dist_name = dists.dist_name',
            event => '_mod',
            placeholders => [ $search ],
            _request => $request,
          }
        );
        return;
     }
  }
  my $response = $request->make_response;
  $response->header("Content-type" => "text/html");
  $response->content("woot");
  $response->send;
  return;
}

sub _mod {
  my ($kernel,$heap,$res) = @_[KERNEL,HEAP,ARG0];
  my $request = delete $res->{_request};
  my $response = $request->make_response;
  $response->header('Content-type','application/x-yaml; charset=utf-8');
  my $string;
  eval { $string = YAML::Tiny::Dump($res->{result}); };
  $response->content($string);
  $response->send;
  return;
}

sub is_valid_mod {
  my $module = shift;
  return $module =~ /\A $module_re \z/xo;
}
