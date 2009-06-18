package mxpoet;

use strict;
use warnings;

our $VERSION = '0.2';

use MooseX::POE;

extends 'mxpoe';

sub START {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  warn "Starting EXTENSION .... \n";
  $kernel->yield( 'counter_event' );
  return;
}

event 'counter' => sub {
  my $self = shift;
  $self->SUPER::counter(@_);
};

no MooseX::POE;

__PACKAGE__->meta->make_immutable();

1;
__END__
