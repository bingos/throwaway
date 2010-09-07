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

exit 0;

__END__

[10:57] < BinGOs> Hmmm I wonder where that preg_replace() in perl I started is.
[10:58] < buu> Good lord why
[10:58] < BinGOs> It seemed like a laff
[10:59] < Altreus> BinGOs: phpreg_replace :P
[10:59] < BinGOs> Actually I quite liked that you could provide arrays of stuff.
[11:00] < BinGOs> Aha found it.
[11:01] < Altreus> BinGOs: so s/shift/shift/ while scalar (@stuff)
[11:02] < Altreus> where @stuff = List::MoreUtils::zip(@regexes, @replacements)
[11:02] < buu> If that worked, yes.
[11:02] < BinGOs> >:)
[11:03] < Altreus> buu: no u work
[11:03] < BinGOs> http://php.net/manual/en/function.preg-replace.php
[11:04] < Altreus> s/shift/@{[shift]}/ while scalar (@stuff)
[11:04] < Altreus> :3
[11:05] < Altreus> eval: @stuff = (qr/1/, 'a', qr/2/, 'b'); $_ = "12345678"; s/shift/@{[shift]}/ while scalar (@stuff); $_
[11:05] < Altreus> :(
[11:05] < buubot> Altreus: No output.
[11:05] < Altreus> stupid @stuff
[11:05] < Altreus> change ok
[11:05] < rindolf> Altreus: the left-hand-shift is wrong.
[11:05] < Altreus> how so
[11:05] < rindolf> Altreus: it will be interpreted as the string "shift".
[11:06] < Altreus> really?
[11:06] < Altreus> hmm
[11:06] < rindolf> Altreus: yes.
[11:06] < Altreus> still, the while does not re-eval scalar @stuff
[11:06] < Altreus> superfluous scalar of course
