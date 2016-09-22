#!/usr/bin/perl

use strict;

if($#ARGV<0)
{
   print STDOUT <DATA>;
   exit(1);
}

my $delim = "\t";
my $missing_value = "";
my $kill_missing=0;
my $negation=0;
my %field;
my @field_pattern;
my $f=0;
my @header;
my @header_tmp;
my $num_fields = 0;
my @num_matches;
my @map;
my @map_tmp;
my $i=0;
my $order;
my $value;
my $soft = 0;
my @map_k;
my @header_k;
my $fin = \*STDIN;
while(@ARGV)
  {
    my $arg = shift @ARGV;

    if($arg eq "-f")
      {
        my $arg = shift @ARGV;
        if(-f $arg and open(FILE, $arg))
        {
           while(<FILE>)
           {
              chomp;
              $field{$_} = $f + 1;
              $field_pattern[$f]  = $_;
              $f++;
           }
           close(FILE);
        }
        else
        {
           $field{$arg} = $f+1;
           $field_pattern[$f] = $arg;
           $f++;
        }
      }
    elsif($arg eq "-h" || $arg eq "--help")
      {
        print STDOUT <DATA>;
        exit(0);
      }
    elsif($arg eq "-missing" || $arg eq "-miss")
      {
        $missing_value = shift @ARGV;
      }
    elsif($arg eq "-kill")
      {
        $kill_missing=1;
      }
    elsif($arg eq "-s")
      {
        $soft=1;
      }
    elsif($arg eq "-neg" || $arg eq "-n")
      {
        $negation=1;
      }
    elsif(-f $arg)
    {
       open($fin,$arg) or die("Could not open file '$arg' for reading");
    }
    else
    {
       die("Bad argument '$arg' given");
    }
  }

while(<$fin>)
{
    chop;
    my @record = split(/$delim/);
    if($i==0)
      {
        # Loop through each field in the header and see if it
        # matches one of the user's patterns:
        for(my $k=0; $k<=$#field_pattern; $k++)
          {
            $num_matches[$k]=0;
            for(my $j=0; $j<=$#record; $j++)
              {
                my $field = $record[$j];
                if((not($soft) and
                   ((($field eq $field_pattern[$k])&&($negation==0)) ||
                   (!($field eq $field_pattern[$k])&&($negation==1))))

                 or ($soft and
                   ((($field =~ /$field_pattern[$k]/)&&($negation==0)) ||
                   (!($field =~ /$field_pattern[$k]/)&&($negation==1)) )))
                  {
                    if(length($map[$k])>0)
                      { 
                        $map_tmp[$k] .= ":$j";
                        $header_tmp[$k] .= ":$field";
                      }
                    else
                      { 
                        $map_tmp[$k] = "$j";
                        $header_tmp[$k] = "$field";
                      }
                    $num_fields++;
                    $num_matches[$k]++;
                  }
              }
            if($num_matches[$k]>1)
              {
                print STDERR "Pattern [$field_pattern[$k]] matched $num_matches[$k] times.\n";
              }
          }

        # Determine the order of the fields as specified
        # by the user.
        $order = 0;
        for(my $k=0; $k<=$#field_pattern; $k++)
          {
            @map_k = split(/:/,$map_tmp[$k]);
            @header_k = split(/:/,$header_tmp[$k]);
            while(@map_k)
              {
                $map[$order]    = shift @map_k;
                $header[$order] = shift @header_k;
                $order++;
              }
          }
        # if($num_fields != $order)
        #   {
        #     die("Number of patterns specified ($order) does not equal the number of patterns found ($num_fields).");
        #   }

        for($order=0; $order<$num_fields; $order++)
          {
            $value = $header[$order];
            print "$value";
            if($order < $num_fields-1)
              { print "$delim"; }
          }
        print "\n";
      }
    else
      {
        my $kill_row=0;
        # $tuple="";
        my @tuple;
        for($order=0; $order<$num_fields; $order++)
          {
            $value = $record[$map[$order]];
            if(length($value)==0 && $kill_missing)
              {
                $kill_row=1;
              }
            elsif(length($value)==0)
              {
                $value = $missing_value;
              }
            push(@tuple,$value);
            # $tuple .= $value;
            # if($order < $num_fields-1)
            #   { $tuple .= $delim; }
          }
        if(not($kill_row))
          { print join($delim,@tuple), "\n"; }
      }
    $i++;
}

__DATA__
syntax: project.pl [OPTIONS] -f <field1> [-f <field2> ...] < TAB_FILE

-f FIELD: Select the column with header field FIELD from TAB_FILE
          If FIELD is a file name, it reads in the names of
          the fields from the file (one field on each line).



