use 5.11.1;
use strict;
use warnings;
use Config;
use Module::CoreList;
use Module::Load::Conditional qw[check_install];
use CPANPLUS::Backend;
use CPANPLUS::Error;
use CPANPLUS::Internals::Constants;

my $mod = shift || die "usage: cpdeprecated.pl <module>\n";
my $version = shift || '0';

my $cb = CPANPLUS::Backend->new();
my $modobj  = $cb->module_tree($mod);

unless( $modobj ) {
   # Check if it is a core module
   my $sub = CPANPLUS::Module->can(
          'module_is_supplied_with_perl_core' );
   my $core = $sub->( $mod );
   unless ( $core ) {
      error( loc( "No such module '%1' found on CPAN", $mod ) );
      exit;
   }
   if ( $cb->_vcmp( $version, $core ) > 0 ) {
      error(loc( "Version of core module '%1' ('%2') is too low for ".
                 "'%3' (needs '%4') -- carrying on but this may be a problem",
                 $mod, $core,
                 'Foo', $version ));
   }
   exit;
}

print "Moo\n" if $modobj->is_uptodate( version => $version );
