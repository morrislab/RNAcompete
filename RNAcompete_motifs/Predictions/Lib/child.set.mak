include $(HOME)/RNAcompete/Templates/Make/quick.mak

SET         = $(THISDIR)
ID          = $(PARENTDIR)
METHOD      = $(GRANDDIR)
RUN_COMMAND = $(METHOD)

SRC_DIR     = $(HOME)/RNAcompete/RNAcompete_motifs/Src/$(METHOD)

INFILE = $(HOME)/RNAcompete/RNAcompete_motifs/Data/Training_Data/$(ID)/z_$(SET).tab

targets = data.tab

all: $(targets)

clean:
	rm -f $(targets) $(wildcard *.tmp) ; \
	rm -f pfm.txt ;

make:

a:
	echo $(SET); \
	echo $(ID); \
	echo $(METHOD); \

data.tab: 
	ln -sf $(SRC_DIR)/Lib; \
	./Lib/$(RUN_COMMAND).pl $(ID) $(SET) $@; \

top7mers.lst:
	cat $(INFILE) \
	| head -10 \
	| cut -f 1 \
	> $@;

fix:
	cat data.tab \
	| sed 's/CCTGTGTGAAATTGTTATCCGCTCT	/	/' \
	> a; \
	mv a data.tab; \


lee:
	cat Tmp/matrix_001.out  | tail -n +5 | tr a-z A-Z  | cut -f 2- | lin.pl -0 | sed 's/^0/Pos/' > pre.tmp; cat pre.tmp | head -n 1 > h.tmp; cat pre.tmp | row_stats.pl -sum | join.pl pre.tmp - -o Sum > pre2.tmp; cat pre2.tmp | sed -e 1d | ./Lib/reformat_MR_matrix.pl | cat h.tmp - | cut -f 1-5 > pfm.txt;
	cat pfm.txt | head -n 1 > h.tmp; cat pfm.txt | row_stats.pl -max | join.pl pfm.txt - -o Min > pre2.tmp; cat pre2.tmp | sed -e 1d | ./Lib/reformat_MR_matrix_to_energy.pl | cat h.tmp - | cut -f 1-5 > energy.txt;

