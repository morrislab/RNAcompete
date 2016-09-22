#!/usr/bin/perl

# 2012-08-08 by Kate Cook
# Added trimmed mean function

use Math::Trig;

use List::Util qw(max min);

use POSIX;

use strict;
#use warnings;
#use diagnostics;

my $MAXDOUBLE = 100000000000000000000000000;
my $LOG10     = log(10);

# this is taken from the perl test t/op/arith.t
sub __OVERFLOW_TO_INF {
    my $n = 5000;
    my $v = 2;
    while (--$n)
    {
        $v *= 2;
    }
    return($v)
	}
my $INFINITY = &__OVERFLOW_TO_INF();




#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
sub ComputeBinomial
{
	my ($p, $n, $r) = @_;

	my $binom = -$MAXDOUBLE;
	for (my $i = $r; $i <= $n; $i++)
	{
		$binom = AddLog($binom, lchoose($i, $n) + $i * log($p) + ($n - $i) * log(1-$p));
		#$binom = AddLog($binom, lchoose($r, $n) + $r * log($p) + ($n - $r) * log(1-$p));
	}

	return exp($binom);
}

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
sub ComputeLog10HyperDensity
{
    my ($k, $n, $K, $N) = @_;
    
    if ($N == 0 or $n == 0 or ($k > $n) or ($K > $N))
    {
        return undef;
    }
    
    my $pvalue = &lchoose($k, $K) + &lchoose($n - $k, $N - $K) - &lchoose($n, $N);
    
    return $pvalue / $LOG10;
}

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
sub ComputeLog10HyperDistOverDensity {
    # Reimplementation from R v2.1.1
    # Calculate
    #
    #            phyper (x, NR, NB, n, TRUE, FALSE)
    #   [log]  ----------------------------------
    #            dhyper (x, NR, NB, n, FALSE)
    #
    # without actually calling phyper.  This assumes that
    #
    #     x * (NR + NB) <= n * NR
    my ($k, $n, $K, $N) = @_;
    
    if ($k == 13066 && $n == 13077 && $K == 13857 && $N == 13867) {
        warn "this is that weird case that messes up the pdhyper";
    }
    
    # this is for double values... 2^-52
    my $DBL_EPSILON = 2.220446049250313e-16;
    
    my $x = $k;
    my $NR = $K;
    my $NB = $N - $NR;
    
    my $sum = 0;
    my $term = 1;
    while($x > 0 && $term >= $DBL_EPSILON * $sum) {
        $term *= $x * ($NB - $n + $x) / ($n + 1 - $x) / ($NR + 1 - $x);
        $sum += $term;
        $x = $x - 1;
    }

    $sum = $sum < 0 ? 0 : $sum;

    return log(1 + $sum) / $LOG10;
}

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
sub ComputeLog10HyperPValue
{
    my ($k, $n, $K, $N) = @_;
    my $swapped = 0;
    
    if ($k <= 0) { return 0; }
    if ($k > $n) { return -$INFINITY; }
    if ($n-$k > $N-$K)
    {
		print STDERR "more failures than black balls in urn:k=$k n=$n K=$K N=$N";
		return 0;
    }
    if ($k > $K)
    {
		print STDERR "more successes than white balls in urn:k=$k n=$n K=$K N=$N";
		return 0;
    }
    if ($K > $N)
    {
		print STDERR "more trials than balls in urn:k=$k n=$n K=$K N=$N";
		return 0;
    }

    # swap tails, if necessary to calculate the phyper(...) / dhyper(...)
    if (($k * $N) > ($n * $K))
    {
		$K = $N - $K;
		$k = $n - $k;
		$swapped = 1;
    }

    if ($k < 0) { return 0; }

    my $pd = &ComputeLog10HyperDistOverDensity($k, $n, $K, $N);
    my $d  = &ComputeLog10HyperDensity($k, $n, $K, $N);

    my $lpvalue = ($k == 0) ? $d : $pd + $d;
    # my $lpvalue = ($k == 0) ? $d : log(10^$pd + 10^$d);

    if ($lpvalue >= 0)
    {
		# warn "pvlaue >= 1: k=$k n=$n K=$K N=$N";
		return 0;
    }
    unless ($swapped)
    {
		$lpvalue = log(1-exp($lpvalue*$LOG10))/$LOG10;
    }
    return $lpvalue;
}

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
sub ComputeHyperPValue
{
	my ($k, $n, $K, $N) = @_;

	my $p = $K / $N;

	my $d = ($k <  $p * $n) ? -1 : +1;

	my $PVal = -$MAXDOUBLE;

	for (; $k >= 0 and $k <= $n; $k += $d)
	{
		my $x = &lchoose($k, $K) + &lchoose($n - $k, $N - $K) - &lchoose($n, $N);

		$PVal = &AddLog($PVal, $x);
	}

	return exp($PVal);
}

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
sub ComputeHyperPValueUpper # one-sided
{
	my ($k, $n, $K, $N) = @_;

	my $p = $K / $N;

	my $PVal = -$MAXDOUBLE;

	for (; $k >= 0 and $k <= $n; $k++)
	{
		my $x = &lchoose($k, $K) + &lchoose($n - $k, $N - $K) - &lchoose($n, $N);

		$PVal = &AddLog($PVal, $x);
	}

	return exp($PVal);
}

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
sub lchoose
{
	my ($k, $N) = @_;

	return $k > $N ? 0 : &lgamma($N + 1) - &lgamma($k + 1) - &lgamma($N - $k + 1);
}

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
sub AddLog
{
	my ($x, $y) = @_;

	if ($x == -$MAXDOUBLE) { return $y };
	if ($y == -$MAXDOUBLE) { return $x };
	if ($x >= $y)
	{
		$y -= $x;
	}
	else
	{
		my $t = $x;
		$x = $y;
		$y = $t - $x;
	}

	return $x + log(1 + exp($y));
}

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
sub lgamma
{
	# per code from numerical recipies
	my $xx = $_[0];

	my ($j, $ser, $stp, $tmp, $x, $y);
	my @cof = (0.0, 76.18009172947146, -86.50532032941677, 24.01409824083091, -1.231739572450155, 0.1208650973866179e-2, -0.5395239384953e-5);
	$stp = 2.5066282746310005;

	$x = $xx;
	$y = $x;
	$tmp = $x + 5.5;
	$tmp = ($x+0.5)*log($tmp)-$tmp;
	$ser = 1.000000000190015;
	foreach $j ( 1 .. 6 )
	{
		$y+=1.0;
		$ser+=$cof[$j]/$y;
	}
	return $tmp + log($stp*$ser/$x);
}

#-----------------------------------------------------------------------------
# $double ComputeSymmetricUniformCdf(\@list reals, $int already_sorted=0)
#-----------------------------------------------------------------------------
sub ComputeSymmetricUniformCdf
{
	my ($reals, $already_sorted) = @_;
	$already_sorted = defined($already_sorted) ? $already_sorted : 0;

	my $list;
	if(not($already_sorted))
	{
		my @list = sort {$b <=> $a} @{$reals};
		push(@list, 0.0);
		$list = \@list;
	}
	else
	{
		$list = $reals;
	}

	if(scalar(@{$list}) == 1)
	{
		return 1.0;
	}
	else
	{
		my $cummulative_probability = 0.0;

		for(my $i = 0; $i < scalar(@{$list}) - 1; $i++)
		{
			my $range = $$list[$i] - $$list[$i + 1];

			my @list = @{$list};

			splice(@list, $i, 1);

			$cummulative_probability += $range * &ComputeSymmetricUniformCdf(\@list, 1);
		}

		return $cummulative_probability;
	}
}

my $epsilon = 0.000001;

sub Pearson2FisherZ
{
	my ($r) = @_;

	$r = $r > (1-$epsilon)  ?  1-$epsilon : $r;
	$r = $r < (-1+$epsilon) ? -1+$epsilon : $r;

	my $z = defined($r) ? 0.5 * (log(1 + $r) - log(1 - $r)) : undef;

	return $z;
}

sub Pearson2FisherZscore
{
	my ($r, $dimensions) = @_;

	my $z      = &Pearson2FisherZ($r);
	my $zscore = (defined($z) and $dimensions > 3) ? $z * sqrt($dimensions - 3) : undef;

	return $zscore;
}


my $TWICE_A = 1.7155277699214135;

sub sample_normal
{
    while (1)
    {
		my $u = rand();
		if ($u != 0.0)
		{
			my $v = (rand() - 0.5) * $TWICE_A;
			my $x = $v / $u;
			my $sqr_x = $x*$x;
			if ($sqr_x <= 6 - 8*$u + 2*$u*$u)
			{
				return $x;
			}
			if (!($sqr_x >= 2 / $u - 2 * $u))
			{
				if ($sqr_x <= -4 * log($u))
				{
					return $x;
				}
			}
		}
    }
}

my $MUTUAL_INFORMATION = "mi";
my $DOT_PRODUCT = "dot";
my $CORRELATION_COEFFICIENT = "cor";

#--------------------------------------------------------------------------------
# DEBUG_VO
#--------------------------------------------------------------------------------
sub DEBUG_VO
{
#  print $_[0];
}

#---------------------------------------------------------
# vec_stats
#---------------------------------------------------------
sub vec_stats (\@)
{
    # $Nx: count of elements
    # $Sx: sum of elements
    # $Sxx: sum of all (element squared)
    my ($Nx, $Sx, $Sxx) = &vec_suff_stats(@_);
    
    my $mean = $Nx > 0 ? $Sx / $Nx : undef;
    
    # $var means "variance"
    my $var  = ($Nx > 0) ?
		$Sxx / $Nx - (($Sx / $Nx) * ($Sx / $Nx))
		: undef;
    
    if (defined($var) && ($var < 0)) {
		# We should check the variance and set it to
		# zero if it is defined and is negative.
		$var = 0;
    }
	
    my $stdev = defined($var) ? sqrt($var) : undef;
	
    # Returns the number of items in this array, the mean of items, and the standard deviation.
	# To use this function, you say something like:
	#   my @theArray = [1,4,4,5,2,8,5,0,-1];
	#   my ($n, $m, $s) = vec_stats(\@theArray);
    return ($Nx, $mean, $stdev);
}

sub mat_stats (\@)
{
	my ($X) = @_;
	my $num = scalar(@{$X});
	my $dim = scalar(@{$$X[0]});

	my (@Nums, @Means, @Stdevs);
	for(my $j = 0; $j < $dim; $j++) {
		my @x;
		for(my $i = 0; $i < $num; $i++) {
			if(defined($$X[$i][$j])) {
				push(@x, $$X[$i][$j]);
			}
		}
		my ($nx, $mean, $stdev) = &vec_stats(\@x);
		push(@Nums, $nx);
		push(@Means, $mean);
		push(@Stdevs, $stdev);
	}
	return (\@Nums, \@Means, \@Stdevs);
}

#---------------------------------------------------------
# vec_suff_stats
#---------------------------------------------------------
sub vec_suff_stats
{
	my ($vec_ref) = @_;

	my $sum = 0;

	my $sumsqr = 0;

	my $num = 0;

	foreach my $x (@{$vec_ref})
	{
		if(defined($x) and ($x =~ /\d/))
		{
			$sum    += $x;
			$sumsqr += $x * $x;
			$num    += 1.0;
		}
	}
	return ($num, $sum, $sumsqr);
}

#---------------------------------------------------------
# vec_count_full_entries
#---------------------------------------------------------
sub vec_count_full_entries
{
	my ($vec) = @_;

	my $entries = 0;
	my $len = scalar(@{$vec});
	for (my $i = 0; $i < $len; $i++)
	{
		if (defined($$vec[$i]) and length($$vec[$i]) > 0)
        { $entries++; }
	}

	return $entries;
}

#---------------------------------------------------------
# vec_sum
#---------------------------------------------------------
sub vec_sum
{
	my ($vec) = @_;

	my $sum = 0;
	my $num = 0;
	my $len = scalar(@{$vec});
	for (my $i = 0; $i < $len; $i++) {
		if (defined($$vec[$i]) and length($$vec[$i]) > 0) {
			$sum += $$vec[$i];
			$num += 1;
		}
	}
	return ($num, $sum);
}

sub mat_sum (\@)
{
	my ($X) = @_;
	my $num = scalar(@{$X});
	my $dim = scalar(@{$$X[0]});

	my (@Nums,@Sums);
	for(my $j = 0; $j < $dim; $j++) {
		my @x;
		for(my $i = 0; $i < $num; $i++) {
			if(defined($$X[$i][$j])) {
				push(@x, $$X[$i][$j]);
			}
		}
		my ($num, $sum) = &vec_sum(\@x);
		push(@Nums, $num);
		push(@Sums, $sum);
	}
	return (\@Nums, \@Sums);
}

#---------------------------------------------------------
# vec_min
#---------------------------------------------------------
sub vec_min (\@)
{
	my ($x) = @_;
	my $min = undef;
	my $arg = undef;
	if(defined($x)) {
		my $n   = scalar(@{$x});

		for(my $i = 0; $i < $n; $i++)
		{
			if(not(defined($min)) or
			   (defined($$x[$i]) and (length($$x[$i]) > 0) and
				($$x[$i] < $min)))
			{
				$min = $$x[$i];
				$arg = $i;
			}
		}
		$min = not(defined($min)) ? "" : $min;
		$arg = not(defined($arg)) ? "" : $arg;
	}
	return ($arg, $min);
}

sub mat_min (\@)
{
	my ($X) = @_;
	my $num = scalar(@{$X});
	my $dim = scalar(@{$$X[0]});

	my (@Args,@Mins);
	for(my $j = 0; $j < $dim; $j++) {
		my @x;
		for(my $i = 0; $i < $num; $i++) {
			if(defined($$X[$i][$j])) {
				push(@x, $$X[$i][$j]);
			}
		}
		my ($arg, $min) = &vec_min(\@x);
		push(@Args, $arg);
		push(@Mins, $min);
	}
	return (\@Args, \@Mins);
}

#---------------------------------------------------------
# vec_max
#---------------------------------------------------------
sub vec_max (\@)
{
	my ($x) = @_;
	my $max = undef;
	my $arg = undef;

	if(defined($x)) {
		my $n   = scalar(@{$x});
		for(my $i = 0; $i < $n; $i++)
		{
			if(not(defined($max)) or
			   (defined($$x[$i]) and (length($$x[$i]) > 0) and
				($$x[$i] > $max)))
			{
				$max = $$x[$i];
				$arg = $i;
			}
		}
		$max = not(defined($max)) ? "" : $max;
		$arg = not(defined($arg)) ? "" : $arg;
	}
	return ($arg, $max);
}

sub mat_max (\@)
{
	my ($X) = @_;
	my $num = scalar(@{$X});
	my $dim = scalar(@{$$X[0]});

	my (@Args,@Maxs);
	for(my $j = 0; $j < $dim; $j++) {
		my @x;
		for(my $i = 0; $i < $num; $i++) {
			if(defined($$X[$i][$j])) {
				push(@x, $$X[$i][$j]);
			}
		}
		my ($arg, $max) = &vec_max(\@x);
		push(@Args, $arg);
		push(@Maxs, $max);
	}
	return (\@Args, \@Maxs);
}

#---------------------------------------------------------
# vec_nth_stat
# Get the nth smallest value (i.e., 1 is the smallest,
# and Array_length is the largest)
#---------------------------------------------------------
sub vec_nth_stat (\@$)
{
    my ($unsorted_vec, $n) = @_;
    my @sorted_vec = sort { $a <=> $b } @{$unsorted_vec};
    return $sorted_vec[$n];
}

#---------------------------------------------------------
# vec_median
# Either returns the middle element, or in cases with even-numbered
# arrays, averages the two middle elements. Makes use of
# vec_nth_stat to sort the lists.
# Future optimization: sorts each even-numbered list TWICE to get
# the nth-item. We should probably only sort once for even-numbered
# lists
#---------------------------------------------------------
sub vec_median {
	my ($unsorted_vec) = @_;

	my $len = scalar(@{$unsorted_vec});
	my @sorted_vec = sort { $a <=> $b } @{$unsorted_vec};

	if ($len == 0) {
		print STDERR "WARNING/ERROR: vec_median in libstats.pl was passed a vector with zero length.\n";
	}

	if ( ($len % 2) == 0) { # even-length vector
		my $middleHigh = int($len / 2); # this is actually the "higher" of the two middle items, since arrays begin at 0 and not 1
		return ($sorted_vec[$middleHigh] + $sorted_vec[$middleHigh - 1])/2;
	} else { # odd-length vector
		my $middleIndex = int($len / 2);
		return $sorted_vec[$middleIndex];
	}
}

# Computes the nth quantile of the vector
sub vec_quantile {
	my ($unsorted_vec, $quantile) = @_;
	my $len = defined($unsorted_vec) ? scalar(@{$unsorted_vec}) : 0;

	if($len == 0) {
		return undef;
	}

	if($quantile > 100 or $quantile < 0) {
		return undef;
	}

	my @sorted_vec     = sort { $a <=> $b } @{$unsorted_vec};
	my $fraction       = $quantile / 100;
	my $fraction_index = $fraction * ($len-1);
	my $lower_index    = int($fraction_index);
	my $lower_delta    = $fraction_index - $lower_index;
	my $upper_index    = $lower_index + 1;
	my $upper_delta    = $upper_index - $fraction_index;
	my $lower_x        = $upper_delta > 0 ? $sorted_vec[$lower_index] : 0;
	my $upper_x        = $lower_delta > 0 ? $sorted_vec[$upper_index] : 0;
	my $weighted_ave   = $upper_delta * $lower_x + $lower_delta * $upper_x;

	return $weighted_ave;
}



sub mat_median (\@)
{
	my ($X) = @_;
	my $num = scalar(@{$X});
	my $dim = scalar(@{$$X[0]});

	my (@Medians);
	for(my $j = 0; $j < $dim; $j++) {
		my @x;
		for(my $i = 0; $i < $num; $i++) {
			if(defined($$X[$i][$j])) {
				push(@x, $$X[$i][$j]);
			}
		}
		push(@Medians, &vec_median(\@x));
	}
	return \@Medians;
}

#---------------------------------------------------------
# vec_mean
#---------------------------------------------------------
sub vec_mean {
	my ($vec) = @_;
	my ($num, $sum) = &vec_sum($vec);
	return $num > 0 ? $sum / $num : undef;
}

# vec_avg (deprecated: use vec_mean instead!)
sub vec_avg {	my ($vec) = @_;  	return &vec_mean($vec);  }
#---------------------------------------------------------


# Matrix mean
sub mat_mean (\@)
{
	my ($X) = @_;
	my $num = scalar(@{$X});
	my $dim = scalar(@{$$X[0]});

	my (@Means);
	for(my $j = 0; $j < $dim; $j++) {
		my @x;
		for(my $i = 0; $i < $num; $i++) {
			if(defined($$X[$i][$j])) {
				push(@x, $$X[$i][$j]);
			}
		}
		push(@Means, &vec_mean(\@x));
	}
	return \@Means;
}

#---------------------------------------------------------
# vec_trim_mean - calculate a trimmed mean
#             
#---------------------------------------------------------

sub vec_trim_mean {
	my ($unsorted_vec, $trim_perc) = @_;
	my $len = defined($unsorted_vec) ? scalar(@{$unsorted_vec}) : 0;

	if($len == 0) {
		return undef;
	}

	if($trim_perc > 100 or $trim_perc < 0) {
		return undef;
	}

	my @sorted_vec     = sort { $a <=> $b } @{$unsorted_vec};
	my $fraction       = $trim_perc / 100;
	my $fraction_index = $fraction * ($len-1);
	my $lower_index    = int($fraction_index);
	my $fraction_upper_index = (1-$fraction) * ($len-1);
	my $upper_index    = ceil($fraction_upper_index);
	
	my @trimmed_vec = @sorted_vec[$lower_index..$upper_index];
	
	
	my $trimmed_mean   = &vec_mean(\@trimmed_vec);

	return $trimmed_mean;
}


#---------------------------------------------------------
# vec_eval - Evaluate a function using the vector for
#            the function's arguments.
#---------------------------------------------------------
sub vec_eval
{
	my ($vec, $func) = @_;

	my $result = undef;

	if($func eq 'mean' or $func eq 'ave')
	{
		$result = &vec_mean($vec);
	}
	elsif($func eq 'median')
	{
		$result = &vec_median($vec);
	}
	elsif($func eq 'sum')
	{
		my ($n, $s) = &vec_sum($vec);
		$result     = $s;
	}
	elsif($func eq 'count')
	{
		my ($n, $s) = &vec_sum($vec);
		$result     = $n;
	}
	elsif($func eq 'std')
	{
		$result = &vec_std($vec);
	}
	elsif($func eq 'var')
	{
		my $s   = &vec_std($vec);
		$result = (defined($s) and $s =~ /\d/) ? $s*$s : undef;
	}
	elsif($func eq 'entropy')
	{
		$result = &shannon_entropy($vec);
	}
	elsif($func eq 'min')
	{
		$result = &vec_min($vec);
	}
	elsif($func eq 'max')
	{
		$result = &vec_max($vec);
	}

	return $result;
}

#---------------------------------------------------------
# vec_std
#---------------------------------------------------------
sub vec_std
{
	my ($vec) = @_;

	my ($n, $Sx, $Sxx) = &vec_suff_stats($vec);

	my $std = $n > 0 ?
		$Sxx / $n - (($Sx / $n) * ($Sx / $n)) : "";

   $std = 0 if ($std < 0);
   return sqrt($std);
}

#---------------------------------------------------------
# shannon_entropy - returns the entropy in bits.
#---------------------------------------------------------
sub shannon_entropy
{
	my ($buckets) = @_;

	my ($num, $total) = &vec_sum($buckets);

	# The entropy, cross entropy, and K-L divergence
	my ($entropy, $cross, $kl) = (-1, -1, -1);

	if($total > 0)
	{
		($entropy, $cross, $kl) = (0, 0, 0);

		# Assume the background distribution is uniform.
		my $q = 1 / $num;

		my $log2 = log(2);

		foreach my $p (@{$buckets})
		{
			if(defined($p) and $p > 0)
			{
				$p /= $total;

				my $plogp = $p * log($p) / $log2;

				$entropy -= $plogp;

				$cross -= $plogp - $p * log($q) / $log2;
			}
		}

		$kl = $entropy - $cross;
	}

	return ($entropy, $cross, $kl);
}

#---------------------------------------------------------
# mutual_information
#---------------------------------------------------------
sub mutual_information (\@\@)
{
	my ($vecX_str, $vecY_str) = @_;

	my @vecX = @{$vecX_str};
	my @vecY = @{$vecY_str};

	DEBUG_VO("mutual_information between\n");
	DEBUG_VO("   X: @vecX\n");
	DEBUG_VO("   Y: @vecY\n");

	my $total = @vecX;

	my %COUNTS_X;
	my %COUNTS_Y;
	my %COUNTS_XY;
	for (my $i = 0; $i < $total; $i++)
	{
		my $key_X = $vecX[$i];
		my $key_Y = $vecY[$i];
		my $key_XY = $vecX[$i] . " " . $vecY[$i];

		if (length($COUNTS_X{$key_X} == 0))
        { $COUNTS_X{$key_X} = 1; }
		else
        { $COUNTS_X{$key_X} = $COUNTS_X{$key_X} + 1; }
		if (length($COUNTS_Y{$key_Y} == 0))
        { $COUNTS_Y{$key_Y} = 1; }
		else
        { $COUNTS_Y{$key_Y} = $COUNTS_Y{$key_Y} + 1; }
		if (length($COUNTS_XY{$key_XY} == 0))
        { $COUNTS_XY{$key_XY} = 1; }
		else
        { $COUNTS_XY{$key_XY} = $COUNTS_XY{$key_XY} + 1; }

		#DEBUG_VO("      $i: X[$key_X]=$COUNTS_X{$key_X}\n");
		#DEBUG_VO("         Y[$key_Y]=$COUNTS_Y{$key_Y}\n");
		#DEBUG_VO("         XY[$key_XY]=$COUNTS_XY{$key_XY}\n");
	}

	my $mi = 0;
	foreach my $key_XY (keys %COUNTS_XY)
	{
		my ($key_X, $key_Y) = split(" ", $key_XY);

		my $p_X = $COUNTS_X{$key_X} / $total;
		my $p_Y = $COUNTS_Y{$key_Y} / $total;
		my $p_XY = $COUNTS_XY{$key_XY} / $total;

		DEBUG_VO("      PX($key_X) = $p_X\n");
		DEBUG_VO("      PY($key_Y) = $p_Y\n");
		DEBUG_VO("      PXY($key_XY) = $p_XY\n");

		$mi += ($p_XY) * log($p_XY / ($p_X * $p_Y));
	}

	return $mi;
}

#---------------------------------------------------------
# vec_angle - The angle between two vectors.
#---------------------------------------------------------
sub vec_angle (\@\@) {
	my ($X, $Y) = @_;
	my $norm_dot = &norm_dot_product($X,$Y);
	my $angle = undef;
	if(defined($norm_dot)) {
		$angle = &acos($norm_dot);
	}
	return $angle;
}

#---------------------------------------------------------
# norm_dot_product
#---------------------------------------------------------
sub norm_dot_product (\@\@) {
	my ($X, $Y) = @_;
	my $norm_dot = undef;
	my $lenX = &vec_length($X);
	my $lenY = &vec_length($Y);
	if($lenX > 0 and $lenY > 0) {
		my $dot = &dot_product($X,$Y);
		$norm_dot = $dot / $lenX / $lenY;
	}
	return $norm_dot;
}

#---------------------------------------------------------
# dot_product
#---------------------------------------------------------
sub dot_product (\@\@)
{
	my ($X, $Y) = @_;
	my $n = scalar(@{$X});
	my $m = scalar(@{$Y});
	$n = $n <= $m ? $n : $m;
	my $dot = 0;
	for (my $i = 0; $i < $n; $i++) {
		if(&is_numeric($$X[$i]) and &is_numeric($$Y[$i])) {
			$dot += $$X[$i] * $$Y[$i];
		}
	}
	return $dot;
}

#---------------------------------------------------------
# vec_length
#---------------------------------------------------------
sub vec_length (\@) {
	my ($X) = @_;
	return &dot_product($X,$X);
}

sub is_numeric ($) {
	my ($x) = @_;
	my $answer = 0;
	if (defined($x) and $x =~ /\d/) {
		$answer = 1;
	}
	return $answer;
}

#---------------------------------------------------------
# pearson
#---------------------------------------------------------
sub vec_pearson (\@\@)
{
	my ($vecX, $vecY) = @_;

	# my $dot = 0;
	my $Sx  = 0;
	my $Sy  = 0;
	my $Sxx = 0;
	my $Sxy = 0;
	my $Syy = 0;
	my $Nxy = 0;
	my $len = scalar(@{$vecX});
	for (my $i = 0; $i < $len; $i++)
	{
		if(&is_numeric($$vecX[$i]) and &is_numeric($$vecY[$i])) {
			$Nxy += 1;
			$Sx  += $$vecX[$i];
			$Sy  += $$vecY[$i];
			$Sxx += $$vecX[$i] * $$vecX[$i];
			$Syy += $$vecY[$i] * $$vecY[$i];
			$Sxy += $$vecX[$i] * $$vecY[$i];
		}
	}

	my $r = undef;

	if($Nxy > 1)
	{
		my $Vxx = $Sxx - $Sx * $Sx / $Nxy;
		my $Vyy = $Syy - $Sy * $Sy / $Nxy;
		my $Vxy = $Sxy - $Sx * $Sy / $Nxy;
		if($Vxx > 0 and $Vyy > 0)
        { $r = $Vxy / sqrt( $Vxx * $Vyy ); }
	warn "$Nxy $Vxx $Vyy $Vxy $r\n";
	}

	return ($r,$Nxy);
}

#---------------------------------------------------------
# canberra distance
#---------------------------------------------------------
sub vec_canbDist(\@\@) {
	my $vectorAref = shift(@_);
	my $vectorBref = shift(@_);
	my $dist = 0;
	my $num;
	my $denom;
	
	for (my $col=0; $col<@$vectorAref; $col++) {
		$num = abs($$vectorAref[$col] - $$vectorBref[$col]);
		$denom = abs($$vectorAref[$col]) + abs($$vectorBref[$col]);
		if ( ($num == 0) && ($denom == 0) ) {
			$dist += 0;
		} else {
			$dist += ($num)/($denom);
		}
	}
	return sqrt($dist);
}

#---------------------------------------------------------
# hamming distance
#---------------------------------------------------------
sub vec_hammingDist(\@\@) {
	my $vectorAref = shift(@_);
	my $vectorBref = shift(@_);
	my $dist = 0;
	
	for (my $col=0; $col<@$vectorAref; $col++) {
		if ( $$vectorAref[$col] != $$vectorBref[$col] ) {
			$dist++;
		}
	}
	return $dist;
}

#---------------------------------------------------------
# rand index
#---------------------------------------------------------
sub vec_randIndex(\@\@) {
	my $vectorAref = shift(@_);
	my $vectorBref = shift(@_);
	my ($a, $b, $c, $d) = (0, 0, 0, 0);

	for (my $col=0; $col<@$vectorAref; $col++) {
		if (($$vectorAref[$col]==1) && ($$vectorBref[$col]==1)) {
			$a++;
		} elsif (($$vectorAref[$col]==1) && ($$vectorBref[$col]==0)) {
			$b++;
		} elsif (($$vectorAref[$col]==0) && ($$vectorBref[$col]==1)) {
			$c++;
		} elsif (($$vectorAref[$col]==0) && ($$vectorBref[$col]==0)) {
			$d++;
		}
	}
	return (($a + $d)/($a + $b + $c + $d));
}

#---------------------------------------------------------
# Jaccard Similarity Coefficient
#---------------------------------------------------------
sub vec_jaccardSimCoeff(\@\@) {
	my $vectorAref = shift(@_);
	my $vectorBref = shift(@_);
	my ($M11, $M01, $M10) = (0, 0, 0);

	for (my $col=0; $col<@$vectorAref; $col++) {
		if (($$vectorAref[$col]==1) && ($$vectorBref[$col]==1)) {
			$M11++;
		} elsif (($$vectorAref[$col]==0) && ($$vectorBref[$col]==1)) {
			$M01++;
		} elsif (($$vectorAref[$col]==1) && ($$vectorBref[$col]==0)) {
			$M10++;
		}
	}
	return ($M11/($M01 + $M10 + $M11));
}

#---------------------------------------------------------
# Euclidean distance
#---------------------------------------------------------
sub vec_euclid (\@\@)
{
	my ($vecX, $vecY) = @_;

	my $num = 0;
	my $sum = 0;
	my $len = scalar(@{$vecX});
	for (my $i = 0; $i < $len; $i++)
	{
		if(&is_numeric($$vecX[$i]) and &is_numeric($$vecY[$i])) {
			my $diff = ($$vecX[$i] - $$vecY[$i]);
			$sum += $diff * $diff;
			$num += 1;
		}
	}

	my $euclid = $num > 0 ? $sum : "";

	return ($euclid,$num);
}

#---------------------------------------------------------
# pearson
#---------------------------------------------------------
sub vec_covariance (\@\@)
{
  my ($vecX, $vecY) = @_;

  # my $dot = 0;
  my $cov = 0;
  my $Nxy = 0;
  my $len = scalar(@{$vecX});

  my $MeanX = &vec_mean($vecX);
  my $MeanY = &vec_mean($vecY);

#  warn "X $MeanX Y $MeanY\n";

  for (my $i = 0; $i < $len; $i++)
  {
    # if (length($$vecX[$i]) > 0 and length($$vecY[$i]) > 0)
    if (defined($$vecX[$i]) and defined($$vecY[$i]) and
        $$vecX[$i] =~ /\d/ and $$vecY[$i] =~ /\d/)
    {
      $cov += (($$vecX[$i] - $MeanX) * ($$vecY[$i] - $MeanY));
#      warn "$$vecX[$i] $MeanX\t$$vecY[$i] $MeanY\n";
      $Nxy++;
    }
  }

  my $r = undef;

  if($Nxy > 1)
  {
     $r = $cov / $Nxy;
  }

  return ($r,$Nxy);
}

#---------------------------------------------------------
# vec_center
#---------------------------------------------------------
sub vec_center (\@)
{
	my ($vec) = @_;

	my $avg = &vec_avg($vec);

	my $std = &vec_std($vec);

	my @res;
	for (my $i = 0; $i < scalar(@{$vec}); $i++)
	{
		$res[$i] = (length($$vec[$i]) > 0 and $std > 0) ? (($$vec[$i] - $avg) / $std) : "";
	}

	return @res;
}

#---------------------------------------------------------
# correlation
#---------------------------------------------------------
sub correlation (\@\@)
{
	my ($vecX, $vecY) = @_;

	my $total = scalar(@{$vecX});

	my $sum_X = 0;
	my $sum_XX = 0;
	my $sum_Y = 0;
	my $sum_YY = 0;
	my $sum_XY = 0;
	my $num = 0;

	for (my $i = 0; $i < $total; $i++)
	{
		my $p_X = $$vecX[$i];
		my $p_Y = $$vecY[$i];

		if(&is_numeric($p_X) and &is_numeric($p_Y)) {
            $sum_X  += $p_X;
            $sum_XX += $p_X * $p_X;
            $sum_Y  += $p_Y;
            $sum_YY += $p_Y * $p_Y;
            $sum_XY += $p_X * $p_Y;
            $num++;
		}
	}

	my $correlation = undef;

	my $numerator = ($num * $sum_XY) - ($sum_X * $sum_Y);
	my $var_X     = ($num * $sum_XX) - ($sum_X * $sum_X);
	my $var_Y     = ($num * $sum_YY) - ($sum_Y * $sum_Y);

	if ($var_X > 0 && $var_Y > 0)
	{
		my $denominator = sqrt($var_X * $var_Y);
		$correlation    = $numerator / $denominator;
	}

	return $correlation;
}

#---------------------------------------------------------
# compute_score
#---------------------------------------------------------
sub compute_score (\@\@\$)
{
	my ($vecX_str, $vecY_str, $op) = @_;

	my @vecX = @{$vecX_str};
	my @vecY = @{$vecY_str};

	if ($op eq $MUTUAL_INFORMATION)         { return mutual_information(@vecX, @vecY); }
	elsif ($op eq $DOT_PRODUCT)             { return dot_product(@vecX, @vecY); }
	elsif ($op eq $CORRELATION_COEFFICIENT) { return correlation(@vecX, @vecY); }
}

sub norm_pdf
{
	my ($x, $mu, $sigma) = @_;

	$mu = defined($mu) ? $mu : 0;

	$sigma = defined($sigma) ? $sigma : 1;

	my $z = ($x - $mu) / $sigma;

	my $f = 1/sqrt(2*3.1415)*exp(-0.5*$z*$z);

	return $f;
}

#---------------------------------------------------------
# intersect
#---------------------------------------------------------
sub intersect (\@\@)
{
	my ($vecX_str, $vecY_str) = @_;

	my @vecX = @{$vecX_str};
	my @vecY = @{$vecY_str};

	my @res;
	my $counter = 0;

	my %h1;
	for (my $i = 0; $i < @vecX; $i++) { $h1{$vecX[$i]} = "1"; }

	for (my $i = 0; $i < @vecY; $i++) { if ($h1{$vecY[$i]} eq "1") { $res[$counter++] = $vecY[$i]; $h1{$vecY[$i]} = ""; } }

	return @res;
}

#---------------------------------------------------------
# intersect
#---------------------------------------------------------
sub union (\@\@)
{
	my ($vecX_str, $vecY_str) = @_;

	my @vecX = @{$vecX_str};
	my @vecY = @{$vecY_str};

	my @res;
	my $counter = 0;

	my %h1;
	for (my $i = 0; $i < @vecX; $i++) { $h1{$vecX[$i]} = "1"; }
	for (my $i = 0; $i < @vecY; $i++) { $h1{$vecY[$i]} = "1"; }

	for my $key (keys %h1)
	{
		$res[$counter++] = $key;
	}

	return @res;
}


# Subroutine for min.  Takes an array as input (not an array reference).
# Badly named, conflicts with the min in the normal perl math library
# sub min {
# 	my ($numberInputs, $firstInput, @array, $value);
# 	our $min;
# 	undef $min;
# 	$numberInputs = $#_ + 1;
# 	if ($numberInputs == 1) {
# 		$firstInput = shift;
# 		if (@$firstInput) {
# 			@array = @$firstInput;
# 		} else {
# 			$min = $firstInput;
# 		}
# 	} else {
# 		@array = @_;
# 	}
	
# 	if (not $min) {
# 		$min = shift(@array);
# 		for $value (@array) {
# 			if ($value < $min) { $min = $value; }
# 		}
# 	}
# 	return $min;
# }

# subroutine for max on an array reference
# I think you could also just use regular min / max and pass in the array instead of the reference!
sub arraymin (\@)
{
    my ($numberInputs, $firstInput, @array, $value);
    our $arraymin;
    undef $arraymin;
    $firstInput = shift;
    @array = @$firstInput;
    unless ($arraymin)
    {
        $arraymin = shift(@array);
        for $value (@array)
        {
            $arraymin = $value if $arraymin > $value;
        }
    }
    return $arraymin;
}

# Subroutine for max.  Takes an array as input (not an array reference).
# Badly named, conflicts with the min in the normal perl math library
# sub max
# {
#     my ($numberInputs, $firstInput, @array, $value);
#     our $max;
#     undef $max;
#     $numberInputs = $#_ + 1;
#     if ($numberInputs == 1)
#     {
#         $firstInput = shift;
#         if (@$firstInput)
#         {
#             @array = @$firstInput;
#         }
#         else
#         {
#             $max = $firstInput;
#         }
#     }
#     else
#     {
#         @array = @_;
#     }
#     unless ($max)
#     {
#         $max = shift(@array);
#         for $value (@array)
#         {
#             $max = $value if $max < $value;
#         }
#     }
#     return $max;
# }

# subroutine for max on an array reference
# I think you could also just use regular min / max and pass in the array instead of the reference!
sub arraymax (\@)
{
    my ($numberInputs, $firstInput, @array, $value);
    our $arraymax;
    undef $arraymax;
    $firstInput = shift;
    @array = @{$firstInput};
    unless ($arraymax)
    {
        $arraymax = shift(@array);
        for $value (@array)
        {
            $arraymax = $value if $arraymax < $value;
        }
    }
    return $arraymax;
}

sub whichismax
{
    my ($max, $firstInput, @array, $arrayLength, $value, $i);
    our $maxElement;
    undef $maxElement;
    $firstInput = shift;
    @array = @$firstInput;
    $max = arraymax(@array);
    unless ($maxElement)
    {
        $arrayLength = $#array + 1;
        for ($i=0; $i<$arrayLength; $i++)
        {
            $value = shift(@array);
            if ($value == $max)
            {
                $maxElement = $i;
                last;
            }
        }
    }
    return $maxElement;
}

sub whichismin (\@)
{
    my ($min, $firstInput, @array, $arrayLength, $value, $i);
    our $minElement;
    undef $minElement;
    $firstInput = shift;
    @array = @$firstInput;
    $min = &arraymin(@array);
    unless ($minElement)
    {
        $arrayLength = $#array + 1;
        for ($i=0; $i<$arrayLength; $i++)
        {
            $value = shift(@array);
            if ($value == $min)
            {
                $minElement = $i;
                last;
            }
        }
    }
    return $minElement;
}


# subroutine to calculate the mutual information between two orfs.  Takes as input the two orfs to compare and a hash with experimental data for each orf as an 
# array keyed by orf name.
sub mi (\$\$\%)
{
    my $orf_i_name = shift;
    my $orf_j_name = shift;
    my $matrix_name = shift;
    my $orf_i = $$orf_i_name;
    my $orf_j = $$orf_j_name;
    my %matrix = %$matrix_name;
    my ($k, $l, @commonExp, $commonExp, $numCommonExp, $x);
    our $mi=0;
    # first find how many experiments have data for both orf_i and orf_j.
    $numCommonExp = 0;
    undef @commonExp;
    for ($x=0; $x<=78; $x++)
    {
        if (($matrix{$orf_i}[$x] =~ m/[0-9]/o) && ($matrix{$orf_j}[$x] =~ m/[0-9]/o))
        {
            $numCommonExp++;
            push(@commonExp, $x);
        }
    }
    # now start mi calculation.
    for ($k=0; $k<=9; $k++)
    {
        # find how many values orf_i has in bin k in the common experiments.
        my $k_count = 0;
        foreach $commonExp (@commonExp)
        {
            if (($matrix{$orf_i}[$commonExp] =~ m/^[0-9]$/o) && ($matrix{$orf_i}[$commonExp] == $k))
            {
                $k_count++;
            }
        }
        for ($l=0; $l<=9; $l++)
        {
            # find how many values orf_j has in bin l in the common experiments.
            my $l_count = 0;
            my $kl_count = 0;
            foreach $commonExp (@commonExp)
            {
                if (($matrix{$orf_j}[$commonExp] =~ m/^[0-9]$/o) && ($matrix{$orf_j}[$commonExp] == $l))
                {
                    $l_count++;
                    # check to see if orf_i has value k for this experiment.
                    if (($matrix{$orf_i}[$commonExp] =~ m/^[0-9]$/o) && ($matrix{$orf_i}[$commonExp] == $k))
                    {
                        $kl_count++;
                    }
                }
            }
            # find probabilities.
            my ($P_i_k, $P_j_l, $P_ij_kl);
            $P_i_k = $k_count/$numCommonExp;
            $P_j_l = $l_count/$numCommonExp;
            $P_ij_kl = $kl_count/$numCommonExp;
            # make sure none of the probabilites are zero (in which case we would be adding zero, but perl would freak out about taking the log of zero).
            unless ($P_ij_kl == 0)
            {
                $mi += $P_ij_kl*(log($P_ij_kl/($P_i_k*$P_j_l))/log(2)); 
            }
        }
    }
    # round to 3 decimal places to be consistent with Josh's results.
    $mi = sprintf("%.3f", $mi);
    return $mi;
}




# subroutine to really(!) sort hash keys by their corresponding hash values.
sub sortHashKeysByLinkedValue (\%)
{
    my (@unsortedKeys, $hash, $unsortedKeysLength, $i, @sortedHashValues);
    our @sortedHashKeys;
    $hash = shift;
    @unsortedKeys = keys(%$hash);
    $unsortedKeysLength = $#unsortedKeys;
    undef(@sortedHashValues);
    undef(@sortedHashKeys);
    $sortedHashKeys[0] = $unsortedKeys[0];
    $sortedHashValues[0] = $$hash{$unsortedKeys[0]};
    for ($i=1; $i<=$unsortedKeysLength; $i++)
    {
        my ($currentKey, $currentValue, $numberCurrentGreaterThan, $sortedHashValuesLength, $j);
        $currentKey = $unsortedKeys[$i];
        $currentValue = $$hash{$currentKey};
        $numberCurrentGreaterThan = 0;
        $sortedHashValuesLength = $#sortedHashValues + 1;
        for ($j=0; $j<$sortedHashValuesLength; $j++)
        {
            if ($currentValue >= $sortedHashValues[$j])
            {
                $numberCurrentGreaterThan++;
            }
        }
        if ($numberCurrentGreaterThan == 0)
        {
            unshift(@sortedHashValues, $currentValue);
            unshift(@sortedHashKeys, $currentKey);
        }
        elsif ($numberCurrentGreaterThan == $sortedHashValuesLength)
        {
            push(@sortedHashValues, $currentValue);
            push(@sortedHashKeys, $currentKey);
        }
        else
        {
            # falls in middle of @sortedHashValues.  split @sortedHashValues into two arrays
            my (@headSortedHashValues, @tailSortedHashValues, @headSortedHashKeys, @tailSortedHashKeys, $k, $l);
            undef(@headSortedHashValues);
            undef(@tailSortedHashValues);
            undef(@headSortedHashKeys);
            undef(@tailSortedHashKeys);
            for ($k=0; $k<$numberCurrentGreaterThan; $k++)
            {
                push(@headSortedHashValues, $sortedHashValues[$k]);
                push(@headSortedHashKeys, $sortedHashKeys[$k]);
            }
            for ($l=$numberCurrentGreaterThan; $l<$sortedHashValuesLength; $l++)
            {
                push(@tailSortedHashValues, $sortedHashValues[$l]);
                push(@tailSortedHashKeys, $sortedHashKeys[$l]);
            }
            push(@headSortedHashValues, $currentValue);
            push(@headSortedHashValues, @tailSortedHashValues);
            @sortedHashValues = @headSortedHashValues;
            push(@headSortedHashKeys, $currentKey);
            push(@headSortedHashKeys, @tailSortedHashKeys);
            @sortedHashKeys = @headSortedHashKeys;
        }
    }
    return @sortedHashKeys;
}

sub binUsingIqrWidth {
	# bin width = 2*(IQR)*N-1/3
	# where IQR = 75th pctl - 25th pctl
	# N = number of samples;
	# and the number of bins would be based on dividing the dataset range
	# by the bin width.
}

sub binUsingLogNumBins {
	# Number of bins = 1+3.3*ln(N) where the bin width would be the
	# dataset range by the number of bins
}

# A short summary: Shimazaki H. and Shinomoto S.
# "A recipe for optimizing a time-histogram"
# Neural Information Processing Systems, Vol. 19, 2007.
sub binUsingShimazakiShinomoto {
	my ($sorted_data,$num_bin_min,$num_bin_max,$num_bin_inc) = @_;
	my $min_jitter   = undef;
	my $best_centers = undef;
	my $best_counts  = undef;
	if(defined($sorted_data)) {
		for(my $n = $num_bin_min; $n <= $num_bin_max; $n += $num_bin_inc) {
			my ($width,$centers) = &getEqualWidthBinCenters($sorted_data,$n);
			my $counts = &histogram($sorted_data,$centers);
			my $jitter = &getShimazakiShinomotoJitter($counts,$width);

			if(not(defined($min_jitter)) or ($min_jitter > $jitter)) {
				$min_jitter   = $jitter;
				$best_centers = $centers;
				$best_counts  = $counts;
			}
		}
	}
	return ($best_centers,$best_counts);
}

sub getShimazakiShinomotoJitter {
	my ($counts, $delta) = @_;
	my ($n,$mean,$stdev) = &vec_stats($counts);
	my $jitter = (2.0*$mean - $stdev*$stdev) / $delta / $delta;
	return $jitter;
}

sub getFreqsFromCounts {
	my ($counts) = @_;
	my $sum = 0;
	foreach my $x (@{$counts}) {
		$sum += $x;
	}
	my @freq;
	foreach my $x (@{$counts}) {
		push(@freq, $sum > 0 ? $x/$sum : undef);
	}
	return \@freq;
}

sub histogram {
	my ($sorted_data, $bin_centers) = @_;

	my $num_data = scalar(@{$sorted_data});
	my $num_bins = scalar(@{$bin_centers});

	my @counts;
	for(my $i = 0; $i < $num_bins; $i++) {
		$counts[$i] = 0;
	}

	# The index b denotes the current bin.
	my $b = 0;
	for (my $i = 0; $i < $num_data; $i++) {
		my $x = $$sorted_data[$i];
		while ( ($b < $num_bins-1) and
				(abs($x-$$bin_centers[$b]) > abs($x-$$bin_centers[$b+1]) )
				) {
			$b++;
		}
		$counts[$b]++;
	}
	return \@counts;
}

sub getAbsDifference {
	# why would anyone ever use this function?
	die "Are you actually using getAbsDifference in libstats.pl? If so, you can remove this line. Although I would say you should just use abs(x - y). Otherwise this function is deprecated! --Alex \n";
	my ($x, $y) = @_;
	my $distance = abs($x-$y);
	return $distance;
}

sub getEqualWidthBinCenters {
	my ($sorted_data,$n) = @_;

	my $min   = $$sorted_data[0];
	my $max   = $$sorted_data[scalar(@{$sorted_data})-1];
	my $width = ($max - $min) / $n;

	my @bin_centers;

	$bin_centers[0] = $min + ($width * 0.5);

	for(my $i = 1; $i < $n; $i++) {
		$bin_centers[$i] = $bin_centers[$i-1] + $width; 
	}
	return ($width,\@bin_centers);
}


1
