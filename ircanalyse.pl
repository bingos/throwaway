use strict;
use warnings;

my $file = shift || die "Must specify a filename\n";

my $content = do { open my $fh, '<', $file or die; local $/; <$fh>; };

my $data;

{ 
  no strict;
  $data = eval $content;
}
