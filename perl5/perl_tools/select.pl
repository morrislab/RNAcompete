#!/usr/bin/perl

require "libfile.pl";

use strict;

$| = 1;

my $verbose      = 1;
my $val_ranges   = undef;
my $match_ranges = undef;
my $delim        = "\t";
my $regex        = undef;
my @files;
my $negate       = 0;
my $op           = '=~';
my $hardop       = undef;
my $blanks       = 1;
my $headers      = 0;
my $print_vals   = 0;
my $absolute     = 0;

while(@ARGV)
{
   my $arg = shift @ARGV;

   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
   elsif(-f $arg)
   {
      # open($file,$arg) or die("Could not open file '$arg' for reading.");
      push(@files,$arg);
   }
   elsif($arg eq '-d')
   {
      $delim = shift @ARGV;
   }
   elsif($arg eq '-f' or $arg eq '-k' or $arg eq '-c' or $arg eq '-v')
   {
      $val_ranges = shift @ARGV;
   }
   elsif($arg eq '-b')
   {
      $blanks = 0;
   }
   elsif($arg eq '-m')
   {
      $match_ranges = shift @ARGV;
   }
   elsif($arg eq '-h')
   {
      $headers = shift @ARGV;
   }
   elsif($arg eq '-p')
   {
      $print_vals = 1;
   }
   elsif($arg eq '-not')
   {
      $negate = 1;
   }
   elsif($arg eq '-op')
   {
      $op = shift @ARGV;
   }
   elsif($arg eq '-abs')
   {
      $absolute = 1;
   }
   elsif($arg eq '-gt')
   {
      $hardop = '>';
   }
   elsif($arg eq '-gte')
   {
      $hardop = '>=';
   }
   elsif($arg eq '-lt')
   {
      $hardop = '<';
   }
   elsif($arg eq '-lte')
   {
      $hardop = '<=';
   }
   elsif($arg eq '-eq')
   {
      $hardop = '==';
   }
   elsif($arg eq '-ne')
   {
      $hardop = '!=';
   }
   elsif($arg eq '-neq')
   {
       die "\nselect.pl: Error in argument passed to select.pl: -neq is NOT the proper way of specified !=. You want to say -ne instead.\n\n";
   }
   elsif($arg eq '-lgt')
   {
      $hardop = 'gt';
   }
   elsif($arg eq '-lgte')
   {
      $hardop = 'gte';
   }
   elsif($arg eq '-llt')
   {
      $hardop = 'lt';
   }
   elsif($arg eq '-llte')
   {
      $hardop = 'llte';
   }
   elsif($arg eq '-leq')
   {
      $hardop = 'eq';
   }
   elsif($arg eq '-lne')
   {
      $hardop = 'ne';
   }
   elsif(length($regex)==0)
   {
      $regex = $arg;
   }
   else
   {
      die("Bad argument '$arg' given.");
   }
}

$regex = defined($regex) ? $regex : '/\S/';

if($#files==-1)
{
   push(@files,'-');
}

my $cols = defined($val_ranges) ? [] : [0];
my $match_cols = undef;
my $iter    = 0;
my $passify = 100000;
foreach my $file (@files)
{
   my $fin;
   if($file eq '-')
   {
      $fin = \*STDIN;
   }
   elsif(not(open($fin,$file)))
   {
      die("Could not open file '$file'.");
   }
   my $line     = 0;
   my $max_cols = 0;
   while(<$fin>)
   {
      $iter++;
      $line++;

      if($line > $headers)
      {
         chomp;

         # my $padded    = &fill($val_ranges + 1, undef, 1, $delim);
         # my @tuple     = split($delim, $padded);
         my @tuple     = split($delim);
         my $new_tuple = defined($match_ranges) ? [] : undef;
         my $tmp_max   = $max_cols;
         my $tmp_cols  = &getCols(\@tuple, $match_ranges, \$tmp_max);
         my $num_match = 0;
         $match_cols   = defined($tmp_cols) ? $tmp_cols : $match_cols;
         $tmp_cols     = &getCols(\@tuple, $val_ranges, \$max_cols);
         $cols         = defined($tmp_cols) ? $tmp_cols : $cols;
         my $num_cols  = scalar(@{$cols});

         my $result = 1;
         for(my $i = 0; $i < $num_cols; $i++)
         {
            my $col   = $$cols[$i];
            my $value = $col < scalar(@tuple) ? $tuple[$col] : undef;

            if(defined($hardop) and not(&OpIsLexical($hardop))) {
               if($absolute) {
                  $value = abs($value);
               }
            }

            my $true  = defined($value) ? &evalRegex($value, $regex, $op, $hardop, $negate) : 0;

            if(not($true)) {
               $result = 0;
            }
            elsif(defined($match_cols) and $col < scalar(@tuple))
            {
               my $j = $$match_cols[$i % scalar(@{$match_cols})];
               my $entry = $tuple[$j];
               push(@{$new_tuple}, $entry);
               if($print_vals)
               {
                  push(@{$new_tuple}, $value);
               }
               $num_match++;
            }
         }

         if(defined($match_ranges))
         {
            if(defined($new_tuple) and $num_match > 0)
            {
               print STDOUT join($delim, @{$new_tuple}), "\n";
            }
            elsif($blanks)
            {
               print "\n";
            }
         }

         elsif($result and $num_cols > 0)
         {
            print STDOUT "$_\n";
         }

         if($verbose and $iter % $passify == 0)
         {
            print STDERR "select.pl: $iter lines processed.\n";
         }
      }
      else
      {
         print;
      }
   }
   close($fin);
}

sub OpIsLexical {
   if($_[0] =~ /\w/) {
      return 1;
   }
   return 0;
}

__DATA__
syntax: select.pl [OPTIONS] REGEX TAB_FILE [TAB_FILE2 ...]

Select a subset of the rows of the supplied file where the key matches the regular expression
in REGEX.

REGEX - a Perl regular expression like '/[Ff]oo[Bb].r/g'
TAB_FILE - a tab-delimited file that has a key column

EXAMPLE:
    select.pl -k 4 -lte 15  FILE
      Prints all rows from FILE where the 4th column contains a numeric value less than 15
    select.pl -k 2 -lne 'test'  FILE
      Prints all rows from FILE  where the 2nd column does not contain the word 'test'
    select.pl -k 2 -ne  25  FILE
      Prints all rows where the 2nd column is not the numeric value 25 (note how this is different from the example above)

OPTIONS are:

-d DELIM      Set the delimiter to DELIM (default is <tab>)

-h HEADERS    The file contains HEADERS header lines.

-v COL        Change the value column to COL (default is 1 -- the first column).
-k COL
-c COL

-m COLS       Select cells instead of whole rows and match these columns to those
              supplied in the -v option.

-p            Print the values out as well as the cells matched

-not          Select files that do not match REGEX

-op OPERATOR  Set the comparison operator to OPERATOR (default is =~)

NUMERIC OPERATORS (These do NOT work as expected on text, only on numbers)
-gt  (>)      Numerical greater than. Faster way of doing -op '>'
-gte (>=)     Numerical reater than or equal to. Faster way of doing -op '>='
-lt  (<)      Numerical less than (numeric)
-lte (<=)     Numerical less than or equal to (numeric)
-eq  (==)     Test for numerical equality (NOT for strings).
-ne  (!=)     Test for numerical inequality (NOT for strings).

-abs          Test the absolute value of the number.

LEXICAL (TEXT) OPERATORS (these do NOT work as expected on numerical values)
-lgt          Lexical greater-than. Similar to -op 'gt' (this is the lexical greater-than)
-lgte         Lexical greater-than-or-equal-to compare (STRINGS, not numbers)
-llt          Lexical less-than (compares STRINGS, not numbers)
-llte         Lexical less-than-or-equal-to (compare STRINGS, not numbers)
-leq          Test for lexical equality (compare STRINGS)
-lne          Test for lexical inequality (compare STRINGS)

