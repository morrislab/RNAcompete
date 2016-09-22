#!/usr/bin/perl

# Smith-Waterman algorithm to align PWMs
# usage statement
die "usage: $0 <sequence 1> <sequence 2>\n" unless @ARGV == 2;
# get sequences from command line
my ($pwmfile1, $pwmfile2) = @ARGV;

# scoring scheme
my $MATCH     =  1; # +1 for letters that match
my $MISMATCH = -1; # -1 for letters that mismatch
my $GAP       = 9999; # -1 for any gap

my $pwm1 = _read_pwm($pwmfile1);
my $pwm2 = _read_pwm($pwmfile2);

my $len1 = scalar @{$pwm1};
my $len2 = scalar @{$pwm2};

# initialization
my @matrix;
$matrix[0][0]{score}   = 0;
$matrix[0][0]{pointer} = "none";
for(my $j = 1; $j <= $len1; $j++) {
     $matrix[0][$j]{score}   = 0;
     $matrix[0][$j]{pointer} = "none";
}
for (my $i = 1; $i <= $len2; $i++) {
     $matrix[$i][0]{score}   = 0;
     $matrix[$i][0]{pointer} = "none";
}

# fill
 my $max_i     = 0;
 my $max_j     = 0;
 my $max_score = 9999999;

 for(my $i = 1; $i <= $len2; $i++) {
     for(my $j = 1; $j <= $len1; $j++) {
         my ($diagonal_score, $left_score, $up_score);
         
         
         print "i=$i, j=$j\n";
         
         # calculate match score
         my $column1 = $pwm1->[$j-1];
         my $column2 = $pwm2->[$i-1]; 
         
         $diagonal_score = $matrix[$i-1][$j-1]{score} + _ed_column($column1,$column2);     
         
         # calculate gap scores
         $up_score   = $matrix[$i-1][$j]{score} + $GAP;
         $left_score = $matrix[$i][$j-1]{score} + $GAP;
         
         print "i=$i, j=$j, d=$diagonal_score, u=$up_score, l=$left_score\n";
         
         if ($diagonal_score <= 0 and $up_score <= 0 and $left_score <= 0) {
             $matrix[$i][$j]{score}   = 0;
             $matrix[$i][$j]{pointer} = "none";
             next; # terminate this iteration of the loop
          }
         
         # choose best score
         if ($diagonal_score <= $up_score) {
             if ($diagonal_score <= $left_score) {
                 $matrix[$i][$j]{score}   = $diagonal_score;
                 $matrix[$i][$j]{pointer} = "diagonal";
              }
             else {
                 $matrix[$i][$j]{score}   = $left_score;
                 $matrix[$i][$j]{pointer} = "left";
              }
          } else {
             if ($up_score <= $left_score) {
                 $matrix[$i][$j]{score}   = $up_score;
                 $matrix[$i][$j]{pointer} = "up";
              }
             else {
                 $matrix[$i][$j]{score}   = $left_score;
                 $matrix[$i][$j]{pointer} = "left";
              }
          }
         
       # set maximum score
         if ($matrix[$i][$j]{score} < $max_score) {
             $max_i     = $i;
             $max_j     = $j;
             $max_score = $matrix[$i][$j]{score};
          }
      }
 }

 # trace-back

 my @align1 = ();
 my @align2 = ();

 my $j = $max_j;
 my $i = $max_i;

print "trace-back\n";

 while (1) {
 	print "i=$i, j=$j\n";
     last if $matrix[$i][$j]{pointer} eq "none";
     
     if ($matrix[$i][$j]{pointer} eq "diagonal") {
         push(@align1,$pwm1->[$j-1]);
         push(@align2,$pwm2->[$i-1]);
         $i--; $j--;
      }
     elsif ($matrix[$i][$j]{pointer} eq "left") {
         push(@align1,$pwm1->[$j-1]);
		  push(@align2,{'A'=>'-','C'=>'-','G'=>'-','U'=>'-'});
         $j--;
      }
     elsif ($matrix[$i][$j]{pointer} eq "up") {
		  push(@align1,{'A'=>'-','C'=>'-','G'=>'-','U'=>'-'});
         push(@align2,$pwm2->[$i-1]);
         $i--;
      }  
 }

print "aligned pwm 1:\n\n";
 _print_pwm(\@align1);
 #_print_pwm($pwm1);
 print "\naligned pwm 2:\n\n";
 _print_pwm(\@align2);
 
 sub _read_pwm{
	my $file = shift;
	my @pwm;
	open(my $in, $file) or die "couldn't open $file";
	<$in>; #header
	while(<$in>){
		chomp; chop while /\r/;
		my ($pos,$a,$c,$g,$u) = split("\t");
		my $hr = { 	'A' => $a,
					'C' => $c,
					'G' => $g,
					'U' => $u };
		push(@pwm,$hr);
	}
	close($in);
	return \@pwm;
}

sub _ed_column{
	my ($column1,$column2) = @_;
	my $ed = 0;
	
	foreach my $b ('A','C','G','U'){
		$val += $column1->{$b} - $column2->{$b};
		$ed += sqrt($val*$val);
	}
		
	return $ed;
}

sub _print_pwm{
	my $pwm = shift;
	my $len = scalar @{$pwm};
	print "Pos\tA\tC\tG\tU\n";
	foreach my $i (0..($len-1)){
		print $i;
		foreach my $b ('A','C','G','U'){
			print "\t".$pwm->[$i]->{$b};
		}
		print "\n";
	}
}
