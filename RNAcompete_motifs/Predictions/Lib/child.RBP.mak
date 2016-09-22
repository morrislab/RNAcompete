include $(HOME)/RNAcompete/Templates/Make/quick.mak

ID            = $(THISDIR)
METHOD            = $(PARENTDIR)
#CHILDREN = setAB
CHILDREN      =  setA setB setAB
HOUR_ESTIMATE = $(shell cat $(HOME)/RNAcompete/RNAcompete_motifs/Src/time.txt | grep '^$(METHOD)	' | cut -f 2)


targets  = 

all: $(targets)

a:
	echo $(CHILDREN)

clean:
	rm -f $(targets) $(wildcard *.tmp)
	
cleanall:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   make clean; \
	   cd ..; \
	) \
	rm -f $(targets) $(wildcard *.tmp)

redo_pfms:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   echo $(c); \
	   mv pfm.txt pfm.old.txt; \
	   make clean; \
	   make all; \
	   cd ..; \
	)

doit:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   make all; \
	   cd ..; \
	)


make:

maker:
	$(foreach c, $(CHILDREN), \
	   mkdir -p $(c); \
	   cd $(c); \
	   ln -sf ../../../Lib/child.set.mak Makefile; \
	   cd ..; \
	)



new:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   mkdir -p Backup; \
	   cp energy.* stats.* Backup; \
	   rm data.tab; \
	   make; \
	   cd ..; \
	)

stats.tab:
	$(foreach c, $(CHILDREN), \
	   cat $(c)/stats.txt \
	   | paste.pl $(c) - \
	   >> $@; \
	)

include $(HOME)/RNAcompete/Templates/Make/quick.mak
