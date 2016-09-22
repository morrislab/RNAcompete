use strict;

sub myJoin {
   my ($delim, $listref, $empty) = @_;
   $delim = defined($delim) ? $delim : "\t";
   $listref = defined($listref) ? $listref : \@_;
   $empty = defined($empty) ? $empty : '';

   my $joined = '';
   my $len = scalar(@{$listref});

   if($len > 0) {
      $joined = length($$listref[0]) > 0 ? $$listref[0] : $empty;
      for(my $i = 1; $i < $len; $i++) {
         my $value = length($$listref[$i]) > 0 ? $$listref[$i] : $empty;
         $joined .= $delim . $value;
      }
   }
   return $joined;
}


# Possibly not necessary...
sub capEnds # ($delim, $str)
{
   my $delim = $_[0];

   if(not(defined($delim)))
   {
      $delim = "\t";
   }

   if(not(defined($_[1])))
   {
      $_ = '{}' . $delim . $_ . $delim . '{}';
   }
   else
   {
      $_[1] = '{}' . $delim . $_ . $delim . '{}';
   }
}

sub decapEnds # ($delim, $str)
{
   my $delim = $_[0];

   if(not(defined($delim)))
   {
      $delim = "\t";
   }

   my $tuple;
   if(not(defined($_[1])))
     { $tuple = &mySplit($delim, $_); }
   else
     { $tuple = &mySplit($delim, $_[1]); }

   pop(@{$tuple});
   shift(@{$tuple});

   if(not(defined($_[1])))
     { $_ = join($delim,@{$tuple}); }
   else
     { $_[1] = join($delim,@{$tuple}); }
}

# Possibly not necessary...
sub myChop
{
   if($#_ >= 0)
     { $_[0] =~ s/[\n]$//; }
   else
     { s/[\n]$//; }
}


# Does not clobber the trailing blank entries like split() does.
sub mySplit
{
   my ($delim, $str) = @_;
   $delim = defined($delim) ? $delim : "\t";
   $str   = defined($str)   ? $str   : $_;

   # Stick a dummy on the beginning and end of the string.
   $str = '{}' . $delim . $str . $delim . '{}';

   my @tuple = split($delim, $str);

   # Remove the dummies.
   pop(@tuple);
   shift(@tuple);

   return \@tuple;
}

# Returns a permutation of the list passed in as an argument.
sub permute
{
  my(@list) = @_;
  my(@p);
  my($i) = 0;

  while(@list)
  {
    my $r = int(($#list+1)*rand());
    $p[$i] = splice(@list, $r, 1);
    $i++;
  }

  return @p;
}

sub unlexifyNumber
{
  my $oldNum = shift @_;
  my $newNum = $oldNum;

  $newNum =~ s/([^0-9])0+([1-9])/$1$2/g;

  return $newNum;
}

1
