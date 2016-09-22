#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $source_file = $ARGV[0];
my $order_file = $ARGV[1];

my %args = load_args(\@ARGV);

my $rows = get_arg("rows", 0, \%args);
my $source_key = get_arg("sk", 0, \%args);
my $order_key = get_arg("ok", 0, \%args);
my $keep_all_rows = get_arg("keepall", 0, \%args);
my $skip_num = get_arg("skip", 0, \%args);

my $outfile = "tmp." . int(rand(1000000));

if ($rows == 0)
{
  my $r1 = int(rand(1000000));
  my $r2 = int(rand(1000000));

  system("transpose.pl < $source_file > tmp.$r1");
  system("transpose.pl < $order_file > tmp.$r2");

  &order_rows("tmp.$r1", "tmp.$r2", $outfile);

  system("rm tmp.$r1");
  system("rm tmp.$r2");

  system("transpose.pl < $outfile");
}
else
{
  &order_rows($source_file, $order_file, $outfile);
  system("cat $outfile");
}

system("rm $outfile");

sub order_rows
{
  my ($source_file, $order_file, $outfile) = @_;

  open(OUTFILE, ">$outfile");

  my %ordered_file;
  open(ORDER_FILE, "<$order_file");
  for (my $i = 0; $i < $skip_num; $i++) { my $line = <ORDER_FILE>; print OUTFILE $line; }
  while(<ORDER_FILE>)
  {
    chop;

    my @row = split(/\t/);

    $ordered_file{$row[$order_key]} = $_;
  }

  my %source_keys;
  open(SOURCE_FILE, "<$source_file");
  while(<SOURCE_FILE>)
  {
    chop;

    my @row = split(/\t/);

    my $ordered_row = $ordered_file{$row[$source_key]};
    $source_keys{$row[$source_key]} = "1";

    if (length($ordered_row) > 0) { print OUTFILE "$ordered_row\n"; }
  }

  if ($keep_all_rows == 1)
  {
    open(ORDER_FILE, "<$order_file");
    for (my $i = 0; $i < $skip_num; $i++) { my $line = <ORDER_FILE>; }
    while(<ORDER_FILE>)
    {
      chop;

      my @row = split(/\t/);

      if ($source_keys{$row[$order_key]} ne "1") { print OUTFILE "$_\n"; }
    }
  }
}

__DATA__

order_file.pl <source file> <order file>

   Order <order file> according to the order of the source file,
   where the key by which the ordering is done may be specified
   as well as whether the ordering should be done by rows or by columns.
   Rows in the order file that are not found can be included in the end
   of the file or they can simply be ignored.

   -rows:         Order by rows (default is by columns)
   -sk:           Source row/column key (default is 0)
   -ok:           Source row/column key (default is 0)
   -keepall       Keep rows in <order file> not found in source at the end
   -skip <num>:   Skip num columns/rows in the order file and just print them (default: 0)

