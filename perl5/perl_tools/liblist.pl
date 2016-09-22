#!/usr/bin/perl

use strict;

##---------------------------------------------------------------------------##
## public:
##---------------------------------------------------------------------------##

##---------------------------------------------------------------------------##
## \@list listDuplicate($int n=2, $scalar value=$_)
##---------------------------------------------------------------------------##
sub listDuplicate
{
   my ($n, $value) = @_;
   $n = defined($n) ? $n : 2;

   my @list;

   for(my $i = 0; $i < $n; $i++)
   {
      push(@list, $value);
   }

   return \@list;
}

##---------------------------------------------------------------------------##
## $int listRemoveUndef (\@list)
##---------------------------------------------------------------------------##
sub listRemoveUndef(\@)
{
   my ($list) = @_;
   my $n = scalar(@{$list});
   for(my $i = $n - 1; $i >= 0; $i--)
   {
      if(not(defined($$list[$i])))
      {
         splice(@{$list}, $i, 1);
      }
   }
}

##---------------------------------------------------------------------------##
## $int listSize (\@list)
##---------------------------------------------------------------------------##
sub listSize
{
   my ($list) = @_;
   return scalar(@{$list});
}

##---------------------------------------------------------------------------##
## $string listMaxString (\@list)
##---------------------------------------------------------------------------##
sub listMaxString
{
   my ($list) = @_;
   my $result = undef;
   foreach my $element (@{$list})
   {
      if(not(defined($result)) or $element gt $result)
      {
         $result = $element;
      }
   }
   return $result;
}

##---------------------------------------------------------------------------##
## $double listMax (\@list)
##---------------------------------------------------------------------------##
sub listMax
{
   my ($list) = @_;
   my $result = undef;
   foreach my $element (@{$list})
   {
      if(not(defined($result)) or $element > $result)
      {
         $result = $element;
      }
   }
   return $result;
}

##---------------------------------------------------------------------------##
## $double listSum (\@list)
##---------------------------------------------------------------------------##
sub listSum
{
   my ($list) = @_;
   my $result = 0;
   my $num    = 0;
   foreach my $element (@{$list})
   {
      if($element =~ /\S/ and $element ne 'NaN')
      {
         $result += $element;
         $num++;
      }
   }
   return $num == 0 ? undef : $result;
}

##---------------------------------------------------------------------------##
## $string listMinString (\@list)
##---------------------------------------------------------------------------##
sub listMinString
{
   my ($list) = @_;
   my $result = undef;
   foreach my $element (@{$list})
   {
      if(not(defined($result)) or $element lt $result)
      {
         $result = $element;
      }
   }
   return $result;
}

#---------------------------------------------------------------------------##
# $double listMin (\@list)
#---------------------------------------------------------------------------##
sub listMin
{
   my ($list) = @_;
   my $result = undef;
   foreach my $element (@{$list})
   {
      if(not(defined($result)) or $element < $result)
      {
         $result = $element;
      }
   }
   return $result;
}

#---------------------------------------------------------------------------##
# \@list listSublist (\@list list, \@list indices)
#---------------------------------------------------------------------------##
sub listSublist
{
   my ($list, $indices, $offset) = @_;
   $offset = defined($offset) ? $offset : 0;

   my @sublist;

   foreach my $index (@{$indices})
   {
      push(@sublist, $$list[$index + $offset]);
   }

   return \@sublist;
}

# Join only part of a list defined by a sub-selection.
sub listSubJoin {
   my ($delim, $list, $selection, $offset) = @_;
   my $sublist = &listSublist($list, $selection, $offset);
   return join($delim, @{$sublist});
}

#---------------------------------------------------------------------------##
# \@list listCombinations (\@list, $int min=undef, $int max=undef,
#                          $string delim="\t")
#---------------------------------------------------------------------------##
sub listCombinations
{
   my ($list, $min, $max, $delim) = @_;
   $delim = not(defined($delim)) ? "\t" : $delim;

   my %result;

   my @bits;
   foreach my $item (@{$list})
      { push(@bits, 0); }

   my $i = 0;
   &listCombinationsRecursively($list, \@bits, \%result, \$i, $min, $max, $delim);

   my @result;
   foreach my $combination (sort(keys(%result)))
   {
      $i = $result{$combination};
      $result[$i] = $combination;
   }

   return \@result;
}

##---------------------------------------------------------------------------##
## private:
##---------------------------------------------------------------------------##

##---------------------------------------------------------------------------##
## void listCombinationsRecursively (\@list, \@list bits, \%set result,
##                                   \$int i, $int min, $int max,
##                                   $string delim="\t")
##---------------------------------------------------------------------------##
sub listCombinationsRecursively
{
   my ($list, $bits, $result, $i, $min, $max, $delim) = @_;

   my @combination;
   for(my $j = 0; $j < scalar(@{$list}); $j++)
   {
      if($$bits[$j])
      {
         push(@combination, $$list[$j]);
      }
   }

   if($#combination >= 0 and
      (not(defined($min)) or $#combination >= ($min - 1)) and
      (not(defined($max)) or $#combination <= ($max - 1)))
   {
      my $combination = join($delim, @combination);

      if(not(exists($$result{$combination})))
      {
         $$result{$combination} = $$i;
         $$i++;
      }
   }

   for(my $j = 0; $j < scalar(@{$bits}); $j++)
   {
      if($$bits[$j] == 0)
      {
         my @bits_copy  = @{$bits};
         $bits_copy[$j] = 1;
         &listCombinationsRecursively($list, \@bits_copy, $result, $i, $min, $max, $delim);
      }
   }
}


##---------------------------------------------------------------------------##
## void listPrint (\@list, \*FILE file=STDOUT, $delim)
##---------------------------------------------------------------------------##
sub listPrint
{
   my ($list, $fp, $delim) = @_;
   $fp = not(defined($fp)) ? \*STDOUT : $fp;
   $delim = not(defined($delim)) ? "\t" : $delim;

   my $i = 0;
   foreach my $element (@{$list})
   {
      if($i > 0)
      {
         print $delim;
      }
      print $fp "$element";
      $i++;
   }
}

#---------------------------------------------------------------------------
# \@list listRead ($string file, $string delim="\t", int col=0,
#                  \%assoc alias=undef, $int headers=0)
#---------------------------------------------------------------------------
sub listRead
{
   my ($file, $delim, $col, $alias, $headers) = @_;
   $col     = not(defined($col)) ? 0 : $col;
   $delim   = not(defined($delim)) ? "\t" : $delim;
   $headers = defined($headers) ? $headers : 0;

   my $fp;
   open($fp, $file) or die("Could not open file '$file' in setRead");
   my @list;
   my $line_no = 0;
   my $header = '';
   while(my $line = <$fp>)
   {
      $line_no++;

      if($line_no > $headers)
      {
         my @tuple = split($delim, $line);
         chomp($tuple[$#tuple]);
         my $element = $tuple[$col];
         if(defined($alias))
         {
            if(exists($$alias{$element}))
            {
               $element = $$alias{$element};
               push(@list, $element);
            }

         }
         else
         {
            push(@list, $element);
         }
      }
      else
      {
         $header .= $line;
      }
   }
   close($fp);

   # if($headers > 0)
   # {
   #    return (\@list, $header);
   # }
   return \@list;
}

##-----------------------------------------------------------------------------
## \@list listRandom (\@list list, $int num=scalar(@list), $int replace=1)
##-----------------------------------------------------------------------------
sub listRandom
{
   my ($list, $num, $replace) = @_;
   $num     = not(defined($num)) ? scalar(@{$list}) : $num;
   $replace = not(defined($replace)) ? 1 : 0;

   my $list_copy = $list;
   my @sub_list;

   if(not($replace))
   {
      my @list_copy = @{$list};
      $list_copy = \@list_copy;
   }

   for(my $i=0; $i<$num; $i++)
   {
     my $r = int(rand(scalar(@{$list_copy})));
     my $item;
     if($replace)
     {
       $item = $$list_copy[$r];
     }
     else
     {
       $item = splice(@{$list_copy}, $r, 1);
     }
     push(@sub_list, $item);
   }
   return \@sub_list;
}

sub listRandomElement
{
   my ($list) = @_;

   my $index  = int(rand(scalar(@{$list})));

   return $$list[$index];
}

##-----------------------------------------------------------------------------
## $double listMean (\@list)
##-----------------------------------------------------------------------------
sub listMean
{
   my ($list) = @_;

   my $mean = 0;

   foreach my $element (@{$list})
   {
      $mean += $element;
   }

   my $num = scalar(@{$list});

   if($num > 0)
   {
      $mean /= $num;
   }
   else
   {
      $mean = undef;
   }

   return $mean;
}

# \@list permutation ($int num)
sub permutation
{
   my ($num) = @_;

   my @list;
   for(my $i = 0; $i < $num; $i++)
   {
      push(@list, $i);
   }

   return &listPermute(\@list, $num);
}

# \@list listPermute (\@list, $int num=scalar(@list), $replace=0)
sub listPermute
{
    # Bugfix on Aug. 16, 2006 by Martina and Alex
    my ($list, $numToPick, $withReplacement) = @_;
    
    my $num_entries = scalar(@{$list});
    
    if (!defined($numToPick)) { $numToPick = $num_entries; } # default: entire length of the list    
    if (!defined($withReplacement)) { $withReplacement = 0; } # default: "without replacement"
    
    my @new_list;
    
    if (not($withReplacement)) {
	my %indexHash = undef;
	
	# choose WITHOUT REPLACEMENT
	for (my $i = 0; $i < $num_entries; $i++) {
	    $indexHash{$i} = $i; # save the indices in the hash
	    # remember that an array in perl is actually more like a linked-list,
	    # when considering access time and modification time complexity
	}
	
	# now randomize the hash, up through the number we want to pick...
	for (my $i = 0; $i < $numToPick; $i++) {
	    # We will swap item $i with item (random from $i (inclusive) to end of list)
	    my $remainingRange  = $num_entries - $i;
	    my $indexToSwapWith = int(rand($remainingRange)) + $i; # could swap this element from any other element from here on to the end
	    push(@new_list, $$list[$indexHash{$indexToSwapWith}]);	   
	    $indexHash{$indexToSwapWith} = $indexHash{$i}; # do the swap! actually, only do one half of the swap, since we never use $indexHash{$i} again, we don't have to set it!
	}
	
    } else {
	# choose a bunch WITH replacement (this is quick and straightforward)
	for (my $i = 0; $i < $numToPick; $i++) {
	    my $indexWeChooseWithReplacement = int(rand($num_entries));
	    push(@new_list, $$list[$indexWeChooseWithReplacement]);
	}
    }
    return \@new_list;
}

# $int binarySearch (\@list, $double value,
#                    $int beg=undef, $int end=undef)
sub binarySearch
{
   my ($list, $value, $beg, $end) = @_;
   my $index;

   $beg = defined($beg)   ? $beg   : 0;
   $end = defined($end)   ? $end   : scalar(@{$list}) - 1;

   # Base case:
   if($beg >= $end - 1)
   {
      $index = $beg;
   }
   else
   {
      my $pivot       = int(($end + $beg) * 0.5);
      my $pivot_val   = $$list[$pivot];

      my $beg_val = $$list[$beg];
      my $end_val = $$list[$end];
      print STDERR "[$value, $beg_val, $pivot_val, $end_val]\n";

      if($value < $pivot_val)
      {
         $index = &binarySearch($list, $value, $beg, $pivot);
      }
      elsif($value > $pivot_val)
      {
         $index = &binarySearch($list, $value, $pivot, $end);
      }
      else
      {
         $index = $pivot;
      }
   }
   return $index;
}

##-----------------------------------------------------------------------------
## \@\@list nest(\@list x)
#
##-----------------------------------------------------------------------------
sub nest
{
   my ($x) = @_;

   my @nested;

   foreach my $val (@{$x})
   {
      push(@nested, [$val]);
   }

   return \@nested;
}

##-----------------------------------------------------------------------------
## \@list denest(\@\@list x)
#
##-----------------------------------------------------------------------------
sub denest
{
   my ($x) = @_;

   my @denested;

   foreach my $list (@{$x})
   {
      push(@denested, @{$list});
   }

   return \@denested;
}

sub listPaste(\@\@)
{
   my ($x, $y, $delim) = @_;
   $delim = defined($delim) ? $delim : "\t";
   my $n = scalar(@{$x});
   my $m = scalar(@{$y});
   my $min = $n < $m ? $n : $m;
   my $max = $n < $m ? $m : $n;
   my @xy;
   for(my $i = 0; $i < $min; $i++)
   {
      push(@xy, $$x[$i] . $delim . $$y[$i]);
   }
   for(my $i = $min; $i < $max; $i++)
   {
      if($n == $max)
      {
         push(@xy, $$x[$i] . $delim);
      }
      else
      {
         push(@xy, $delim . $$y[$i]);
      }
   }
}

##-----------------------------------------------------------------------------
## \@\@list listsPaste(\@\@list x, \@\@list y)
#
##-----------------------------------------------------------------------------
sub listsPaste
{
   my ($x, $y) = @_;

   my @z;

   if(not(defined($x)))
   {
      @z = @{$y};
   }
   elsif(not(defined($y)))
   {
      @z = @{$x};
   }
   else
   {
      if(scalar(@{$x}) > scalar(@{$y}))
      {
         my $tmp = $x;
         $x = $y;
         $y = $tmp;
      }

      my $n = scalar(@{$x});

      my $m = scalar(@{$y});

      for(my $i = 0; $i < $n; $i++)
      {
         my @zz = (@{$$x[$i]}, @{$$y[$i]});
         $z[$i] = \@zz;
      }

      for(my $i = $n; $i < $m; $i++)
      {
         my @zz = @{$$y[$i]};
         $z[$i] = \@zz;
      }
   }
   return \@z;
}

1




