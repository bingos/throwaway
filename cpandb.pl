use strict;
use warnings;
use DBI;
use CPAN::DistnameInfo;
use IO::Zlib;
use File::Fetch;
use LWP::Simple;
use File::Spec;

my $verbose = shift;

$|=1;

my $tables = {
   mods => [
      'mod_name VARCHAR(300) NOT NULL',
      'dist_name VARCHAR(190) NOT NULL',
      'dist_vers VARCHAR(20)',
      'cpan_id VARCHAR(20) NOT NULL',
      'mod_vers VARCHAR(30)',
    ],
   dists => [
      'dist_name VARCHAR(190) NOT NULL',
      'cpan_id VARCHAR(20) NOT NULL',
      'dist_file VARCHAR(400) NOT NULL',
      'dist_vers VARCHAR(20)',
    ],
   auths => [
      'cpan_id VARCHAR(20) NOT NULL',
      'fullname VARCHAR(60) NOT NULL',
      'email TEXT',
    ],
};

my $mirror = 'ftp://localhost/CPAN/';
my $packages_file = '02packages.details.txt.gz';
my $mailrc_file = '01mailrc.txt.gz';

fetch_indexes('.',$mirror,$mailrc_file,$packages_file);
my $dbh = DBI->connect("dbi:SQLite:dbname=meep.db","","");
create_tables($dbh);
print "Populating auths ... ";
populate_auths($dbh,$mailrc_file);
print "DONE\nPopulating dists and mods ... ";
populate_dists($dbh,$packages_file);
print "DONE\n";
exit 0;

sub create_tables {
  my $handle = shift;
  foreach my $table ( keys %$tables ) {
     my $sql = 'CREATE TABLE IF NOT EXISTS ' . $table . ' ( ';
     $sql .= join ', ', @{ $tables->{$table} };
     $sql .= ' )';
     $handle->do($sql) or die $handle->errstr;
     $handle->do('DELETE FROM ' . $table) or die $handle->errstr;
  }
  return 1;
}

sub populate_dists {
  my ($handle,$pfile) = @_;
  my $fh = IO::Zlib->new( $pfile, "rb" ) or die "$!\n";
  my %dists;

  while (<$fh>) {
    last if /^\s*$/;
  }
  while (<$fh>) {
    chomp;
    my ($module,$version,$package_path) = split ' ', $_;
    my $d = CPAN::DistnameInfo->new( $package_path );
    next unless $d;
    my $metaname = $d->pathname;
    my $extension = $d->extension;
    next unless $extension;
    unless ( exists $dists{$package_path} ) {
      print ".INSERT '", $d->dist, "'\n" if $verbose;
      my $sth = $handle->prepare(qq{INSERT INTO dists values (?,?,?,?)}) or die $handle->errstr;
      $sth->execute(
	$d->dist,
	$d->cpanid,
	$d->pathname,
	$d->version,
      ) or die $handle->errstr;
      $dists{$package_path}++;
    }
    # Insert into table dists and mods
    print ".INSERT '$module'\n" if $verbose;
    my $sth = $handle->prepare(qq{INSERT INTO mods values (?,?,?,?,?)}) or die $handle->errstr;
    $sth->execute(
	$module,
	$d->dist,
	$d->version,
	$d->cpanid,
	$version,
    ) or die $handle->errstr;
  }
  return 1;
}

sub populate_auths {
  my ($handle,$mfile) = @_;
  my $fh = IO::Zlib->new( $mfile, "rb" ) or die "$!\n";
  while (<$fh>) {
    chomp;
    my ( $alias, $pauseid, $long ) = split ' ', $_, 3;
    $long =~ s/^"//;
    $long =~ s/"$//;
    my ($name, $email) = $long =~ /(.*) <(.+)>$/;
    print ".INSERT '$pauseid'\n" if $verbose;
    my $sth = $handle->prepare(qq{INSERT INTO auths values (?,?,?)}) or die $handle->errstr;
    $sth->execute( $pauseid, $name, $email ) or die $handle->errstr;
  }
  return 1;
}

sub fetch_indexes {
my ($location,$mirror,$mailrc,$packages) = @_;
$mailrc = join '/', 'authors', $mailrc;
$packages = join '/', 'modules', $packages;

foreach my $file ( $mailrc, $packages ) {
  my $url = join '', $mirror, $file;

  my $ff = File::Fetch->new( uri => $url );
  my $stat = $ff->fetch( to => $location );
  next unless $stat;
  print "Downloaded '$url' to '$stat'\n";
}
}
