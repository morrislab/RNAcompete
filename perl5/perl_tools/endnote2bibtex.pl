#!/usr/bin/perl

##############################################################################
##############################################################################
##
## endnote2bibtex.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: Department of Biomolecular Engineering
##                 Baskin Engineering 129
##                 University of California, Santa Cruz
##                 Santa Cruz, CA 95064
##
##############################################################################

require "libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});

my $file          = $args{'--file'};

my $filep = &openFile($file);

my $all_fields = &parseEndnote($filep);

close($filep);

&makeBibIds($all_fields);

foreach my $fields (@{$all_fields})
{
   &printEndnote($fields);
}

exit(0);

sub parseEndnote
{
   my ($filep) = @_;

   my @all_fields;

   my $fields;

   while(my $line = <$filep>)
   {
      if($line =~ /^\s*Reference\s+Type\s*:\s*(\S.+)\s*$/i)
      {
         my $type = &fixSpacing($1);

         if(defined($fields))
         {
            push(@all_fields, $fields);

            my %fields;

            $fields = \%fields;
         }
         $$fields{'type'} = $type;
      }
      elsif($line =~ /^\s*(\S[^:]+):\s*(\S.+)\s*$/)
      {
         my ($attrib, $val) = ($1, $2);

         $attrib =  &fixSpacing($attrib);

         $attrib =~ tr/A-Z/a-z/;

         $val    = &fixSpacing($val);

         $$fields{$attrib} = $val;
      }
   }

   if(defined($fields))
   {
      push(@all_fields, $fields);
   }

   return \@all_fields;
}

sub makeBibIds
{
   my ($all_fields) = @_;

   my %used;

   for(my $i = 0; $i < scalar(@{$all_fields}); $i++)
   {
      my $fields = $$all_fields[$i];

      if(exists($$fields{'author'}) and exists($$fields{'year'}))
      {
         my @authors = split(';', $$fields{'author'});

         my $year   = $$fields{'year'};

         $year =~ s/^.*(\d\d)\s*$/$1/;

         my $handle = &makeAuthorHandle($authors[0]) .
                      (scalar(@authors) > 1 ?
                       (':' . &makeAuthorHandle($authors[$#authors])) : '') .
                       ':' . $year;

         my $id = $handle;

         $id =~ s/\s//g;

         for(my $j = 2; exists($used{$id}) and $j <= 26; $j++)
         {
            $id = $handle . &getLetter($j);
         }

         if(not(exists($used{$id})))
         {
            $used{$id} = 1;

            $$fields{'id'} = $id;
         }
      }
   }
}

sub getLetter
{
   my ($i) = @_;

   my @letters = ('a','b','c','d','e','f','g','h','i','j','k','l','m',
                  'n','o','p','q','r','s','t','u','v','w','x','y','z');

   return $letters[($i-1)%26];
}

sub makeBibIdsOld
{
   my ($all_fields) = @_;

   my %used;

   for(my $i = 0; $i < scalar(@{$all_fields}); $i++)
   {
      my $fields = $$all_fields[$i];

      my $done = 0;

      for(my $try = 1; (not($done) and $try <= 6); $try++)
      {
         my $id = &makeBibIdFromEndnote($fields, $try);

         if(defined($id) and not(exists($used{$id})))
         {
            $$fields{'id'} = $id;

            $used{$id} = $i;

            $done = 1;
         }
      }

      if(not(exists($$fields{'id'})))
      {
         my $id = undef;

         my $done = 0;

         my $augment = 1;

         for(my $i = 1; not($done); $i++)
         {
            my $id = &makeEndnoteId($fields, -$i);

            if(not(exists($used{$id})))
            {
               $$fields{'id'} = $id;

               $used{$id} = $i;

               $done = 1;
            }
         }
      }
   }
}

sub makeBibIdFromEndnote
{
   my ($fields, $try) = @_;

   my $id = undef;

   if($$fields{'type'} =~ /article/i)
   {
      $id = &makeBibIdFromEndnoteArticle($fields, $try);
   }

   return $id;
}

sub makeBibIdFromEndnoteArticle
{
   my ($fields, $try) = @_;

   my @id;

   if(exists($$fields{'author'}))
   {
      my @authors = split(";", $$fields{'author'});

      if($try =~ /-(\d+)/)
      {
         push(@id, &makeAuthorHandle($authors[0]). $1);
      }

      elsif($try <= scalar(@authors))
      {
         for(my $i = 0; $i < $try; $i++)
         {
            push(@id, &makeAuthorHandle($authors[$i]));
         }
      }
      elsif($try <= 2*scalar(@authors))
      {
         for(my $i = 0; $i < $try; $i += 2)
         {
            push(@id, &makeAuthorHandle($authors[$i], 1));
         }
      }

      my $year = defined($$fields{'year'}) ? $$fields{'year'} : '';

      if($year =~ /(\d\d)\s*$/)
      {
         push(@id, $1);
      }
   }

   my $id = join(':', @id);

   $id =~ s/\s//g;

   return $id;
}

sub makeAuthorHandle
{
   my ($name, $use_initials) = @_;

   $use_initials = defined($use_initials) ? $use_initials : 0;

   my $handle = undef;

   if($name =~ /^\s*([^,]+)/)
   {
      $handle = $1;
   }

   if($use_initials)
   {
      $name =~ s/^\s*([^,]+)//;

      $name =~ s/\s+//g;

      $name =~ s/\.//g;

      $handle .= $name;
   }

   $handle =~ tr/A-Z/a-z/;

   $handle =~ s/[-_]//g;

   return $handle;
}

sub printEndnote
{
   my ($fields, $file) = @_;

   $file = defined($file) ? $file : \*STDOUT;

   if($$fields{'type'} =~ /article/i)
   {
      &printEndnoteArticle($fields, $file);
   }
   elsif($$fields{'type'} =~ /book/i)
   {
      &printEndnoteBook($fields, $file);
   }
}

sub printEndnoteBook
{
   my ($fields, $file) = @_;

   $file = defined($file) ? $file : \*STDOUT;

   if(defined($fields))
   {
      if(exists($$fields{'id'}) and
        (exists($$fields{'author'}) or exists($$fields{'editor'})) and
         exists($$fields{'title'})  and
         exists($$fields{'publisher'}) and
         exists($$fields{'year'}))
      {
         my $authors = exists($$fields{'author'}) ?
                       &parseAuthors($$fields{'author'}) : [];

         my $bib = ""
                   . "\n\t$$fields{'id'}"
                   . ",\n\tTITLE     = {$$fields{'title'}}"
                   . ",\n\tPUBLISHER = {$$fields{'publisher'}}"
                   . ",\n\tYEAR      = {$$fields{'year'}}";

         $bib .= exists($$fields{'author'}) ?
                     ",\n\tAUTHOR    = {" . join(" and ", @{$authors}) . "}" : "";

         $bib .= exists($$fields{'editor'}) ?
                     ",\n\tEDITOR  = {$$fields{'editor'}}" : "";

         $bib .= exists($$fields{'volume'}) ?
                     ",\n\tVOLUME  = {$$fields{'volume'}}" : "";

         $bib .= exists($$fields{'number'}) ?
                     ",\n\tNUMBER  = {$$fields{'number'}}" : "";

         $bib .= exists($$fields{'series'}) ?
                     ",\n\tSERIES   = {$$fields{'series'}}" : "";

         $bib .= exists($$fields{'address'}) ?
                     ",\n\tADDRESS   = {$$fields{'address'}}" : "";

         $bib .= exists($$fields{'edition'}) ?
                     ",\n\tEDITION   = {$$fields{'edition'}}" : "";

         $bib .= exists($$fields{'month'}) ?
                     ",\n\tMONTH   = {$$fields{'month'}}" : "";

         $bib .= exists($$fields{'note'}) ?
                     ",\n\tNOTE   = {$$fields{'note'}}" : "";

         print $file '@BOOK', "\n{", $bib, "\n}\n\n";
      }
   }
}

sub printEndnoteArticle
{
   my ($fields, $file) = @_;

   $file = defined($file) ? $file : \*STDOUT;

   if(defined($fields))
   {
      if(exists($$fields{'id'}) and
         exists($$fields{'author'}) and
         exists($$fields{'title'})  and
         exists($$fields{'journal'}) and
         exists($$fields{'year'}))
      {
         &fixEndnoteArticleFields($fields);

         my $authors = &parseAuthors($$fields{'author'});

         my $bib = ""
                   . "\n\t$$fields{'id'}"
                   . ",\n\tAUTHOR  = {" . join(" and ", @{$authors}) . "}"
                   . ",\n\tTITLE   = {$$fields{'title'}}"
                   . ",\n\tJOURNAL = {$$fields{'journal'}}"
                   . ",\n\tYEAR    = {$$fields{'year'}}";

         $bib .= exists($$fields{'volume'}) ?
                     ",\n\tVOLUME  = {$$fields{'volume'}}" : "";

         $bib .= exists($$fields{'number'}) ?
                     ",\n\tNUMBER  = {$$fields{'number'}}" : "";

         $bib .= exists($$fields{'pages'}) ?
                     ",\n\tPAGES   = {$$fields{'pages'}}" : "";

         $bib .= exists($$fields{'date'}) ?
                     ",\n\tMONTH   = {$$fields{'date'}}" : "";

         print $file '@ARTICLE', "\n{", $bib, "\n}\n\n";
      }
      else
      {
         $verbose and print STDERR "Warning: did not print reference for '",
            exists($$fields{'title'}) ? $$fields{'title'} : $$fields{'id'},
            "' since the ",
            not(exists($$fields{'author'}))   ? "author"  :
            (not(exists($$fields{'title'}))   ? "title"   :
            (not(exists($$fields{'journal'})) ? "journal" :
            (not(exists($$fields{'year'}))    ? "year"    :
            "id"))),
            " did not exist.\n";
      }
   }
}

sub parseAuthors
{
   my ($text) = @_;

   my @authors = split(';', $text);

   for(my $i = 0; $i < scalar(@authors); $i++)
   {
      if($authors[$i] =~ /^\s*([^,]+)\s*,\s(\S.*)$/)
      {
         $authors[$i] = &fixSpacing($2 . ' ' . $1);
      }
   }

   return \@authors;
}

sub fixEndnoteArticleFields
{
   my ($fields) = @_;

   if(defined($fields))
   {
      if(exists($$fields{'pages'}))
      {
         if($$fields{'pages'} =~ /^\s*([\d-]+)/)
         {
            $$fields{'pages'} = $1;
         }
      }
   }
}

sub fixSpacing
{
   my ($text) = @_;

   $text =~ s/^\s+//;

   $text =~ s/\s+$//;

   $text =~ s/(\s)\s+/$1/g;

   return $text;
}

__DATA__
syntax: endnote2bibtex.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)


