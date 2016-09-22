#!/usr/bin/perl

use strict;
use warnings;

my $id      = shift (@ARGV);
my $set = shift (@ARGV);
my $outfile = shift (@ARGV);
die unless (defined ($outfile));

my $dir          = "~/RNAcompete/RNAcompete_motifs/Data/Training_Data/$id";
my $scorefile   = "$dir/${set}.tab";
my $testset;
if($set eq 'setA'){
	$testset = 'setB';
} elsif($set eq 'setB'){
	$testset = 'setA';
} else {
	$testset = 'setAB';
}
my $answerfile   = "$dir/${testset}.tab";

warn "$dir\n$scorefile\n$answerfile\n";

my $k = 7;
my $x = 10;
warn "$x top ${k}-mers\n";
my $infile = "$dir/${k}mers_${set}.tab";
my $zfile = "$dir/z_${set}.tab";
warn "get count pfm from top k-mers\n";
system "cat $infile | sed -e 1d | head -$x | cut -f 1 | align_nmers.pl | pfm_from_aligned.pl -g -c | lin.pl | cap.pl Pos,A,C,G,U > pfm_${k}_${x}.tmp ;";
print "cat $zfile | head -$x | cut -f 2 > topz.tmp;";
print "cat $zfile | head -$x | cut -f 1 | align_nmers.pl | paste - topz.tmp | pfm_from_aligned_z.pl -g -c | lin.pl | cap.pl Pos,A,C,G,U > pfm_${k}_${x}_z.tmp ;";
system "cat $zfile | head -$x | cut -f 2 > topz.tmp;";
system "cat $zfile | head -$x | cut -f 1 | align_nmers.pl | paste - topz.tmp | pfm_from_aligned_z.pl -g -c | lin.pl | cap.pl Pos,A,C,G,U > pfm_${k}_${x}_z.tmp ;";

warn "trim pfm\n";
system "cat pfm_${k}_${x}.tmp | sed -e 1d | row_stats.pl -h 0 -sum | paste.pl - $x | sed -e 1d | ./Lib/trim_to_min.pl  | join.pl - pfm_${k}_${x}.tmp | cut -f 2- | lin.pl | cap.pl Pos,A,C,G,U  > pfm_trimmed_${k}_${x}.tmp;";
system "cat pfm_${k}_${x}.tmp | sed -e 1d | row_stats.pl -h 0 -sum | paste.pl - $x | sed -e 1d | ./Lib/trim_to_min.pl  | join.pl - pfm_${k}_${x}_z.tmp | cut -f 2- | lin.pl | cap.pl Pos,A,C,G,U  > pfm_trimmed_${k}_${x}_z.tmp;";

warn "convert to fraction PFM\n";
system "cat pfm_trimmed_${k}_${x}.tmp | row_stats.pl -sum | sed 's/^Key/Pos/' | join.pl pfm_trimmed_${k}_${x}.tmp - | ./Lib/convert_to_pfm.pl | cut -f 1-5 > pfm_frac_${k}_${x}.tmp";
system "cat pfm_trimmed_${k}_${x}.tmp | row_stats.pl -sum | sed 's/^Key/Pos/' | join.pl pfm_trimmed_${k}_${x}.tmp - | ./Lib/convert_to_pfm_pseud.pl | cut -f 1-5 > pfm_frac_${k}_${x}_pseud.tmp";
system "cat pfm_trimmed_${k}_${x}_z.tmp | row_stats.pl -sum | sed 's/^Key/Pos/' | join.pl pfm_trimmed_${k}_${x}_z.tmp - | ./Lib/convert_to_pfm.pl | cut -f 1-5 > pfm_frac_${k}_${x}_z.tmp";
system "cat pfm_trimmed_${k}_${x}_z.tmp | row_stats.pl -sum | sed 's/^Key/Pos/' | join.pl pfm_trimmed_${k}_${x}_z.tmp - | ./Lib/convert_to_pfm_pseud.pl | cut -f 1-5 > pfm_frac_${k}_${x}_pseud_z.tmp";
#my $avgZ = `cat topz.tmp | cap.pl asdf | transpose.pl -q | row_stats.pl -h 0 -mean | sed -e 1d | cut -f 2`;
#chomp($avgZ);
#print "avgZ = $avgZ\n";
my $avgZ = 10.926;
system "cat pfm_trimmed_${k}_${x}_z.tmp | row_stats.pl -sum | sed 's/^Key/Pos/' | join.pl pfm_trimmed_${k}_${x}_z.tmp - | ./Lib/convert_to_pfm_pseud.pl $avgZ | cut -f 1-5 > pfm_frac_${k}_${x}_z_pseud_z.tmp";
system "cat pfm_trimmed_${k}_${x}_z.tmp | row_stats.pl -sum | sed 's/^Key/Pos/' | join.pl pfm_trimmed_${k}_${x}_z.tmp - | ./Lib/convert_to_pfm_pseud.pl | cut -f 1-5 > pfm_frac_${k}_${x}_z_pseud_1.tmp";

warn "convert to energy matrix\n";
system "cat pfm_frac_${k}_${x}_pseud.tmp | head -n 1 > h.tmp; cat pfm_frac_${k}_${x}_pseud.tmp | row_stats.pl -max | join.pl pfm_frac_${k}_${x}_pseud.tmp - -o Min > pre2.tmp; cat pre2.tmp | sed -e 1d | ./Lib/reformat_MR_matrix_to_energy.pl | cat h.tmp - | cut -f 1-5 > energy_${k}_${x}.tmp;";

warn "predict scores on training data\n";
#system "./Lib/predict_intensity_BML_mu_0_strands.pl $scorefile energy_${k}_${x}.tmp | cut -f 4 > pred_${k}_${x}.tmp;";

warn "calculate pearson correlation on training data\n";
#system "cat $scorefile | cut -f 4 | paste.pl pred_${k}_${x}.tmp - | sed -e 1d  > data.tmp;";
#system "pearson.R data.tmp | cut -d ' ' -f 2 | paste.pl $k $x - >> stats.txt";


system "cp pfm_frac_7_10_z_pseud_1.tmp pfm.txt";
system "cp energy_7_10.tmp energy.txt";

#system "rm -f *.tmp";

#warn "predict scores on test data\n";

#system "./Lib/predict_intensity_BML_mu_0_strands.pl $answerfile energy.txt  > $outfile;";







