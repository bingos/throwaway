use Test::More tests => 2;

package mxpoe;

use MooseX::POE;
use MooseX::AttributeHelpers;
use Test::More;

sub START {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  diag "Starting .... \n";
  $kernel->yield( 'counter_event' );
  return;
}

event 'counter_event' => sub {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  pass('Got a counter event');
  return;
};

no MooseX::POE;

__PACKAGE__->meta->make_immutable;

package mxpoet;

use MooseX::POE;
use Test::More;

extends 'mxpoe';

sub START {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  diag "Starting EXTENSION .... \n";
  $kernel->yield( 'counter_event' );
  $kernel->yield( 'rounter_event' );
  return;
}

event 'counter_event' => sub {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  pass('Got a counter event');
  return;
};

event 'rounter_event' => sub {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  pass('Got a counter event');
  return;
};

no MooseX::POE;

__PACKAGE__->meta->make_immutable;

package main;
use strict;
use warnings;
use Test::More;
use POE;
use POE::API::Peek;
use Data::Dumper;

my $mxpoe = mxpoet->new();
my $events = POE::API::Peek->new()->event_list();
diag(Dumper($events));
$poe_kernel->run();
exit 0;
