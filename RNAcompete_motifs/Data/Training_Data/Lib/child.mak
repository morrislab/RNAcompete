include $(HOME)/RNAcompete/Templates/Make/quick.mak

ID       = $(THISDIR)
INDIR    = ../../normalized_probe_scores
ARRAYDIR    = ../../array_design
# BATCH    =  $(shell cat ../../Escores/info.tab | grep '^$(ID)\s'  | cut -f 4 )
# ESCOREDIR    = ../../Escores/$(BATCH)/$(ID)
# ESCORELABELS = ../../Escores/rowlabels.txt
# ESCORELABELS_NOCUT = ../../Escores/rowlabels_nocut.txt
EXP_ID   = $(shell cat $(HOME)/RNAcompete/RNAcompete_motifs/Data/info.tab | grep '^$(ID)\s'  | cut -f 2)
TRAIN_SET   = $(shell cat $(HOME)/RNAcompete/RNAcompete_motifs/Data/info.tab | grep '^$(ID)\s'  | cut -f 6)
TEST_SET   = $(shell cat $(HOME)/RNAcompete/RNAcompete_motifs/Data/info.tab | grep '^$(ID)\s'  | cut -f 7)
INFOALLFILE = ../../info_all.tab

MIN_POS_PROBES  = 50
POS_PROBE_CUT = 4
NEG_PROBE_CUT = 0
#POS_ESCORE_CUT  = 0.45

#targets  = raw_data.tab setA.tab setB.tab setAB.tab kmers probes_posneg probes_preprocessed zscores escores new
targets  =  setA.tab setB.tab setAB.tab kmers zscores escores new_z

probes_preprocessed: setA_bottomhalf_remove.tab setA_bottomhalf_zero.tab setB_bottomhalf_remove.tab setB_bottomhalf_zero.tab setAB_bottomhalf_remove.tab setAB_bottomhalf_zero.tab

probes_posneg: probes_positive probes_negative probes_top50

probes_positive: probes_positive_setA.tab probes_positive_setB.tab probes_positive_setAB.tab
probes_negative: probes_negative_setA.tab probes_negative_setB.tab probes_negative_setAB.tab
probes_top50: probes_top50_setA.tab probes_top50_setB.tab probes_top50_setAB.tab

kmers: 4mers 5mers 6mers 7mers 8mers 9mers 10mers
zscores: z_setA.tab z_setB.tab z_setAB.tab z_all.tab
# escores: e_setA.tab e_setB.tab e_setAB.tab e_all.tab

4mers: 4mers_setA.tab 4mers_setB.tab 4mers_setAB.tab
5mers: 5mers_setA.tab 5mers_setB.tab 5mers_setAB.tab
6mers: 6mers_setA.tab 6mers_setB.tab 6mers_setAB.tab
7mers: 7mers_setA.tab 7mers_setB.tab 7mers_setAB.tab 
8mers: 8mers_setA.tab 8mers_setB.tab 8mers_setAB.tab
9mers: 9mers_setAB.tab
10mers: 10mers_setAB.tab

z_4mers: z_4mers_setAB.tab z_4mers_setA.tab z_4mers_setB.tab
z_5mers: z_5mers_setAB.tab z_5mers_setA.tab z_5mers_setB.tab
z_6mers: z_6mers_setAB.tab z_6mers_setA.tab z_6mers_setB.tab
z_8mers: z_8mers_setAB.tab z_8mers_setA.tab z_8mers_setB.tab
z_9mers: z_9mers_setAB.tab
z_10mers: z_10mers_setAB.tab

new_z: z_4mers z_5mers z_6mers z_8mers z_9mers z_10mers

base: setA.tab setB.tab setAB.tab 7mers zscores

all: $(targets)

clean:
	rm -f $(targets) $(wildcard *.tmp)

make:

a: 
	echo $(ID); \
	echo $(EXP_ID); \
	echo $(BATCH); \

setA.tab:
	@echo HybID_$(EXP_ID)
	extract_column.pl -s HybID_$(EXP_ID)_ $(INDIR)/*.txt > data.tmp;
	cut -f 1 $(INDIR)/PhaseVII_mad_col_quant_trim_5.txt \
	| paste.pl - data.tmp \
	| sort \
	> data2.tmp;
	join_multi_sorted.pl $(ARRAYDIR)/sets.tab $(ARRAYDIR)/probes.tab data2.tmp \
	| filter_rows.pl -k 1 -v SetA \
	| awk -F"\t" '{print $$2 "\t" $$3 "\t" $$4 "\t" $$1}'  \
	| paste.pl $(ID) - \
	| sed -e 1d \
	| cap.pl RBP_ID,Probe_Set,RNA_Seq,Probe_Score,Probe_ID \
	> $@;
	rm *.tmp;

setB.tab:
	@echo HybID_$(EXP_ID)
	extract_column.pl -s HybID_$(EXP_ID)_ $(INDIR)/*.txt > data.tmp;
	cut -f 1 $(INDIR)/PhaseVII_mad_col_quant_trim_5.txt \
	| paste.pl - data.tmp \
	| sort \
	> data2.tmp;
	join_multi_sorted.pl $(ARRAYDIR)/sets.tab $(ARRAYDIR)/probes.tab data2.tmp \
	| filter_rows.pl -k 1 -v SetB \
	| awk -F"\t" '{print $$2 "\t" $$3 "\t" $$4 "\t" $$1}'  \
	| paste.pl $(ID) - \
	| sed -e 1d \
	| cap.pl RBP_ID,Probe_Set,RNA_Seq,Probe_Score,Probe_ID \
	> $@;
	rm *.tmp;
	
setAB.tab: setA.tab setB.tab
	cat setA.tab \
	> $@; \
	cat setB.tab \
	| sed -e 1d \
	>> $@;

4mers_setA.tab: setA_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 4 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 4mer,MeanScore \
	> $@;	
	
4mers_setB.tab: setB_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 4 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 4mer,MeanScore \
	> $@;	
	
4mers_setAB.tab: setAB_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 4 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 4mer,MeanScore \
	> $@;


	
5mers_setA.tab: setA_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 5 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 5mer,MeanScore \
	> $@;	
	
5mers_setB.tab: setB_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 5 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 5mer,MeanScore \
	> $@;	
	
5mers_setAB.tab: setAB_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 5 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 5mer,MeanScore \
	> $@;	
	
6mers_setA.tab: setA_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 6 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 6mer,MeanScore \
	> $@;	
	
6mers_setB.tab: setB_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 6 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 6mer,MeanScore \
	> $@;	
	
6mers_setAB.tab: setAB_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 6 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 6mer,MeanScore \
	> $@;	
	
7mers_setA.tab: setA_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 7 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 7mer,MeanScore \
	> $@;

7mers_setB.tab: setB_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 7 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 7mer,MeanScore \
	> $@;
	
7mers_setAB.tab: setAB_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 7 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 7mer,MeanScore \
	> $@;


8mers_setA.tab: setA_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 8 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 8mer,MeanScore \
	> $@;

8mers_setB.tab: setB_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 8 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 8mer,MeanScore \
	> $@;
	
8mers_setAB.tab: setAB_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 8 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 8mer,MeanScore \
	> $@;
	
9mers_setAB.tab: setAB_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 9 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 8mer,MeanScore \
	> $@;

10mers_setAB.tab: setAB_bottomhalf_zero.tab
	cat $< \
	| sed -e 1d \
	| cut.pl -f 2,3,4 \
	| ../Lib/probe2kmers.pl - 10 \
	| filter_rows.pl -n -k 2 -v NaN \
	| cut.pl -f 2,3 \
	| expand.pl \
	| row_stats_expanded.pl -h 0 -trimmedmean 5 \
	| sed -e 1d \
	| sort -grk 2 \
	| cap.pl 8mer,MeanScore \
	> $@;

z_8mers_setAB.tab: 8mers_setAB.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_8mers_setA.tab: 8mers_setA.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_8mers_setB.tab: 8mers_setB.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \


z_9mers_setAB.tab: 9mers_setAB.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_10mers_setAB.tab: 10mers_setAB.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_4mers_setAB.tab: 4mers_setAB.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_4mers_setA.tab: 4mers_setA.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_4mers_setB.tab: 4mers_setB.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_5mers_setAB.tab: 5mers_setAB.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_5mers_setA.tab: 5mers_setA.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_5mers_setB.tab: 5mers_setB.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_6mers_setA.tab: 6mers_setA.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_6mers_setB.tab: 6mers_setB.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_6mers_setAB.tab: 6mers_setAB.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_7mers_setA.tab: z_setA.tab
	cat $< \
	> $@; \

z_7mers_setB.tab: z_setB.tab
	cat $< \
	> $@; \

z_7mers_setAB.tab: z_setAB.tab
	cat $< \
	> $@; \


##


z_setA.tab: 7mers_setA.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_setB.tab: 7mers_setB.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \

z_setAB.tab: 7mers_setAB.tab
	cat $< \
	| sed -e 1d \
	| cut -f 2 \
	| stats.pl \
	| cut -f 3,4 \
	| paste.pl $< `cat -` \
	| sed -e 1d \
	| perl -ne 'chomp; @tabs = split (/\t/); $$v=($$tabs[1]-$$tabs[2])/$$tabs[3]; print "$$_\t$$v\n";' \
	| cut -f 1,5 \
	> $@; \


probes_positive_setA.tab: setA.tab
	cat $< \
	| sed -e 1d \
    | cut -f 3,4 \
	| sort -nrk 2 \
	> 1.tmp; \
	\
	cat 1.tmp \
    | head -n $(MIN_POS_PROBES) \
    > o.tmp; \
    \
    cat 1.tmp \
    | select.pl -k 2 -gt $(POS_PROBE_CUT) \
	>> o.tmp; \
	\
	cat o.tmp \
	| sort -u \
    > $@; \
    rm -f 1.tmp o.tmp; \

probes_positive_setB.tab: setB.tab
	cat $< \
	| sed -e 1d \
    | cut -f 3,4 \
	| sort -nrk 2 \
	> 1.tmp; \
	\
	cat 1.tmp \
    | head -n $(MIN_POS_PROBES) \
    > o.tmp; \
    \
    cat 1.tmp \
    | select.pl -k 2 -gt $(POS_PROBE_CUT) \
	>> o.tmp; \
	\
	cat o.tmp \
	| sort -u \
    > $@; \
    rm -f 1.tmp o.tmp; \

probes_positive_setAB.tab: setAB.tab
	cat $< \
	| sed -e 1d \
    | cut -f 3,4 \
	| sort -nrk 2 \
	> 1.tmp; \
	\
	cat 1.tmp \
    | head -n $(MIN_POS_PROBES) \
    > o.tmp; \
    \
    cat 1.tmp \
    | select.pl -k 2 -gt $(POS_PROBE_CUT) \
	>> o.tmp; \
	\
	cat o.tmp \
	| sort -u \
    > $@; \
    rm -f 1.tmp o.tmp; \

probes_top50_setA.tab: setA.tab
	cat $< \
	| sed -e 1d \
    | cut -f 3,4 \
	| sort -nrk 2 \
	> 1.tmp; \
	\
	cat 1.tmp \
    | head -n 50 \
    > $@; \
    rm -f 1.tmp; \

probes_top50_setB.tab: setB.tab
	cat $< \
	| sed -e 1d \
    | cut -f 3,4 \
	| sort -nrk 2 \
	> 1.tmp; \
	\
	cat 1.tmp \
    | head -n 50 \
    > $@; \
    rm -f 1.tmp; \

probes_top50_setAB.tab: setAB.tab
	cat $< \
	| sed -e 1d \
    | cut -f 3,4 \
	| sort -nrk 2 \
	> 1.tmp; \
	\
	cat 1.tmp \
    | head -n 50 \
    > $@; \
    rm -f 1.tmp; \



probes_negative_setA.tab: setA.tab
	cat $< \
	| sed -e 1d \
    | cut -f 3,4 \
	| sort -nrk 2 \
    | select.pl -k 2 -lt $(NEG_PROBE_CUT) \
    > $@; \

probes_negative_setB.tab: setB.tab
	cat $< \
	| sed -e 1d \
    | cut -f 3,4 \
	| sort -nrk 2 \
    | select.pl -k 2 -lt $(NEG_PROBE_CUT) \
    > $@; \

probes_negative_setAB.tab: setAB.tab
	cat $< \
	| sed -e 1d \
    | cut -f 3,4 \
	| sort -nrk 2 \
    | select.pl -k 2 -lt $(NEG_PROBE_CUT) \
    > $@; \

e_setA.tab: $(ESCOREDIR)
	cat $</escores_A.txt \
	| grep -v NaN \
	| paste.pl $(ESCORELABELS_NOCUT) - \
	| sort -grk 2 \
	> $@;
	
e_setB.tab: $(ESCOREDIR)
	cat $</escores_B.txt \
	| grep -v NaN \
	| paste.pl $(ESCORELABELS_NOCUT) - \
	| sort -grk 2 \
	> $@;
	
e_setAB.tab: $(ESCOREDIR)
	cat $</escores_AB.txt \
	| grep -v NaN \
	| paste.pl $(ESCORELABELS_NOCUT) - \
	| sort -grk 2 \
	> $@;

setA_bottomhalf_remove.tab: setA.tab
	head -1 $< > h.tmp; \
	cat $< \
	| sed -e 1d \
	| sort -nrk 4 \
    | select.pl -k 4 -gt 0 \
    > 1.tmp; \
    cat h.tmp 1.tmp \
    > $@; \
    rm -f h.tmp 1.tmp;

setB_bottomhalf_remove.tab: setB.tab
	head -1 $< > h.tmp; \
	cat $< \
	| sed -e 1d \
	| sort -nrk 4 \
    | select.pl -k 4 -gt 0 \
    > 1.tmp; \
    cat h.tmp 1.tmp \
    > $@; \
    rm -f h.tmp 1.tmp;

setAB_bottomhalf_remove.tab: setAB.tab
	head -1 $< > h.tmp; \
	cat $< \
	| sed -e 1d \
	| sort -nrk 4 \
    | select.pl -k 4 -gt 0 \
    > 1.tmp; \
    cat h.tmp 1.tmp \
    > $@; \
    rm -f h.tmp 1.tmp;

setA_bottomhalf_zero.tab: setA.tab
	head -1 $< > h.tmp; \
	cat $< \
	| sed -e 1d \
	| sort -nrk 4 \
    | select.pl -k 4 -gt 0 \
    > 1.tmp; \
	cat $< \
	| sed -e 1d \
	| sort -nrk 4 \
    | select.pl -k 4 -lte 0 \
    | awk -F $$'\t' 'BEGIN {OFS = FS} {$$4 = 0; print}' \
    > 2.tmp; \
    cat h.tmp 1.tmp 2.tmp \
    > $@; \
    rm -f h.tmp 1.tmp 2.tmp;

setB_bottomhalf_zero.tab: setB.tab
	head -1 $< > h.tmp; \
	cat $< \
	| sed -e 1d \
	| sort -nrk 4 \
    | select.pl -k 4 -gt 0 \
    > 1.tmp; \
	cat $< \
	| sed -e 1d \
	| sort -nrk 4 \
    | select.pl -k 4 -lte 0 \
    | awk -F $$'\t' 'BEGIN {OFS = FS} {$$4 = 0; print}' \
    > 2.tmp; \
    cat h.tmp 1.tmp 2.tmp \
    > $@; \
    rm -f h.tmp 1.tmp 2.tmp;

setAB_bottomhalf_zero.tab: setAB.tab
	head -1 $< > h.tmp; \
	cat $< \
	| sed -e 1d \
	| sort -nrk 4 \
    | select.pl -k 4 -gt 0 \
    > 1.tmp; \
	cat $< \
	| sed -e 1d \
	| sort -nrk 4 \
    | select.pl -k 4 -lte 0 \
    | awk -F $$'\t' 'BEGIN {OFS = FS} {$$4 = 0; print}' \
    > 2.tmp; \
    cat h.tmp 1.tmp 2.tmp \
    > $@; \
    rm -f h.tmp 1.tmp 2.tmp;

e_all.tab: e_setA.tab e_setB.tab e_setAB.tab
	cat e_setA.tab \
	| sort \
	> e_setA.tmp;
	\
	cat e_setB.tab \
	| sort \
	> e_setB.tmp;
	\
	cat e_setAB.tab \
	| sort \
	> e_setAB.tmp;
	paste e_setA.tmp e_setB.tmp e_setAB.tmp \
	| cut -f 1,2,4,6 \
	| cap.pl 7mer,`cat $(INFOALLFILE) | grep '$(ID)\t' | cut -f 2`_e_setA,`cat $(INFOALLFILE) | grep '$(ID)\t' | cut -f 2`_e_setB,`cat $(INFOALLFILE) | grep '$(ID)\t' | cut -f 2`_e_setAB \
	> $@;
	rm -f e_setA.tmp e_setB.tmp e_setAB.tmp;

z_all.tab: z_setA.tab z_setB.tab z_setAB.tab
	cat z_setA.tab \
	| sort \
	> z_setA.tmp;
	\
	cat z_setB.tab \
	| sort \
	> z_setB.tmp;
	\
	cat z_setAB.tab \
	| sort \
	> z_setAB.tmp;
	paste z_setA.tmp z_setB.tmp z_setAB.tmp \
	| cut -f 1,2,4,6 \
	| cap.pl 7mer,`cat $(INFOALLFILE) | grep '$(ID)\t' | cut -f 2`_z_setA,`cat $(INFOALLFILE) | grep '$(ID)\t' | cut -f 2`_z_setB,`cat $(INFOALLFILE) | grep '$(ID)\t' | cut -f 2`_z_setAB \
	> $@;
	rm -f z_setA.tmp z_setB.tmp z_setAB.tmp;

fix:
	rm -f e_setA.tab e_setB.tab e_all.tab;
	make e_setA.tab;
	make e_setB.tab;
	make e_all.tab;
