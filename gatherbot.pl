  # A simple Rot13 'encryption' bot

  use strict;
  use warnings;
  use POE qw(Component::IRC::State);

  my $nickname = 'Flibble' . $$;
  my $ircname = 'Flibble the Sailor Bot';
  my $ircserver = 'irc.freenode.net';
  my $port = 6667;

  my @channels = ( '#perl', );

  $|=1;

  # We create a new PoCo-IRC object and component.
  my $irc = POE::Component::IRC::State->spawn( 
        nick => $nickname,
        server => $ircserver,
        port => $port,
        ircname => $ircname,
	debug => 0,
  ) or die "Oh noooo! $!";

  POE::Session->create(
        package_states => [
                'main' => [ qw(_default _start irc_001 irc_chan_sync) ],
        ],
        heap => { irc => $irc },
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # We get the session ID of the component from the object
    # and register and connect to the specified server.
    my $irc_session = $heap->{irc}->session_id();
    $kernel->post( $irc_session => register => 'all' );
    $kernel->post( $irc_session => connect => { } );
    undef;
  }

  sub irc_001 {
    my ($kernel,$sender) = @_[KERNEL,SENDER];

    # Get the component's object at any time by accessing the heap of
    # the SENDER
    my $poco_object = $sender->get_heap();
    print "Connected to ", $poco_object->server_name(), "\n";

    # In any irc_* events SENDER will be the PoCo-IRC session
    $kernel->post( $sender => join => $_ ) for @channels;
    undef;
  }

  sub irc_chan_sync {
    my ($kernel,$heap,$channel,$time) = @_[KERNEL,HEAP,ARG0,ARG1];
    my @nicks = map { $heap->{irc}->nick_info( $_ ) } 
                      $heap->{irc}->channel_list( $channel );
    use Data::Dumper;
    $Data::Dumper::Indent=1;
    print Dumper( \@nicks );
    return;
  }
  # We registered for all events, this will produce some debug info.
  sub _default {
    my ($event, $args) = @_[ARG0 .. $#_];
    return 0;
    my @output = ( "$event: " );

    foreach my $arg ( @$args ) {
        if ( ref($arg) eq 'ARRAY' ) {
                push( @output, "[" . join(" ,", @$arg ) . "]" );
        } else {
                push ( @output, "'$arg'" );
        }
    }
    print STDOUT join ' ', @output, "\n";
    return 0;
  }
