include $(HOME)/RNAcompete/Templates/Make/quick.mak

SET     = $(THISDIR)
ID      = $(PARENTDIR)
METHODS = pwm_topX_w7

targets  = files

all: $(targets)

clean:
	rm -f $(targets) $(wildcard *.tmp) $(wildcard *.log) $(wildcard *.opt) $(wildcard *.out) $(wildcard *.eps) $(wildcard *.xml);
	rm -rf Entropy Entropy_noborder Affinity Affinity_noborder Freq Freq_noborder ;

a:
	echo $(METHODS)

make:

files:
	mkdir -p Entropy Entropy_noborder Affinity Affinity_noborder Freq Freq_noborder Entropy_noborder_trimmed Entropy_noborder_small Entropy_noborder_med Entropy_noborder_tiny
	ln -s $(HOME)/RNAcompete/REDUCE_Suite/bin/ .; \
	\
	$(foreach m, $(METHODS), \
	   cat $(HOME)/RNAcompete/RNAcompete_motifs/Predictions/$(m)/$(ID)/$(SET)/pfm.txt \
	   | ../../Lib/pwm2pfm.pl \
	   | space2tab.pl \
	   | transpose.pl \
	   | sed -e 1d \
	   | join.pl ../../Lib/order.lst - \
	   > $(m).pfm.tmp; \
	)
	\
	ls -l *.pfm.tmp \
	| grep ' 0 ' \
	| cut.pl -f -1 -d ' ' \
	| perl -ne 'chomp; system "rm $$_";'; \
	\
	$(foreach m, $(METHODS), \
	   cat $(m).pfm.tmp \
	   | transpose.pl \
	   | sed -e 1d \
	   | cut.pl -f 1,4,3,2 \
	   | lin.pl \
	   | cap.pl Pos,A,C,G,U \
	   > $(m).2.tmp; \
	   \
	   cat $(m).2.tmp \
	   | row_stats.pl -max \
	   | join.pl $(m).2.tmp - \
	   | perl -ne 'chomp; @tabs = split (/\t/); $$id=shift (@tabs); print "$$id"; foreach (@tabs) { $$v=$$_/$$tabs[4]; $$v=1 if (1-$$v < 0.00001); print "\t$$v"; } print "\n";' \
	   | cut -f 1-5 \
	   | cap.pl Pos,A,C,G,T \
	   > $(m).mr.tmp; \
	   \
	   cat $(m).mr.tmp \
	   | sed -e 1d \
	   | cut -f 2- \
	   | add_column.pl - -s '-' -b \
	   | cat ../../Lib/head.txt - \
	   | sed 's/-/a/' \
	   > $(ID)_$(m).tmp; \
	   \
	   touch Entropy/$(ID)_$(m).png; \
	   touch Entropy_noborder/$(ID)_$(m).png; \
	   touch Entropy_noborder_trimmed/$(ID)_$(m).png; \
	   touch Entropy_noborder_small/$(ID)_$(m).png; \
	   touch Entropy_noborder_tiny/$(ID)_$(m).png; \
	   touch Entropy_noborder_med/$(ID)_$(m).png; \
	   touch Affinity/$(ID)_$(m).png; \
	   touch Affinity_noborder/$(ID)_$(m).png; \
	   touch Freq/$(ID)_$(m).png; \
	   touch Freq_noborder/$(ID)_$(m).png; \
	   \
	   ./bin/Convert2PSAM -source=v1 -inp=$(ID)_$(m).tmp -psam=$(ID)_$(m).xml ; \
	   ./bin/LogoGenerator -file=$(ID)_$(m).xml -logo=Entropy/$(ID)_$(m).png -rna ; \
	   convert Entropy/$(ID)_$(m).png -fuzz 35% -opaque black -fill white -opaque grey -fill white -trim -bordercolor white -border 10x10 Entropy_noborder/$(ID)_$(m).png ; \
	   convert Entropy/$(ID)_$(m).png -fuzz 35% -opaque black -fill white -opaque grey -fill white -trim -bordercolor white Entropy_noborder_trimmed/$(ID)_$(m).png ; \
	   convert Entropy_noborder_trimmed/$(ID)_$(m).png -resize x100 Entropy_noborder_med/$(ID)_$(m).png ; \
	   convert Entropy_noborder_trimmed/$(ID)_$(m).png -resize x50 Entropy_noborder_small/$(ID)_$(m).png ; \
	   convert Entropy_noborder_trimmed/$(ID)_$(m).png -resize x70 Entropy_noborder_tiny/$(ID)_$(m).png ; \
	   ./bin/LogoGenerator -file=$(ID)_$(m).xml -logo=Affinity/$(ID)_$(m).png -style=ddG -rna; \
	   convert Affinity/$(ID)_$(m).png -fuzz 20% -opaque black -fill white -fuzz 18% -opaque gray\(47%\) -fill white -opaque gray\(27%\) -fill white -fuzz 10%  -opaque gray\(73%\) -fill white -fuzz 20% -trim -bordercolor white -border 10x10 Affinity_noborder/$(ID)_$(m).png ; \
	   ./bin/LogoGenerator -file=$(ID)_$(m).xml -logo=Freq/$(ID)_$(m).png -style=freq -rna; \
	   convert Freq/$(ID)_$(m).png -fuzz 35% -opaque black -fill white -opaque grey -fill white -trim -bordercolor white -border 10x10 Freq_noborder/$(ID)_$(m).png ; \
	)
	\
	ls -l */*.png \
	| grep ' 0 ' \
	| cut.pl -f -1 -d ' ' \
	| perl -ne 'chomp; system "cp ../../Remote/EMPTY.png $$_";'; \

test:
	mkdir -p UnAligned; \
	mkdir -p UnAligned/Files/; \
	\
	$(foreach m, $(METHODS), \
	   cat $(m).tmp \
	   | ../../Lib/pwm2pfm.pl \
	   | transpose.pl \
	   | sed -e 1d \
	   | join.pl ../../Lib/order.lst - \
	   > UnAligned/Files/$(m).pfm; \
	)
	\
	ln -sf ../../Lib/*.rb .; \
	./alignPFMs.rb UnAligned Aligned; \
	\
	$(foreach m, $(METHODS), \
	   cat Aligned/UnAligned/Files/$(m).pfm \
	   | transpose.pl \
	   | sed -e 1d \
	   | cut.pl -f 1,4,3,2 \
	   | lin.pl \
	   | cap.pl Pos,A,C,G,T \
	   > Aligned/$(m).txt; \
	)

test:
	ls -l UnAligned/Files/*.pfm \
	| grep ' 0 ' \
	| cut.pl -f -1 -d ' ' \
	| perl -ne 'chomp; system "rm $$_";'; \
	\
	./alignPFMs.rb UnAligned Aligned; \

