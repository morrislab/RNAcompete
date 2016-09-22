#!/usr/bin/perl

my $delim = "\t";
my $col   = 1;
my $fin   = \*STDIN;
my $missing_value = '-1.79769e+308';
while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-k')
  {
    $col = shift @ARGV;
  }
  elsif(($arg eq '-') or (-f $arg))
  {
    open($fin,$arg) or die("Could not open '$arg' for reading.");
  }
  else
  {
    die("Invalid argument '$arg'.");
  }
}
$col--;

my $sum_x  = 0.0;
my $sum_xx = 0.0;
my $num_x  = 0.0;
while(<$fin>)
{
  chop;
  my @tuple = split($delim,$_,$col+1);
  my $x     = $tuple[$col];

  if(($x =~ /\S/) and not($x =~ /NaN/i) and not($x eq $missing_value))
  {
    $sum_x   += $x;
    $sum_xx  += $x*$x;
    $num_x   += 1.0;
  }
}

my $mean_x = 'NaN';
my $std_x  = 'NaN';
if($num_x > 0.0)
{
  $mean_x   = $sum_x / $num_x;
  my $e_xx  = $sum_xx / $num_x;
  my $var_x = $e_xx - $mean_x*$mean_x;

  if($var_x >= 0.0)
    { $std_x = sqrt($var_x); }
}

print "$num_x\t$sum_x\t$mean_x\t$std_x\n";

exit(0);

__DATA__
syntax: stats.pl [OPTIONS] FILE

-k COL: Specify the column to compute the stats over.


