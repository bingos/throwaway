package mxpoe;

use strict;
use warnings;

our $VERSION = '0.2';

use MooseX::POE;
use MooseX::AttributeHelpers;

has 'counter' => (
  metaclass => 'Counter',
  is        => 'ro',
  isa       => 'Num',
  default   => sub { 0 },
  provides  => {
    inc => 'inc_counter',
    dec => 'dec_counter',
    reset => 'reset_counter',
  },
);

sub START {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  warn "Starting .... \n";
  $kernel->yield( 'counter_event' );
  return;
}

event 'counter_event' => sub {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  warn "Counter is: ", $self->counter, "\n";
  warn "Incrementing counter\n";
  $self->inc_counter;
  $kernel->delay( 'counter_event', $self->counter );
  return;
};

no MooseX::POE;

#__PACKAGE__->meta->make_immutable();

1;
__END__
