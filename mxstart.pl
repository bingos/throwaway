use Test::More tests => 2;

package notmxpoe;

use strict;
use warnings;
use Test::More;
use POE;

sub new {
  my $package = shift;
  my $self = bless { @_ }, $package;
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => [qw(_start _parent counter_event)],
	],
  )->ID();
  return $self;
}

sub _start {
  my ($kernel,$self,$sender,$session) = @_[KERNEL,OBJECT,SENDER,SESSION];
  my $moo = $kernel->ID();
  my $cow = $sender->ID();
  my $pig = $session->ID();
  warn "notmxpoe\nKernel: $moo\nSender: $cow\nSession: $pig\n";
  $kernel->yield('counter_event');
  return;
}

sub _parent {
  warn "Got a notMX PARENT event\n";
  return;
}

sub counter_event {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  pass('Got a counter event');
  return;
}

package mxpoe;

use MooseX::POE;
use MooseX::AttributeHelpers;
use Test::More;

sub START {
  my ($kernel,$self,$sender,$session) = @_[KERNEL,OBJECT,SENDER,SESSION];
  my $moo = $kernel->ID();
  my $cow = $sender->ID();
  my $pig = $session->ID();
  warn "mxpoe\nKernel: $moo\nSender: $cow\nSession: $pig\n";
  $kernel->yield('counter_event');
  return;
}

event 'counter_event' => sub {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  pass('Got a counter event');
  return;
};

event 'PARENT' => sub {
  warn "Got a MX PARENT event\n";
  return;
};

no MooseX::POE;

__PACKAGE__->meta->make_immutable;

package main;
use strict;
use warnings;
use Test::More;
use POE;

POE::Session->create(
  inline_states => {
     _start => sub {
	mxpoe->new();
	notmxpoe->new();
	return;
     },
  },
);
$poe_kernel->run();
exit 0;
