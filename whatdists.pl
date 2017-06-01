use strict;
use warnings;
use File::Spec;
use File::Spec::Unix;
use File::Fetch;
use File::Find;
use File::Slurper qw[read_binary];
use IO::Zlib;
use CPAN::DistnameInfo;
use Sort::Versions;
use version;
use Module::Load::Conditional qw[check_install];

use constant ON_WIN32       => $^O eq 'MSWin32';
use constant ON_VMS         => $^O eq 'VMS';

my $mirror = 'http://www.cpan.org/';

my $opt_verbose = 1;
my @search_dirs = (@ARGV) ? @ARGV : @INC;
warn "Searching @search_dirs\n" if $opt_verbose;

my %seen_dist;

{

  my %installed;
  my %cpan;
  foreach my $module ( _all_installed(@search_dirs) ) {
    my $href = check_install( module => $module );
    next unless $href;
    $installed{ $module } = defined $href->{version} ? $href->{version} : 'undef';
  }

  my $loc = fetch_indexes('.',$mirror) or die;
  populate_cpan( $loc, \%cpan );
  foreach my $module ( sort keys %installed ) {
    # Eliminate core modules
    if ( supplied_with_core( $module ) and !$cpan{ $module } ) {
      delete $installed{ $module };
      next;
    }
  }

  # Further eliminate choices.

  foreach my $mod ( sort keys %installed ) {

    unless ($cpan{ $mod }) {
        warn "$mod not found in CPAN index (local version $installed{$mod})\n"
            if $opt_verbose;
        next;
    }

    my $cd = CPAN::DistnameInfo->new( $cpan{ $mod } );
    if ( exists $seen_dist{ $cd->dist } ) {
      my $ed = CPAN::DistnameInfo->new(  $seen_dist{ $cd->dist } );
      if ( versioncmp( $cd->version, $ed->version ) == 1 ) {
        $seen_dist{ $cd->dist } = $cpan{ $mod };
      }
    }
    else {
      $seen_dist{ $cd->dist } = $cpan{ $mod };
    }
  }

}

print $_, "\n" for sort values %seen_dist;
exit 0;

sub supplied_with_core {
  my $name = shift;
  my $ver = shift || $];
  require Module::CoreList;
  return $Module::CoreList::version{ 0+$ver }->{ $name };
}

sub _vcmp {
  my ($x, $y) = @_;
  s/_//g foreach $x, $y;
  return version->parse($x) <=> version->parse($y);
}

sub populate_cpan {
  my $pfile = shift;
  my $cpan  = shift;
  my $fh = IO::Zlib->new( $pfile, "rb" ) or die "$!\n";
  my %dists;

  while (<$fh>) {
    last if /^\s*$/;
  }
  while (<$fh>) {
    chomp;
    my ($module,$version,$package_path) = split ' ', $_;
    $cpan->{ $module } = $package_path;
  }
  return 1;
}

sub fetch_indexes {
  my ($location,$mirror) = @_;
  my $packages = 'modules/02packages.details.txt.gz';
  my $url = join '', $mirror, $packages;
  my $ff = File::Fetch->new( uri => $url );
  my $stat = $ff->fetch( to => $location );
  return unless $stat;
  warn "Downloaded '$url' to '$stat'\n";
  return $stat;
}

sub _all_installed {
    my (@dirs) = @_;

    ### File::Find uses follow_skip => 1 by default, which doesn't die
    ### on duplicates, unless they are directories or symlinks.
    ### Ticket #29796 shows this code dying on Alien::WxWidgets,
    ### which uses symlinks.
    ### File::Find doc says to use follow_skip => 2 to ignore duplicates
    ### so this will stop it from dying.
    my %find_args = ( follow_skip => 2 );

    ### File::Find uses lstat, which quietly becomes stat on win32
    ### it then uses -l _ which is not allowed by the statbuffer because
    ### you did a stat, not an lstat (duh!). so don't tell win32 to
    ### follow symlinks, as that will break badly
    # XXX disabled because we want the postprocess hook to work
    #$find_args{'follow_fast'} = 1 unless ON_WIN32;

    ### never use the @INC hooks to find installed versions of
    ### modules -- they're just there in case they're not on the
    ### perl install, but the user shouldn't trust them for *other*
    ### modules!
    ### XXX CPANPLUS::inc is now obsolete, remove the calls
    #local @INC = CPANPLUS::inc->original_inc;

    # sort @dirs to put longest first to make it easy to handle
    # elements that are within other elements (e.g., an archdir)
    my @dirs_ordered = sort { length $b <=> length $a } @dirs;

    my %seen_mod; my @rv; my %dir_done;
    for my $dir (@dirs_ordered) {
        next if $dir eq '.';

        ### not a directory after all 
        ### may be coderef or some such
        next unless -d $dir;

        ### make sure to clean up the directories just in case,
        ### as we're making assumptions about the length
        ### This solves rt.cpan issue #19738
        
        ### John M. notes: On VMS cannonpath can not currently handle 
        ### the $dir values that are in UNIX format.
        $dir = File::Spec->canonpath( $dir ) unless ON_VMS;
        
        ### have to use F::S::Unix on VMS, or things will break
        my $file_spec = ON_VMS ? 'File::Spec::Unix' : 'File::Spec';

        ### XXX in some cases File::Find can actually die!
        ### so be safe and wrap it in an eval.
        eval { File::Find::find(
            {   %find_args,
                postprocess => sub {
                    $dir_done{ $File::Find::dir }++;
                },
                wanted      => sub {

                    unless (/\.pm$/i) {
                        # skip all dot-dirs (eg .git .svn)
                        $File::Find::prune = 1 if -d $File::Find::name and /^\.\w/;
                        # don't reenter a dir we've already done
                        $File::Find::prune = 1 if $dir_done{ $File::Find::name };
                        return;
                    }
                    my $mod = $File::Find::name;

                    ### make sure it's in Unix format, as it
                    ### may be in VMS format on VMS;
                    $mod = VMS::Filespec::unixify( $mod ) if ON_VMS;                    
                    
                    $mod = substr($mod, length($dir) + 1, -3);
                    $mod = join '::', $file_spec->splitdir($mod);

                    return if $seen_mod{$mod}++;

                    ### ignore files that don't contain a matching package declaration
                    ### warn about those that do contain some kind of package declaration
                    my $content = read_binary($File::Find::name);
                    unless ($content =~ m/^ \s* package \s+ (\#.*\n\s*)? $mod \b/xm) {
                        warn "No 'package $mod' seen in $File::Find::name\n"
                            if $opt_verbose && $content =~ /\b package \b/x;
                        return;
                    }

                    push @rv, $mod;
                },
            }, $dir
        ); 1 }
            or die "File::Find died: $@";

    }

    return @rv;
}
