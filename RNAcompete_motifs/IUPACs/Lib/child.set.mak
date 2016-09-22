include $(HOME)/RNAcompete/Templates/Make/quick.mak

SET     = $(THISDIR)
ID      = $(PARENTDIR)
METHOD  = $(GRANDDIR)
INDIR   = $(HOME)/RNAcompete/RNAcompete_motifs/Predictions/$(METHOD)/$(ID)/$(SET)

targets  = motif.IUPAC.ed motif.IUPAC.kl motifs.tab

all: $(targets)

clean:
	rm -f $(targets) $(wildcard *.tmp) ;

a:
	echo $(METHODS)

make:

motif.IUPAC.ed: $(INDIR)/pfm.txt
	cat $< \
	| ./convert_pfm_to_iupac.pl ed - \
	> $@;


motif.IUPAC.7mer.ed: $(INDIR)/pfm.txt
	cat $< \
	| ./convert_pfm_to_iupac.pl 7ed - \
	> $@;



motif.IUPAC.kl: $(INDIR)/pfm.txt
	cat $< \
	| ./convert_pfm_to_iupac.pl kl - \
	> $@;

motifs.tab: motif.IUPAC.ed motif.IUPAC.kl
	paste motif.IUPAC.ed motif.IUPAC.kl \
	> $@;
