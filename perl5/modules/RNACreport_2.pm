use strict;
use warnings;
use File::Temp qw/ tempfile /;
use Cwd;
require 'align-nmers.pm';
require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(generate_html_report);

sub generate_html_report{
	my ($inDir,$sBatchID,$nMotifSize) = @_[0,1,2];
	my @suffixes = @_[3..$#_];
	my $nmer = "${nMotifSize}mer";


	my @anTop = (10,100); # top nmers to show


	print join("\n",@suffixes)."\n";
	
	
	# set up output files and folders
	my $outFileName = "RNAcompete_report.html";
	my $outDir = $inDir . '/report';	
	my $outFile = $outDir .'/'. $outFileName;
	mkdir($outDir) unless -e $outDir;
	open(my $out, ">$outFile") or die "couldn't open $outFile\n";
	
	my @setAFiles = ();
	my @setBFiles = ();
	my @logoDirs = ();
	my @scatterDirs = ();
	for (my $i=0; $i<=$#suffixes; $i++){
		my $suffix = $suffixes[$i];
		$setAFiles[$i] = "$inDir/${nMotifSize}mer_trimmedmeans_setA_$suffix.txt";
		$setBFiles[$i] = "$inDir/${nMotifSize}mer_trimmedmeans_setB_$suffix.txt";
		$logoDirs[$i] =  "logo_images_${suffix}";
		$scatterDirs[$i] = "scatter_plots_${suffix}";
		# make directories;
		mkdir($outDir.'/'.$logoDirs[$i]) unless -e $outDir.'/'.$logoDirs[$i];
		mkdir($outDir.'/'.$scatterDirs[$i]) unless -e $outDir.'/'.$scatterDirs[$i];
		
		
	}

	
	#get experiment headers
	my $rasHeaders = _get_headers($setAFiles[0]);
	my $nSamples = (scalar @{$rasHeaders})-1;

	print join("\n",@{$rasHeaders})."\n";
	
	#print initial info
	_print_title($out,$sBatchID,$nMotifSize);
	
	# print links to individual samples
	_print_sample_index($out,$rasHeaders);

	# create all the scatterplots + correlations	
	my @pearsons = ();
	my @spearmans = ();
	for (my $i = 0; $i <= $#scatterDirs; $i++){
		my $scatterDir = $scatterDirs[$i];
		_get_scatter($outDir.'/'.$scatterDir,$setAFiles[$i],$setBFiles[$i]);
		my %sampleToABPearson = ();
		my %sampleToABSpearman = ();
		# read in scatterplot correlations
		my $corFile ="$outDir/$scatterDir/setA_setB_correlations.txt"; 
		#print "getting correlations from $corFile\n";
		open(my $corfh, $corFile) or die "couldn't open $corFile\n";
		while(<$corfh>){
			chomp; chop while /\r/;
			my ($s,$pr,$sr) = split("\t");
			if($s =~ /^(.+)\.(FLAG_TRMEAN|MEDIAN)/){
				$s = $1;
			}
			$sampleToABPearson{$s} = $pr;
			$sampleToABSpearman{$s} = $sr;
		}
		close($corFile);
		$pearsons[$i] = \%sampleToABPearson;
		$spearmans[$i] = \%sampleToABSpearman;
	}
		
	

	#print results for each protein
	for (my $nCol=0; $nCol<=$nSamples ; $nCol++){
		#print sample info
		my $sSample = $rasHeaders->[$nCol];	
		print "$sSample...\n";
		$sSample =~ s/\s//g;
		print $out "<a name=\"$sSample\"></a>\n";
		print $out "<h2>Results for $sSample</h2>\n";

		print $out "<table border=\"1\">\n"; #start of table of suffixes
		
		#print suffix headers
		print $out "<tr>\n"; #start of suffix header row
		for (my $i=0; $i<=$#suffixes; $i++){
			print $out "<td><b>$suffixes[$i] normalization</b></td>\n";
		}		
		print $out "</tr>\n"; #end of suffix header row
		
		#print scatterplots
		print $out "<tr>\n"; #start of scatterplot row
		for (my $i=0; $i<=$#suffixes; $i++){
			#my $scatterFile = "$scatterDirs[$i]/${sSample}.FLAG_col_quant_trim_5_setAsetBscatter.png";
			my $scatterFile = "$scatterDirs[$i]/${sSample}_setAsetBscatter.png";
			#$scatterFile =~ tr/\-\(\)/\.\.\./ if $suffixes[$i] =~ /pc/;
			print $out "<td>\n<h3>Set A vs Set B $nmer scatterplot with $suffixes[$i] normalization</h3>\n";
			my $sS = $sSample;
			$sS =~ tr/\-\(\)/\.\.\./ if $suffixes[$i] =~ /pc/;
			my $pr = $pearsons[$i]->{$sS};
			my $sr = $spearmans[$i]->{$sS};
			print $out "<img src=\"$scatterFile\" />\n";
			print $out "<p>Pearson R=${pr} Spearman R=${sr}</p>\n";
			print $out "</td>\n";
		}
		print $out "</tr>\n"; #end of scatterplot row

		my @arhraraAllTopNmersAndScoresSetA = ();
		my @arhraraAllTopNmersAndScoresSetB = ();
		for (my $i=0; $i<=$#suffixes; $i++){	
			$arhraraAllTopNmersAndScoresSetA[$i] = _get_top_nmers_and_scores($setAFiles[$i],$nCol,\@anTop);
			$arhraraAllTopNmersAndScoresSetB[$i] = _get_top_nmers_and_scores($setBFiles[$i],$nCol,\@anTop);
		}
		
		# print logos
		foreach (my $iTop=0; $iTop <= $#anTop; $iTop++){
			my $nTop = $anTop[$iTop];
			print $out "<tr>\n"; #start of logos row
			for (my $i=0; $i<=$#suffixes; $i++){
				print $out "<td>\n";
				
				my $rasTopNmersSetA = $arhraraAllTopNmersAndScoresSetA[$i]->{'nmers'}->[$iTop];
				my $rasTopNmersSetB = $arhraraAllTopNmersAndScoresSetB[$i]->{'nmers'}->[$iTop];
				
				my $rasAlignedTopSetA = align_and_print($rasTopNmersSetA);
				my $rasAlignedTopSetB = align_and_print($rasTopNmersSetB);

				
				my $logoFileSetA = "$logoDirs[$i]/${sSample}_logo_SetA_top$nTop";
				my $logoFileSetB = "$logoDirs[$i]/${sSample}_logo_SetB_top$nTop";
				$logoFileSetA =~ s/[\(\)]/_/g;
				$logoFileSetB =~ s/[\(\)]/_/g;

				#print "logo file: $logoFileSetA\n";
			
				my $return = _get_logo("$outDir/$logoFileSetA",$rasAlignedTopSetA);
				$return = _get_logo("$outDir/$logoFileSetB",$rasAlignedTopSetB);
				
				print $out "<h3>Logo generated from top $nTop ${nmer}s with $suffixes[$i] normalization</h3>\n";
				print $out "<table border=1 cellpadding=5px>\n<tr><th>Set A</th><th>Set B</th></tr>\n";
				print $out "<tr>\n";
				print $out "<td><img src=\"${logoFileSetA}.png\" /></td>\n";
				print $out "<td><img src=\"${logoFileSetB}.png\" /></td>\n";
				print $out "</tr></table>\n";
				
				print $out "</td>\n";
				
			}
			print $out "</tr>\n"; #end of logos row

		}

		
		
		my $iTop = 0;
		my $nTop = 10;
		
		# print top 10 nmers
		print $out "<tr>\n"; #start of top 10 nmers row
		for (my $i=0; $i<=$#suffixes; $i++){
			print $out "<td>\n";
			my $rasTopNmersSetA = $arhraraAllTopNmersAndScoresSetA[$i]->{'nmers'}->[$iTop];
			my $rasTopNmersSetB = $arhraraAllTopNmersAndScoresSetB[$i]->{'nmers'}->[$iTop];

			my $ranTopScoresSetA = $arhraraAllTopNmersAndScoresSetA[$i]->{'scores'}->[$iTop];
			my $ranTopScoresSetB = $arhraraAllTopNmersAndScoresSetB[$i]->{'scores'}->[$iTop];
			
			print $out "<h3>Top $nTop Nmers with $suffixes[$i] normalization</h3>\n";
			print $out "<table border=1 cellpadding=5px>\n<tr><th colspan=\"2\">Set A</th><th colspan=\"2\">Set B</th></tr>\n";
			print $out "<tr>\n";
			print $out "<td>\n<code>".join("<br/>\n",@{$rasTopNmersSetA})."</code>\n</td>\n";
			print $out "<td>\n<code>".join("<br/>\n",@{$ranTopScoresSetA})."</code>\n</td>\n";
			print $out "<td>\n<code>".join("<br/>\n",@{$rasTopNmersSetB})."</code>\n</td>\n";
			print $out "<td>\n<code>".join("<br/>\n",@{$ranTopScoresSetB})."</code>\n</td>\n";
			print $out "</tr></table>\n";


			print $out "</td>\n";
		}
		print $out "</tr>\n"; #end of top 10 nmers row

		# print aligned top 10 nmers
		print $out "<tr>\n"; #start of aligned top 10 nmers row
		for (my $i=0; $i<=$#suffixes; $i++){
			my $suffix = $suffixes[$i];
			print $out "<td>\n";
			my $rasTopNmersSetA = $arhraraAllTopNmersAndScoresSetA[$i]->{'nmers'}->[$iTop];
			my $rasTopNmersSetB = $arhraraAllTopNmersAndScoresSetB[$i]->{'nmers'}->[$iTop];
				
			my $rasAlignedTopSetA = align_and_print($rasTopNmersSetA);
			my $rasAlignedTopSetB = align_and_print($rasTopNmersSetB);
			
			print $out "<h3>Top $nTop Nmers, aligned, with $suffixes[$i] normalization</h3>\n";
			print $out "<table border=1 cellpadding=5px>\n<tr><th>Set A</th><th>Set B</th></tr>\n";
			print $out "<tr>\n";
			print $out "<td>\n<code>".join("<br/>\n",@{$rasAlignedTopSetA})."</code>\n</td>\n";
			print $out "<td>\n<code>".join("<br/>\n",@{$rasAlignedTopSetB})."</code>\n</td>\n";
			print $out "</tr></table>\n";
			
			my $alignedoutfileSetA = "$outDir/${sSample}_top${nTop}_setA_aligned_nmers_${suffix}.txt";
			_print_top_nmers_tofile($alignedoutfileSetA,$nTop,$rasAlignedTopSetA);
			my $alignedoutfileSetB = "$outDir/${sSample}_top${nTop}_setB_aligned_nmers_${suffix}.txt";
			_print_top_nmers_tofile($alignedoutfileSetB,$nTop,$rasAlignedTopSetB);


			print $out "</td>\n";
		}
		print $out "</tr>\n"; #end of aligned top 10 nmers row

		print $out "</table>\n";
		
	}
	
	
	print $out "</body>\n</html>\n";
	
	close($out);
}

sub _get_scatter{
	my ($scatterDir,$setAFile,$setBFile) = @_;
	my $matlab = join('; ',
						"outdir = '$scatterDir'",
						"addpath('/Users/eskay/Documents/work/grad/Projects/RNAcompeteDB/working/rnacompete/trunk/matlab')",
						"setAFile = '$setAFile'",
						"setBFile = '$setBFile'",
						"run_makescatters",
						"exit;");
	`matlab -nodesktop -nosplash -nodisplay -r "$matlab"  1>&2`;
	
}

sub _print_title{
	my ($out, $sBatchID, $nMotifSize) = @_;
	my $title = "RNAcompete results for batch \"$sBatchID\"";
	my $nmer = "${nMotifSize}mer";
	
	print $out "<html>\n<head>\n<title>$title</title>\n</head>\n";
	print $out "<body>\n<h1>$title</h1>\n";
	print $out "<h2>Results based on $nmer analysis -- ";
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
	$year += 1900;
	$mon += 1;
	my $datetime = sprintf "%02d-%02d-%04d %02d:%02d", $mday, $mon, $year, $hour, $min;
	print $out "generated on $datetime</h2>\n";
}


sub _print_sample_index{
	my ($out, $rasHeaders) = @_;
	my $nSamples = (scalar @{$rasHeaders})-1;
	for (my $nCol=0; $nCol<=$nSamples ; $nCol++){
		my $sSample = $rasHeaders->[$nCol];	
		$sSample =~ s/\s//g;
		print "$sSample\n";
		print $out "<p><a href=\"#$sSample\">Results for $sSample</a></p>\n";
	}
}


sub _print_top_nmers_tofile{
	my ($outFile,$top,$rasAlignedd) = @_;
	open(my $out, ">$outFile") or die "couldn't open $outFile\n";
	# print top 10 nmers
	print $out join("\n",@{$rasAlignedd})."\n";
	close($out);
}


sub _get_logo{
	my ($logoFile,$rasAligned) = @_;
	# write temporary .fa file
	my($fh,$tmpFaFile) = tempfile(UNLINK => 1);
	my $i = 1;
	my $alignWidth;
	foreach my $seq (@{$rasAligned}){
		print $fh ">seq_$i\n$seq\n";
		$alignWidth = length($seq) if $i == 1;
		$i++;
	}
	my $cmd = "(weblogo -F png  -A rna --errorbars NO --color-scheme classic --fineprint '' --weight 0.0001 < $tmpFaFile > ${logoFile}.png) &> /dev/null";
#	my $cmd = "(weblogo -F png  -A rna --errorbars NO --color-scheme classic --fineprint '' --weight 25 < $tmpFaFile > ${logoFile}.png) &> /dev/null";
#	my $width = $alignWidth * 41 + 2.7152;
#	$width = int($width + .5 * ($width <=> 0)); # round it
#	my $dir = getcwd;
#	my $cmd = "~/Documents/work/grad/software/enologs_v1.40/enologos -f $tmpFaFile -c /Users/eskay/Documents/work/grad/software/enologos_v1.40/parameters.txt -o ${dir}/${logoFile}.ps}; convert -trim -density ${width}x200! -resize ${width}x200! ${dir}/${logoFile}.ps ${dir}/${logoFile}.png\n";
	#print $cmd."\n";
	`$cmd`;
	close($fh);
	return $logoFile;
}

sub _get_top_nmers_and_scores{
	my ($inFile,$nCol,$nTops) = @_;
	$nCol = $nCol+1;
	my $nSortCol = $nCol+1;
	my($fh,$tmpFile) = tempfile(UNLINK => 1);
	my $cmd = "sort -grk $nSortCol $inFile > $tmpFile";
	#print "$cmd\n";
	`$cmd`;
	open(my $in, "$tmpFile") or die "couldn't open $tmpFile\n";
	#my $sLine = <$in>; #header
	my @araResultNmers = ();
	my @araResultScores = ();
	for my $nTop (@{$nTops}){
		my @topResultNmers = ();
		my @topResultScores = ();
		while(<$in>){
			my ($sNmer,$nScore) = (split("\t"))[0,$nCol];
			push(@topResultNmers, $sNmer);
			push(@topResultScores, $nScore);
			last if $#topResultNmers == ($nTop-1);
		}
		push(@araResultNmers,\@topResultNmers);
		push(@araResultScores,\@topResultScores);
	}
	close($fh);
	#print "$tmpFile\n";
	`rm $tmpFile`;
	my %output = (
		'nmers' => \@araResultNmers,
		'scores' => \@araResultScores
	);
	return \%output;
}

sub _get_headers{
	my $inFile = shift;
	open(my $in, $inFile) or die "couldn't open $inFile\n";
	my $sLine = <$in>;
	chomp ($sLine); chop($sLine) while $sLine =~ /\r/;
	close($in);
	my @asHeaders = split("\t",$sLine);
	my @asTrimHeaders = ();
	foreach my $sHead (@asHeaders){
		next if $sHead eq 'Nmer';
		if($sHead =~ /^(.+)\.(FLAG_TRMEAN|MEDIAN|FLAG_col_quant_trim_\d*)/){
			push(@asTrimHeaders,$1);
		} else {
			push(@asTrimHeaders,$sHead);			
		}
		#if($sHead !~ /Nmer/){
		#	push(@asTrimHeaders,$sHead);
		#}
	}
	print "\n\nHEADERS:\n",join("\n",@asTrimHeaders),"\n\nEND HEADERS\n\n";
	return \@asTrimHeaders;
}
