#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## xml.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Bioengineering, UCSC
##                 1156 High Street
##                 Santa Cruz, CA 95060
##
##       Web site: http://www.soe.ucsc.edu/~jstuart/
##
##############################################################################
##############################################################################

require "libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;


my @flags   = (
                  [     '-q', 'scalar',     0,     1]
                , ['-msword', 'scalar',     1,     0]
                , [ '--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $msword  = $args{'-msword'};
my $file    = $args{'--file'};

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");

while(my $line = <$filep>)
{
   my $done = 0;

   chomp($line);

   while(not($done))
   {
      my ($beg_tag, $body, $end_tag) = &getSimple(\$line);

      if(defined($beg_tag) and defined($end_tag) and defined($body)
         and $beg_tag =~ /\S/ and $end_tag =~ /\S/)
      {
         print STDOUT $beg_tag, $body, $end_tag, "\n";
      }

      else
      {
         my ($leader, $tag) = &getNextTag(\$line);

         if(defined($tag) and defined($leader) and
            (($tag =~ /\S/) or ($leader =~ /\S/)))
         {
            if($msword and $tag =~ /<o:Revision>/)
            {
            }
            elsif($msword and $tag =~ /<\/o:Revision>/)
            {
               print STDOUT "<o:Revision>",
                            ($leader =~ /\S/ ? $leader : ""),
                            "</o:Revision>\n";
            }
            else
            {
               print STDOUT ($leader =~ /\S/ ? "$leader\n" : ""),
                            ($tag =~ /\S/ ? "$tag\n" : "");
            }
         }
         else
         {
            $done = 1;
         }
      }
   }
}

close($filep);

exit(0);

sub getSimple
{
   my ($text_ref) = @_;

   my ($leader, $beg_tag, $body, $end_tag) = undef;

   if($$text_ref =~ /^([^<]*)(<\s*(\S+)[^>]*>)([^<>]*)(<\s*\1[^>]*>)/)
   {
      $leader  = $1;
      $beg_tag = $2;
      $body    = $3;
      $end_tag = $4;
   }

   return ($leader, $beg_tag, $body, $end_tag);
}

sub getNextTag
{
   my ($text_ref) = @_;

   my ($tag,$leading) = (undef, undef);

   if($$text_ref =~ /^([^<]*)(<[^>]+>)/)
   {
      $leading = $1;
      $tag     = $2;
      $$text_ref =~ s/^([^<]*)(<[^>]+>)//;
   }

   return ($leading, $tag);
}

__DATA__
syntax: xml.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-msword: If set, applies formatting specific to Microsoft Word's
         XML output.

