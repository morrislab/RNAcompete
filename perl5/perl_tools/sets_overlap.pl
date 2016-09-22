#!/usr/bin/perl

##############################################################################
##############################################################################
##
## sets_overlap.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart in the lab of Stuart Kim, Stanford University.
##
##  Email address: jstuart@stanford.edu
##          Phone: (650) 725-7612
##
##       Web site: http://www.smi.stanford.edu/people/stuart
##
##############################################################################
##############################################################################
##
## Written: 00/00/02
## Updated: 00/00/02
##
##############################################################################
##############################################################################

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;
use warnings;

use Getopt::Long;

# Flush output to STDOUT immediately.
$| = 1;

my $defaultLogEpsilon = -0.01;
my $defaultOutputDelimiter = ','; # <-- note! this is unusual, typically our programs use tab for output, but sets_overlap.pl uses commas!


my @flags   = (
	         [     '-q', 'scalar',      0,     1]
	       , [     '-U', 'scalar',  undef, undef]
	       , [    '-UT', 'scalar',  undef, undef]
	       , [    '-UG', 'scalar',  undef, undef]
	       , [     '-N', 'scalar',  undef, undef]
	       , [     '-I', 'scalar',      0,     1]
	       , [     '-G', 'scalar',      0,     1]
	       , [     '-T', 'scalar',      0,     1]
	       , [     '-M', 'scalar',  undef, undef]
	       , [    '-kg', 'scalar',      1, undef]
	       , [    '-kt', 'scalar',      1, undef]
	       , [    '-do', 'scalar', $defaultOutputDelimiter, undef]
	       , [    '-dot','scalar',      0,     1]
	       , [    '-dg', 'scalar',   "\t", undef]
	       , [    '-dt', 'scalar',   "\t", undef]
	       , [    '-hg', 'scalar',      0, undef]
	       , [    '-ht', 'scalar',      0, undef]
	       , [    '-mg', 'scalar',      0,     1]
	       , [    '-mt', 'scalar',      0,     1]
	       , [    '-no', 'scalar',      0,     1]
	       , [    '-ig', 'scalar',      0,     1]
	       , [    '-it', 'scalar',      0,     1]
	       , [   '-eps', 'scalar', $defaultLogEpsilon, undef]
	       , ['-ignore',   'list',     [], undef]
	       , [     '-p', 'scalar',   0.05, undef]
	       , ['-noself', 'scalar',      0,     1]
	       , [    '-sf', 'scalar',      4, undef]
	       , [     '-o', 'scalar','stats', undef]
	       , [ '--file',   'list',  ['-'], undef]
	       );

my $STORE_EXTRA_DO_NOT_QUIT_ON_UNRECOGNIZED_ARGUMENT = 1; # <-- 1 or 0
my %args = %{&parseArgs(\@ARGV, \@flags, $STORE_EXTRA_DO_NOT_QUIT_ON_UNRECOGNIZED_ARGUMENT)};

my $individualUniverseFile = undef;

# IMPORTANT: Note that GetOptions CONSUMES @ARGV--you CAN'T use it afterward)!
# Thus, you MUST use it before, if you're going to use it!
# More info about GetOptions: http://www.perl.com/doc/manual/html/lib/Getopt/Long.html
Getopt::Long::Configure(qw(pass_through)); # pass_through: "Don't flag options we don't process as errors"
GetOptions("help|man|?", sub { print STDOUT <DATA>; exit(0); }
	   , "iu|individual_universe:s", \$individualUniverseFile
	   );

# For some reason, GetOptions was setting $individualUniverseFile to '' instead of undef
# even when no arguments were provided. This produced an error below.
if(defined($individualUniverseFile) and $individualUniverseFile !~ /\s/) {
   $individualUniverseFile = undef;
}

if (defined($individualUniverseFile)) {
	print STDERR "i=[$individualUniverseFile]\n";
}

if ($args{'-p'} <= 0 || $args{'-p'} > 1) { # p value must be in (0,1]
  die "The specified p-value (-p VALUE option) was invalid! The valid range is (0,1].\n
-p 1 means display all results (since everything is p <= 1.0).\n
Lower p-values indicate more stringent cutoffs. The default is -p 0.05.\n";
}

my $verbose        = not($args{'-q'});
my $univ_file      = $args{'-U'}; # UNIVERSE of items from which both the test and gold were drawn
my $univ_test_file = $args{'-UT'}; # UNIVERSE of items from which the test sets were drawn
my $univ_gold_file = $args{'-UG'}; # UNIVERSE of items from which the gold sets were drawn
my $N              = $args{'-N'};
my $I              = $args{'-I'};
my $G              = $args{'-G'};
my $T              = $args{'-T'};
my $max_gold       = $args{'-M'};
my $key_col_gold   = $args{'-kg'} - 1;
my $key_col_test   = $args{'-kt'} - 1;
my $delim_out      = $args{'-do'};
if ($args{'-dot'}) {
  if ($args{'-do'} ne $defaultOutputDelimiter) { die "
*** Argument error to sets_overlap: You cannot specify both the -do *and* -dot options.
*** (-dot is a synonym for  -do '	' , where there is a tab between those single quotes)
*** You should remove either  -do DELIM  or  -dot  from the command line.
*** Note that -do DELIM requires an argument, whereas -dot does not.\n"; }
  $delim_out = "\t";
}
my $delim_gold     = $args{'-dg'};
my $delim_test     = $args{'-dt'};
my $headers_gold   = $args{'-hg'};
my $headers_test   = $args{'-ht'};
my $matrix_gold    = $args{'-mg'};
my $matrix_test    = $args{'-mt'};
my $negateOutputPvalue = $args{'-no'}; # <-- means that POSITIVE values are better (negates the output)
my $invert_gold        = $args{'-ig'};
my $invert_test        = $args{'-it'};
my $output_type        = $args{'-o'};
my @ignore_files    = @{$args{'-ignore'}};
my $pval_cut        = log($args{'-p'}) / log(10); # p-value cutoff (note that we convert to log_BASE_10--default Perl log is actually "ln")
my $noself          = $args{'-noself'};
my $numSigFigs      = $args{'-sf'};
my $log_epsilon     = $args{'-eps'};
my @files           = @{$args{'--file'}};

my $universe      = undef;
my $universe_test = undef;
my $universe_gold = undef;

if (scalar(@files) != 2) {
  die("
*** sets_overlap argument error: Please supply two input files!
***
*** Note that this error can also arise if you specified an option that requires
*** a value, but you did not supply a value. For example, if you had:
*** sets_overlap.pl -1 1 -2 FILE1 FILE2
***                       (-2 requires an argument, and in this case, FILE1 will
***                        be consumed as the arguemnt to -2)
*** What you might have actually wanted was sets_overlap.pl -1 1 -2 1 FILE1 FILE2.
*** So beware of your input filenames being consumed as variable assignments!\n\n");
}

my $goldSetFilename = $files[0]; # The "gold" sets (usually much larger than the test set, although this is not necessary) that each test set item gets compared against. GO categories are often the GOLD set.
my $testSetFilename = $files[1]; # The sets you are testing to see how much overlap it has with other things

$verbose and print STDERR "Reading in the gold-standard classification.\n";
my $gold = &setsReadLists($goldSetFilename, $delim_gold, $key_col_gold,
                          $headers_gold, undef, undef, $invert_gold);
my $num_gold = &setSize($gold);
$verbose and print STDERR "Done ($num_gold sets read).\n";


my @testSetKeysInFileOrder = (); # The test sets in the SAME order that we found them in the file

$verbose and print STDERR "Reading in the test classification.\n";
my $test = &setsReadLists($testSetFilename, $delim_test, $key_col_test,
                          $headers_test, \@testSetKeysInFileOrder, undef, $invert_test);

#print @testSetKeysInFileOrder;

my $num_test = &setSize($test);
$verbose and print STDERR "Done ($num_test sets read).\n";

my %individualUniverse = (defined($individualUniverseFile)) ? readIndividualUniverse() : ();

# If the universe file is specified, and it's a file...
# Could also have been supplied as standard input.
if(defined($univ_file) and ((-f $univ_file) or (-l $univ_file)))
{
    $verbose and print STDERR "Reading in the universe from '$univ_file'.\n";
    $universe = &setRead($univ_file);
    print STDERR "\nDone reading in the universe from '$univ_file'.\n";
}

# Read in a universe for the TEST sets.
if(defined($univ_test_file) and ((-f $univ_test_file) or (-l $univ_test_file))) {
    if(not(defined($universe))) {
	$verbose and print STDERR "Reading in the TEST universe from '$univ_test_file'.\n";
	$universe_test = &setRead($univ_test_file);
	print STDERR "\nDone reading in the TEST universe from '$univ_test_file'.\n";
    }
    else {
	  die("Erroneous use of -UT option, since a universe for both GOLD and TEST was set.");
    }
}

# Read in a universe for the GOLD sets.
if(defined($univ_gold_file) and ((-f $univ_gold_file) or (-l $univ_gold_file))) {
    if(not(defined($universe))) {
	$verbose and print STDERR "Reading in the GOLD universe from '$univ_gold_file'.\n";
	$universe_gold = &setRead($univ_gold_file);
	print STDERR "\nDone reading in the GOLD universe from '$univ_gold_file'.\n";
    }
    else {
	  die("Erroneous use of -UG option since a universe for both GOLD and TEST was set.");
    }
}

# If we don't have a universe for the TEST set, set it to either the common universe for both
# GOLD and TEST or, if that's not defined, the union of all the TEST sets.
if(not(defined($universe_test))) {
    $universe_test = defined($universe) ? $universe : &setsUnionSelf($test);
}
$verbose and print STDERR "The TEST universe has ", &setSize($universe_test), " members.\n";

# If we don't have a universe for the GOLD set, set it to either the common universe for both
# GOLD and TEST or, if that's not defined, the union of all the GOLD sets.
if(not(defined($universe_gold))) {
    $universe_gold = defined($universe) ? $universe : &setsUnionSelf($gold);
}
$verbose and print STDERR "The GOLD universe has ", &setSize($universe_gold), " members.\n";

if(not(defined($universe))) {
    # The user has requested the universe be constructed from the intersection
    # of the TEST and GOLD universes.
    if($I) {
	$verbose and print STDERR "Setting the common universe to the intersection of the TEST and GOLD universes.\n";
	$universe = &setIntersection($universe_test, $universe_gold);
	$verbose and print STDERR "Done setting the common universe to the intersection of the TEST and GOLD universes.\n";
    }
    elsif($G) {
	$verbose and print STDERR "Setting the common universe to the GOLD universe.\n";
	$universe = $universe_gold;
	$verbose and print STDERR "Done setting the common universe to the GOLD universe.\n";
    }
    elsif($T) {
	$verbose and print STDERR "Setting the common universe to the TEST universe.\n";
	$universe = $universe_test;
	$verbose and print STDERR "Done setting the common universe to the TEST universe.\n";
    }
    else {
	$verbose and print STDERR "Setting the universe to the union of the TEST and GOLD universes.\n";
	$universe = &setUnion($universe_test, $universe_gold);
	$verbose and print STDERR "Done setting the universe to the union of the TEST and GOLD universes.\n";
    }
}
$verbose and print STDERR "The common universe has ", &setSize($universe), " member(s).\n";
$verbose and print STDERR "The cutoff for displaying results was p = ", $args{'-p'}, ".\n";
if ($args{'-p'} == 1) {
  $verbose and print STDERR "(Since -p == 1, we are displaying all overlap results, even where there was no overlap.)\n";
}


# For consistency, remove any items from the TEST universe that aren't in the common universe.
$universe_test = &setIntersection($universe_test, $universe);

# For consistency, remove any items from the GOlD universe that aren't in the common universe.
$universe_gold = &setIntersection($universe_gold, $universe);

# For consistency, remove any items from the TEST sets that are not in its universe.
$test = &setsReduceBySet($test, $universe_test);

# For consistency, remove any items from the GOLD sets that are not in its universe.
$gold = &setsReduceBySet($gold, $universe_gold);

$N     = defined($N) ? $N : &setSize($universe);
my $NT = &setSize($universe_test);
my $NG = &setSize($universe_gold);
$verbose and print STDERR "Common universe size = $N; TEST universe size = $NT, GOLD universe size = $NG.\n";

foreach my $ignore_file (@ignore_files) {
    open(IGNORE, $ignore_file) or die("*** Could not open ignore file '$ignore_file'\n\n");
    while(<IGNORE>) {
	chomp;
	delete($$gold{$_});
    }
    close(IGNORE);
}

if(defined($max_gold)) {
    if($max_gold > 0 and $max_gold < 1) {
	$max_gold = int($N * $max_gold);
    }

    foreach my $key_gold (keys(%{$gold})) {
	my $size = &setSize($$gold{$key_gold});
	if($size > $max_gold) {
	    $verbose and print STDERR "Removing gold set '$key_gold'--it has more members than the max ($size > $max_gold).\n";
	    delete($$gold{$key_gold});
	}
    }
}

my $passify = 100;
my $iter = 0;
my $total = $num_test * $num_gold;

# Let's go through each key and print things that it had overlap with.
# The key will be printed with a > in front, in a FASTA-like format)
foreach my $testSetKeyName (@testSetKeysInFileOrder) {

	# The line above used to be : (@{&setMembersList($test)})  instead of @testSetKeysInFileOrder
  
  next if (!exists($$test{$testSetKeyName})); # handles the problem of blanks and other disqualified keys
  
  my $set_test = $$test{$testSetKeyName};
  $verbose and print STDERR "Overlapping $testSetKeyName with GOLD.\n";
  
  my $results;
    
    if (defined($individualUniverseFile) &&
		exists($individualUniverse{$testSetKeyName}) && defined($individualUniverse{$testSetKeyName})) {
	    # individualUniverseFile means that *EACH* entry has its own universe specified.
		# Check the <DATA> info at the bottom of the file for specifics on the format of the individual universe file.
		
		# Note that if an element just doesn't appear in this -IU file at all, we use the default set universe
		# calculations. Thus it is possible to have both -IU and also specify a "default" target universe.
		
		my @x_tmp = keys(%{$individualUniverse{$testSetKeyName}});
		my $thisIndividualUniverseSet = &list2Set(\@x_tmp);
		my $culledTest = &setIntersection($set_test, $thisIndividualUniverseSet);
		my $culledGold = &setsReduceBySet($gold, $thisIndividualUniverseSet);
		#print "\nITEMS IN THE TEST SET FOR KEY $testSetKeyName:\n";
		#&setPrint($set_test);
		#print STDERR "\nTHIS INDIVIDUAL UNIVERSE SET:\n"; &setPrint($thisIndividualUniverseSet); print STDERR "\n\n";
		#print STDERR "\nTEST:\n"; &setPrint($test);
		#print STDERR "\nGOLD:\n"; &setPrint($gold);
		#print STDERR "\nCULLED TEST SET:\n"; &setPrint($culledTest); print STDERR "\n\n";
		#print STDERR "\nCULLED GOLD SET:\n"; &setPrint($culledGold); print STDERR "\n\n";
		
		my $culled_N = &setSize($thisIndividualUniverseSet);
		$results = &setsOverlap($culledTest, $culledGold, $culled_N, $pval_cut, 1);
    }
    else {
		$results = &setsOverlap($set_test, $gold, $N, $pval_cut, 1);
    }
	
    if ($output_type eq 'stats') {
	  # THIS IS THE FINAL PROGRAM OUTPUT AREA FOR the "stats" mode (which is the one we most commonly use)
		print STDOUT ">$testSetKeyName\n";
		foreach my $result (@{$results}) {
			my ($key_gold, $lpval, $ov, $draw, $suc, $pop, $intersection) = @{$result};
			
			if($lpval >= $log_epsilon) {
				$lpval = 0; # If the log_10-pvalue is bigger than the cutoff, set it to 0.
			}
			if(not($noself) or ($key_gold ne $testSetKeyName)) {
				my $lpvalToPrint = ($negateOutputPvalue) ? (-$lpval) : $lpval;
				print STDOUT $key_gold
					, $delim_out, &format_number($lpvalToPrint, $numSigFigs)
					, $delim_out, $ov
					, $delim_out, $draw
					, $delim_out, $suc
					, $delim_out, $pop
					, "\n";
			}
		}
		
		if($verbose) {
			my $found_best = 0;
			for(my $i = 0; $i < @{$results} and not($found_best); $i++) {
				if(defined($$results[$i])) {
					my ($key_gold,$pval,$o,$d,$s,$pop) = @{$$results[$i]};
					if(not($noself) or ($key_gold ne $testSetKeyName)) {
						my ($pvp) = ($negateOutputPvalue) ? (-$pval) : $pval;
						print STDERR "$testSetKeyName -> $key_gold ($pvp : $o,$d,$s,$pop)\n";
						$found_best = 1;
					}
				}
			}
			if(not($found_best)) {
				print STDERR "TEST set \"$testSetKeyName\" has no significant overlap with any GOLD set.\n";
			}
		}
    }
    elsif($output_type eq 'members' or $output_type eq 'mems') {
	  # THIS IS THE FINAL PROGRAM OUTPUT AREA FOR the "members" mode (which is the one we use less frequently)
		my $unused = undef;
		foreach my $result (@{$results}) {
			my ($key_gold,@stats) = @{$result};
			if(not($noself) or ($key_gold ne $testSetKeyName)) {
				&printCommonMembers($testSetKeyName, $key_gold, $test, $gold, \$unused, $delim_gold, \*STDOUT);
			}
		}
		foreach my $member (keys(%{$unused})) {
			print STDOUT $member, $delim_gold, $testSetKeyName, $delim_gold, "NaN\n";
		}
    }
}

if (0 == scalar(@testSetKeysInFileOrder)) {
  print STDOUT "\n"; # make sure file ends with a newline
}

exit(0);

# ======= END OF MAIN CODE AREA ========


# ========== SUBROUTINES BELOW =========



sub printCommonMembers {
    my ($keya,$keyb,$A,$B,$unused,$delim,$fp) = @_;
    my $setA = $$A{$keya};
    my $setB = $$B{$keyb};

    $$unused = defined($$unused) ? $$unused : &setCopy($setA);

    foreach my $a (@{&setMembersList($setA)}) {
	if(exists($$$unused{$a})) {
	    if(exists($$setB{$a})) {
		print $fp $a, $delim, $keya, $delim, $keyb, "\n";
		delete($$$unused{$a});
	    }
	}
    }
}

sub readIndividualUniverse {
    # Individual universe file format is specified in the <DATA> below.
    # Note that typically various items share the same universe. It is unlikely that we have
    # a unique universe for each element (although here we obviously have more than one "universe" of
    # elements for various items, or else we wouldn't have the "individual" universes in the first
    # place).
    # One possible optimization for this function would be to read a *FILE* specifying each universe,
    # rather than writing out the entire universe on each line. Nevertheless, even a 500 x 5000 x 10 bytes
    # file is "only" 25 MB, so it's probably not incredibly critical to change this immediately.

    my %returnIndividualUniverse = ();
    my $numElemsRead = 0;
    $verbose and print STDERR "Reading in the individual per-element universe file ($individualUniverseFile)...\n";
    open(F, "< $individualUniverseFile") or die "*** Error opening the individual universe file \"$individualUniverseFile\"!
Make sure that this file exists and is readable by the current user.\n"; {
	foreach my $line (<F>) {
	    chomp($line);
	    my @elems = split(/\t/, $line);
	    # The first "elem" is the key, telling us WHOSE universe this is
	    # All the rest are the actual items that are in this elem's set of tested items.
	    my $whoseUniverse = (scalar(@elems) >= 1) ? $elems[0] : undef;
	    for (my $i = 1; $i < scalar(@elems); $i++) {
		$returnIndividualUniverse{$whoseUniverse}{$elems[$i]} = 1;
		$numElemsRead++;
		#$verbose and print STDERR "Individual universe for " . $elems[0] . ": " . $elems[$i] . "\n";
	    }
	}
    } close(F) or die "*** Error closing individual universe file.\n";
    $verbose and print STDERR "Done reading in the individual per-element universe file ($individualUniverseFile).\n";

    if ($numElemsRead <= 0) {
		print STDERR "sets_overlap.pl: WARNING: The individual universe (-IU) file was specified,
 but there weren\'t any actual elements for the entries (if any) in it.\nThis could be intentional, but is more likely an error.\n";
    }

    return %returnIndividualUniverse;
}


__DATA__
syntax: sets_overlap.pl -p CUTOFF  [OPTIONS]  GOLD_SET TEST_SET

    GOLD - Gold-standard classification set

    TEST - Test classification set

Calculates similarity between sets. Uses the hypergeometric calculation for p-values, which are reported
as log10(p_value) for each test/gold pair.

EXAMPLE USAGE SCENARIO (i.e., "what is sets_overlap.pl for?"):

You use sets_overlap.pl when you want to see if a list of things is likely to belong to a particular
set. For example, if you had a test set of genes:

EXPERIMENT_1_SET    alphaGene     gammaGene     omegaGene     betaGene     epsilonGene

and you wanted to know if those genes had some function in common, you could overlap it with the
"gold standard" functional set:

Mitosis_Genes       gammaGene  omegaGene   betaGene    muGene   epsilonGene   alphaGene
DNA_Repair_Genes    geneZ      geneY       alphaGene

sets_overlap could tell you that your set seemed likely to be involved in Mitosis (and not so much in
DNA repair).

The command to run the above example (assuming you made the proper files) would be:
   sets_overlap.pl  -p 1  Experiement_1_Set_File.name   Functional_Set_File.name  > OUTPUT.file


CAVEATS:
    By default, NOT ALL RESULTS ARE PRINTED. Only p-values better than the cutoff (0.05) are reported.
    Specify "-p 1" (cutoff of P = 1.0) to print ALL results.
    (Specifiy -p 0.9999 to print the results that have any overlap at all.)

    In the output file, p-values are reported as log_base_10(p_value). Thus,
    1.0 is the worst ("no significance") and more-negative numbers are more significant. You can
    reverse this with -no (negate output).

    Note that significance only reports if something has significantly MORE overlap than expected.
    We do *NOT* detect a sets with significant UNDERrepresentation (they just have bad p-values)

    You can use the program "fasta2single_line.pl" to process the
    output of sets_overlap.pl and make it easier to sort the results or put them in a spreadsheet.
    Here is how you do it:
       sets_overlap.pl -dot OTHER_PARAMETERS | fasta2single_line.pl > OUTPUT_FILE

    It will turn this:
       >Set1
       Guy1,142,42,13
       Guy2,42,11,22

    Into this:
       Set1     Guy1,142,42,13
       Set1     Guy2,42,11,22

    Also consider using -dot (tab-delimit the output) in order to get an easily-"cut.pl"-able result.
    The default output delimiter is a comma (which is troublesome if set names contain commas).

OPTIONS:

    -q: Quiet mode (default is verbose)

    -no: (Negate output)   (default: OFF)
    Negate output value: bigger numbers are better if this option is specified.
	Normally the score value printed is the log10(pvalue). With this option,
	it is the NEGATIVE log10(pvalue). The worst score is still 0. A score of
	2 now means P = 0.01.

    -U UNIVERSE: Set the universe of elements to UNIVERSE.  UNIVERSE should be
    a file containing a list of members, with a single member on each
    line. This option overrides the -UT or the -UG option (see below).

    -UT UNIVERSE: Same as the -U option only specifies the universe from which the
    TEST sets were drawn. By default, the union of all TEST sets is
    used as the TEST universe.

    -UG UNIVERSE: Same as the -U option only specifies the universe from which the
    GOLD sets were drawn. By default, the union of all GOLD sets is
    used as the GOLD universe.

    --IU=FILE | --individual_universe=FILE : An "individual universe" file that
    specifies a separate universe of items to consider for each item in the test
    set.
    Note: if you specify -IU, you MUST use the equals sign to specify the file.
    ("--IU file" will NOT work, but --IU=file WILL work)
    The format is:   ELEMENT <tab> UNIV_ITEM_1 <tab> UNIV_ITEM_2 <tab> etc...
    This feature is useful in situations where one gene was tested against a
    large panel, but others were only tested against a small panel. We do not
    want to penalize the small-panel genes for not being tested in many conditions,
    nor do we want to re-run sets_overlap with a different universe file for
    each entry.
    Sample file, with ITEM_B tested more thoroughly than ITEM_A:
      ITEM_A <tab> 1 <tab> 2 <tab> 3
      ITEM_B <tab> 1 <tab> 2 <tab> 3 <tab> 4 <tab> 5

    Note that any entries that do not appear in the -IU file simply use the
    default universe calculations (as if you had not specified -IU=FILENAME at all).
    Thus it is possible to have both -IU and also -U/UG/UT.

    -N NUM: Set the population size to NUM. Overrides the default, which is to
    simply count the number of items in the universe. Note: the N specified here
    is superseded by the count in the -IU (individual universe) file, if you
    specify one.

    -I: Use the intersection of the GOLD universe with the TEST universe
    for the population size (default uses the union). Use this option if
    you do not want to penalize a test set from drawing members that were
    not in the GOLD universe, and on the other hand, if you do not want to
    include members of GOLD sets that do not appear in the TEST universe.

    -G: Use the GOLD universe as the common universe. The -I flag supercedes
    this option.

    -T: Use the TEST universe as the common universe. The -I and -G
    flags supercede this flag.

    -M MAX: Set the maximum size used for the GOLD.  Any
    GOLD set that is larger will be ignored.  If MAX is
    a value between 0 and 1 then it is interpreted as a
    fraction of the population size.

    -kg COL: Set the key column to COL (default is 1).

    -kt COL: Same as -kg but for the TEST file.

    -do DELIM: Set the output delimiter of the stats to DELIM (default is a comma).

    -dot (with no argument): Sets the output delimiter to a tab (default is a comma)
        Can be accomplished with "-do '	'" as well. This option is occasionally
        useful, since tabs frequently get clobbered when copying and pasting.

    -dg DELIM: Set the field delimiter for the GOLD set to DELIM (default is tab).

    -dt DELIM: Same as -dg but for the TEST file.

    -hg HEADERS: Set the number of header lines to HEADERS (default is 0).

    -ht HEADERS: Same as -hg but for the TEST file.

    -mg: The GOLD classification is in matrix format (default is list format)

    -mt: Same as -mg but for the TEST file.

    -ig: The GOLD file contains an inverted listing with members down the first
    column and sets across. Saves you from having to modify the lists
	using sets.pl (which is how you would deal with this otherwise).

    -it: Same as -ig but for the TEST file.

    -ignore FILE: Supply a list of sets to ignore in the TILING.

    -p PVAL: Supply a p-value cutoff (default is -p 0.05, which only reports overlap
      with P-values of 0.05 or lower (better). (Note that this is about -1.3 in log10(p) terms.)

    -noself: Do not compare sets that have the same name. Useful for when GOLD=TEST.

    -sf SIGFIGS: Set the number of significant figures for reporting P-values to
    SIGFIGS (default is 4).

    -o OUTPUT_TYPE: Specify whether to print the statistics of the overlaps out ('stats')
    to print the members with their category assignments in the significantly
    overlapping categories ('members').  By default this is set to 'stats'.

EXAMPLE:

    If example set file A consists of (tab-delimited):
    Group1  1       2       3       5
    Group2  2       4       6

    And example set file B consists of (tab-delimited):
    ODD     1       3       5       7       9
    EVEN    2       4       6       8

    Then "sets_overlap.pl B A -p 1" will give you:

    >Group1
    ODD,-0.447158031342433,3,4,5,9
    EVEN,-0.191885526238794,1,4,4,9
    >Group2
    EVEN,-1.32221929473412,3,3,4,9
    ODD,0,0,3,5,9

    Note that B is the "GOLD-standard" file (ODD & EVEN), whereas A is the "test" file of
    unknown groups. The order in which the files are specified is significant!

    The sets are always printed in the same order that they are found in the test (second) file.

    From the results, we see that, for
    example, Group2 is more simliar to EVEN than ODD.
    It has 3/3 overlap with the elements in EVEN,
    giving it a log-base-10 p-value of -1.322.

    For Group1, the line "ODD,-0.447,3,4,5,9" means:
    N ,  A   ,B,C,D,E

  N: Name of this set (the second set)
  A: Score
  B: Overlap between sets
  C: Num elements in first set
  D: Num elements in second set (the set "N")
  E: Total number of unique elements (union of 1st and 2nd sets)

  More details:
    A. The log_10(p-value) of at least this amount of overlap
    between the two sets ODD and Group1 is -0.447.
    B. 3 elements from the Group1 set were also in the ODD set...
    C. Group1 had 4 members in all.
    (i.e., 3 out of 4 elements in Group1 were also in the ODD set)
    D. The ODD set had a total of 5 elements in it (it was of size 5)
    E. The universe of all possible elements was size 9 (here, it happens to be the numbers 1..9).
    This last number will always be the same for every result line.

    The universe of all elements is automatically computed by "union"-ing all the entries.
    Or it can instead be manually specified with the "-U" switch on the command line.


Revision History:

    May 2007: Added "-IU" (individual universe) option for specifying different
              universes for different items.

	March 2008: Added "-no" for outputting -log10(pval) instead of log10(pval).
    This way, higher scores are BETTER (and 0 is still the worst).
    (This is *NOT* the default option!)

    May 2008:
    sets_overlap.pl now prints out the sets in the same order that they were
    found in the *test* file (not the gold file). (alexgw)
    Previously, sets were printed out randomly based on the Perl hash order.

    May 2008:
    Added "-dot" for setting output delimiter to a tab. Prevents
    tab copy-paste Makefile bugs. (Previously possible with -do '	'.)
