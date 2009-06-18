package test_httpd;

use strict;
use warnings;
use POE qw(Filter::HTTPD Filter::Stream Component::Client::HTTP Filter::HTTP::Parser);
use HTTP::Status qw(status_message RC_BAD_REQUEST RC_OK RC_LENGTH_REQUIRED);
use Test::POE::Server::TCP;
use Test::POE::Client::TCP;

our $VERSION = '0.02';

my $agent = 'proxy' . $$;

use MooseX::POE;

has 'address' => (
  is => 'ro',
);

has 'port' => (
  is => 'ro',
  default => sub { 0 },
  writer => '_set_port',
);

has 'hostname' => (
  is => 'ro',
  default => sub { require Sys::Hostname; return Sys::Hostname::hostname(); },
);

has '_httpd' => (
  accessor => 'httpd',
  isa => 'Test::POE::Server::TCP',
  lazy_build => 1,
  init_arg => undef,
);

has '_requests' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub {{}},
  init_arg => undef,
);

sub _build__httpd {
  my $self = shift;
  Test::POE::Server::TCP->spawn(
     address => $self->address,
     port => $self->port,
     prefix => 'httpd',
     filter => POE::Filter::HTTP::Parser->new( type => 'server' ),
  );
}

sub START {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->httpd;
  return;
}

event 'httpd_registered' => sub {
  my ($kernel,$self,$httpd) = @_[KERNEL,OBJECT,ARG0];
  warn ref $httpd, "\n";
  warn $httpd->port, "\n";
  return;
};

event 'httpd_connected' => sub {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  warn "Client connected\n";
  $self->httpd->client_wheel( $_[ARG0] )->set_output_filter( POE::Filter::Stream->new() );
  return;
};

event 'httpd_disconnected' => sub {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  if ( my $tunnel = $self->_requests->{$id}->{tunnel} ) {
     $tunnel->terminate;
     delete $self->_requests->{$id}->{tunnel};
     delete $self->_requests->{$id};
     warn "Client Close '$id'\n";
     return;
  }
  my $httpc = delete $self->_requests->{$id}->{httpc};
  $kernel->post( $httpc, 'shutdown' );
  delete $self->_requests->{$id};
  warn "Client Close '$id'\n";
  return;
};

event 'httpd_client_input' => sub {
  my ($kernel,$self,$id,$request) = @_[KERNEL,OBJECT,ARG0,ARG1];
  if ( my $tunnel = $self->_requests->{$id}->{tunnel} ) {
     $tunnel->send_to_server( $request );
     return;
  }
  my $httpc = join('-',$agent,$id);
  warn $request->as_string;
  if ( $request->method eq 'CONNECT' ) {
     my ($host,$port) = split /:/, $request->uri;
     return unless $host and $port;
     my $tunnel = Test::POE::Client::TCP->spawn(
	alias => $id,
	prefix => 'tunnel',
	autoconnect => 1,
	filter => POE::Filter::Stream->new(),
	address => $host,
	port => $port,
     );
     $self->_requests->{$id}->{tunnel} = $tunnel;
     return;
  }
  POE::Component::Client::HTTP->spawn(
     Alias => $httpc,
     Streaming => 4096,
     FollowRedirects => 2,
  );
  $self->_requests->{$id} = { stream => 0, agent => $httpc, };
  $request->remove_header('Accept-Encoding');
  $kernel->post( 
    $httpc, 
    'request',
    '_response',
    $request, 
    "$id",
  );
  return;
};

event 'httpd_client_flushed' => sub {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  warn "Client Flushed\n";
  return;
  if ( $self->_requests->{$id}->{chunk} ) {
    warn "First CHUNK ... switch to stream\n";
    $self->_requests->{$id}->{stream} = 1;
    $self->httpd->client_wheel( $id )->set_output_filter( POE::Filter::Stream->new() );
    my $chunk = delete $self->_requests->{$id}->{chunk};
    $self->httpd->send_to_client( $id, $chunk );
    return;
  }
  if ( $self->_requests->{$id}->{done} ) {
    warn "DONE ... switch filters back\n";
    $self->_requests->{$id}->{stream} = 0;
    delete $self->_requests->{$id}->{done};
    my $wheel = $self->httpd->client_wheel( $id );
    $wheel->set_output_filter( $wheel->get_input_filter() );
    return;
  }
  return;
};

event '_response' => sub {
  my ($kernel,$self,$request_packet,$response_packet) = @_[KERNEL,OBJECT,ARG0,ARG1];
  my $id = $request_packet->[1];
  my $response = $response_packet->[0];
  my $chunk    = $response_packet->[1];
  use Data::Dumper;
  $Data::Dumper::Indent=1;
  warn Dumper( $self->_requests );
  unless ( $self->_requests->{$id}->{stream} ) {
     $self->_requests->{$id}->{stream} = 1;
     $self->httpd->send_to_client( $id, _response_headers( $response ) );
  }
  unless ( $chunk ) {
     $self->_requests->{$id}->{stream} = 0;
     return;
  }
  $self->httpd->send_to_client( $id, $chunk );
  return;
};

event 'tunnel_socket_failed' => sub {
};

event 'tunnel_connected' => sub {
};

event 'tunnel_disconnected' => sub {
};

event 'tunnel_input' => sub {
};

sub _response_headers {
    my $resp = shift;
    my $code           = $resp->code;
    my $status_message = status_message($code) || "Unknown Error";
    my $message        = $resp->message  || "";
    my $proto          = $resp->protocol || 'HTTP/1.0';

    my $status_line = "$proto $code";
    $status_line   .= " ($status_message)"  if $status_message ne $message;
    $status_line   .= " $message" if length($message);

    # Use network newlines, and be sure not to mangle newlines in the
    # response's content.

    my @headers;
    push @headers, $status_line;
    push @headers, $resp->headers_as_string("\x0D\x0A");

    return join("\x0D\x0A", @headers, "") . $resp->content;
}

no MooseX::POE;

__PACKAGE__->meta->make_immutable;

1;

__END__
