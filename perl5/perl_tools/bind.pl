#!/usr/bin/perl

use strict;

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libattrib.pl";

my %givens;
my $recursive       = 1;
my $default_file    = undef;
my $template_file   = undef;
my $assignment_file = undef;
my @exes            = ();
my @pipes           = ();
my $max_depth       = -1;
my $depth           = 0;
my $stdin_used      = 0;
my $use_environment = 1;
my $case_sensitive  = 0;
my $detect          = 0;
my $verbose         = 1;
my $xml             = 0;
my $print           = 0;
my $fill            = undef;
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
  elsif($arg eq '-exe')
  {
    push(@exes,shift @ARGV);
  }
  elsif($arg eq '-noexe')
  {
    @exes  = ();
    @pipes = ();
  }
  elsif($arg eq '-pipe')
  {
    push(@pipes,shift @ARGV);
  }
  elsif($arg eq '-xml')
  {
    $xml = 1;
  }
  elsif($arg eq '-print')
  {
    $print = 1;
  }
  elsif($arg eq '-detect')
  {
    $detect = 1;
  }
  elsif($arg eq '-r')
  {
    $recursive = 1;
  }
  elsif($arg eq '-nr')
  {
    $recursive = 0;
  }
  elsif($arg eq '-s')
  {
    $case_sensitive = 1;
  }
  elsif($arg eq '-depth')
  {
    $max_depth = int(shift @ARGV);
  }
  elsif($arg eq '-def')
  {
    $default_file = shift @ARGV;
  }
  elsif($arg eq '-nodef')
  {
    $default_file = '';
  }
  elsif($arg eq '-noenv')
  {
    $use_environment = 0;
  }
  elsif($arg eq '-fill')
  {
    $fill = shift @ARGV;
  }
  elsif(not(defined($template_file)) and ((-f $arg) or ($arg eq '-')))
  {
    $template_file = $arg;
  }
  elsif((-f $arg) or ($arg eq '-'))
  {
    my $assignments = &readAttribLines(&getFileText($arg));
    foreach my $attrib (keys(%{$assignments}))
    {
      my $val = $$assignments{$attrib};
      $givens{$attrib} = $val;
    }
  }
  elsif($arg =~ /([^=]+)=(.*)/)
  {
    my ($attrib,$val) = ($1,$2);
    $givens{$attrib} = $val;
  }
  else
  {
    die("Invalid argument '$arg'.");
  }
}

if(not(defined($default_file)))
{
  if($default_file eq '-')
  {
    $default_file = '';
    $stdin_used = 1;
  }
  # else
  # {
  #   $default_file = &remPathExt($template_file) . '.att';
  #   $default_file = (-f $default_file) ? $default_file : '';
  # }
}

my $defaults = defined($default_file) ? &readAttribLines(&getFileText($default_file)) : {};

my $file;
my $dir;
if($template_file eq '-')
{
  $file = \*STDIN;
  $dir  = `pwd`; chomp($dir);
  $stdin_used = 1;
}
elsif(-f $template_file)
{
  open($file,$template_file) or die("Could not open template file '$template_file'.");
  $dir  = &getPathPrefix($template_file);
}
elsif(not(defined($template_file)) and not($stdin_used))
{
  $file = \*STDIN;
  $dir  = `pwd`; chomp($dir);
  $stdin_used = 1;
}
else
{
  die("Please supply a template file.");
}

my @template = <$file>;
my $template = join('',@template);
close($file);

# Extract defaults from detecting attribute=value pairs in the
# template itself.
# if($detect)
# {
#   my $detected = &readAttribText($template);
# }

# Environment variables
my %environment;
if($use_environment)
{
  foreach my $attrib (keys(%ENV))
    {
	  $environment{$attrib} = $ENV{$attrib};
	}
}

if(not($case_sensitive))
{
  &upperCaseAttribs(\%givens);
  &upperCaseAttribs($defaults);
  &upperCaseAttribs(\%environment);
}

my %attributes = %environment;
&replaceAttribs(\%attributes,$defaults);
&replaceAttribs(\%attributes,\%givens);

# Bind the variables
$template = &bindAttribs($template,\%attributes,$recursive,$max_depth,
                         $case_sensitive,$dir);



# Remove any unpreprocessed commands.  Also, take
# out any #[...]# blocks.
$template = &postProcessTemplate($template);

if(defined($fill))
{
  $template = &setAllAttribs($template,$fill);
}

# Report any unbound attributes
my %unbound_attributes = &getUnboundAttributes($template);
if($verbose and scalar(keys(%unbound_attributes))>=0)
{
  foreach my $unbound (sort(keys(%unbound_attributes)))
  {
    print STDERR "bind.pl: !!!!!!!!!! WARNING: attribute '$unbound' remains unbound!\n"
  }
}

# Execute command(s) on the resulting bound template
foreach my $exe (@exes)
{
  my $file = '/tmp/bind_tmp_' . time;
  open(FILE,">$file");
  print FILE $template;
  close(FILE);
  system("$exe $file");
  system("rm -f $file");
}

foreach my $pipe (@pipes)
{
  open(PIPE, "| $pipe |") or die("Failed to open pipe '$pipe'.");
  print PIPE $template;
  close(PIPE);
}

$print = $print ? 1 : ($#exes==-1 and $#pipes==-1);
if($print)
{
  if($xml)
  {
    open(PIPE, "| format_xml.pl |");
    print PIPE $template;
    close(PIPE);
  }
  else
  {
    print "$template";
  }
}

exit(0);

__DATA__
syntax: bind.pl [OPTIONS] TEMPLATE [ASSIGNMENT_FILE1 ...] [VAR1=VAL1 VAR2=VAL2 ...]

Fills in the variables in the template file with the bound variables supplied.  Any variables
named $(VAR1) (i.e within $()) in the template file are set to VAL1 and the result printed
to standard output.

Appears to also collapse blank lines down into nothingness. This can be a problem
if you use it on a makefile with a continuation at the end of a line (\) and expect
the whitespace after it to make the continuation irrelevant.

Example usage:

# If you have a file with this text:      Today is $(DAY) in $(YEAR).
# And you run the following command:      bind.pl day="a good day" Year=2008
# The result will be:                     Today is a good day in 2008.
# (Note that capitalization does not matter.)

# If you have the text:     Annoying marks are $(quote1) and $(QUOTE2)
# And you run the command   bind.pl  quote1="'" quote2='"'
# The result will be:       Annoying marks are ' and "

# It appears to also remove comments, or anything after the # symbol

So if you want to use a quotation mark or double quote anywhere in a binding,
you must use the *other* type of mark to surround the symbol.

CAVEATS:

   1. You must NOT have spaces around a binding. So   bind.pl day = FRIDAY   will give a cryptic error.
      (It should be   bind.pl day=FRIDAY  ).

   2. All comments or other instances of '#' are stripped out. This means if you have something like
      HTML_COLOR="#FF0099", those lines will be malformed! 
      THIS IS A HUGE CAVEAT IF YOU USE "R" or HTML or anything else that uses '#' for something other than comments!.

   3. Newlines are stripped out. So if a line ends with a ' \ ' continuation, and the next line is blank,
      when bind.pl strips out that blank line, you will be very unhappy!

   4. There is seemingly no way to mix both single quotes AND double quotes in a single variable passed
      in to bind.pl.


TEMPLATE - File containing a variables of the form $(VARIABLE).  If '-' is supplied,
           reads the template from standard input.

ASSIGNMENT_FILEi - If supplied lists variable=value pairs.  If '-' is supplied,
                   the script reads variable=value pairs from standard input.  Multiple
                   assignment files are allowed.

VARi=VALi - Replace the variable VARi with the value VALi in the template file. Note
            that there CANNOT be spaces around the equals sign.

OPTIONS are:

-def DEFAULT_FILE: Unbound variables in the template will be filled in by the values in
                   the default file DEFAULT_FILE.

-depth DEPTH: Set the maximum recursion depth to DEPTH (default is infinite).  Setting to -1
              tells the script to perform infinite-depth recursion.

                ** -detect not implemented yet **
-detect: Tell the script to "detect" variables in the template file.

-exe COMMAND: Execute the command COMMAND on the resulting bound file.  When this
              option is used a temporary file is created and the file is passed
              into the COMMAND as one of its arguments.  The default prints the
              resulting bound file to standard output.  Multiple -exe options can
              be supplied.  The commands are executed in the order given.

-fill FILLER: If any variables are unbound in the final document then set them all to FILLER.

-nodef: Tell the script to ignore variable assignments in any default file.
        Use this option when a default file for the template exists and you do not wish to
        fill in the default values.

-noenv: Ignore environment variables (default uses them).

-noexe: Removes any previous -exe and -pipe option(s).

-nr: Non-recursive (default is recursive).  Do not expand values of attributes that are also
     attribute names.

-pipe COMMAND: Same as the -exe option only the resulting file with bound variables is
               passed to the commands standard input.

-print: Print the resulting template to standard output even if -exe or -pipe was
        supplied.

-q: Quiet mode (suppress warnings and information).

-s: Use case-sensitive matching on variable names (default is case-insensitive).

-r: Recursively apply bindings (default).  I.e. if variable names are the result of one
    application of the values then it will be replaced by the value assigned to a variable
    of that name in the next round of substitution.  For example if the variable $($(FOO))
    exists in the template file and FOO=BAR and BAR=10 then the result of recursive binding
    will replace $($(FOO)) with 10 while non-recursive would yield $(BAR).

-xml: Tell the script the document is XML so can print more pretty output.


