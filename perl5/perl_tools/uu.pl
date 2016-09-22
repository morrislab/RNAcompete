#!/usr/bin/perl

$outfile="";

$f = 1;
foreach $infile (@ARGV)
  {
    if(open(INFILE, $infile))
      {
        while(<INFILE>)
          {
            if(/^begin/)
              {	
        	$outfile = (split)[2]; 
		$outfile =~ s/[()\[\]]//g;
        	if(!(open(OUTFILE, "| uudecode > $outfile")))
		  {
		    open(OUTFILE, ">/dev/null");
		  }
		else
		  {
		    print STDERR "Creating file($f) [$outfile]\n";
		    $f++;
		  }
              }

            if(length($outfile)>0)
              {	print OUTFILE; }

	    if(/^end$/)
	      { 
		system("rm -f $infile");
		close(OUTFILE);
		$outfile=""; 
	      }
          }
      }
  }

