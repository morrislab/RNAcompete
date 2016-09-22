include $(HOME)/RNAcompete/Templates/Make/quick.mak

CHILDREN = $(shell cat $(HOME)/RNAcompete/RNAcompete_motifs/Data/id.lst )

targets  = motifs.tab

a:
	echo $(CHILDREN)

all: $(targets)

clean:
	rm -f $(targets) $(wildcard *.tmp)

make:

maker:
	$(foreach c, $(CHILDREN), \
	   mkdir -p $(c); \
	   cd $(c); \
	   ln -sf ../../Lib/child.RBP.mak Makefile; \
	   make maker; \
	   cd ..; \
	)

motifs.tab:
	$(foreach c, $(CHILDREN), \
	   cat $(c)/setAB/motif.IUPAC.ed \
	   | paste.pl $(c) - \
	   >> $@; \
	)


doit:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   echo $(c) ; \
	   make doit ; \
	   cd ..; \
	)


include $(HOME)/RNAcompete/Templates/Make/quick.mak
