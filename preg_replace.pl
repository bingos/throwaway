use strict;
use warnings;

sub preg_replace (\[$@]\[$@]@) {
  my ($pat,$rep,$str) = @_;
   use Data::Dumper;
   $Data::Dumper::Indent=1;
   warn Dumper( \@_ );
}

{
 my $foo = 'bleh';
 my $bar = 'blah';
 my $str = 'This is bleh';
 preg_replace( $foo, $bar, $str );
}

{
  my @foo = ('This','bleh');
  my @bar = ('That','blah');
  my $str = 'This is bleh';
  preg_replace( @foo, @bar, $str );
}
