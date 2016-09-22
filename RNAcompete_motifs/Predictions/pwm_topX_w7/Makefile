include $(HOME)/RNAcompete/Templates/Make/quick.mak

ID            = $(THISDIR)

CHILDREN = $(shell cat $(HOME)/RNAcompete/RNAcompete_motifs/Data/id.lst)


targets  = 

all: $(targets)

clean:
	rm -f $(targets) $(wildcard *.tmp)

cleanall:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   make clean; \
	   cd ..; \
	) \
	rm -f $(targets) $(wildcard *.tmp)

a:
	echo $(CHILDREN)

make:

maker:
	$(foreach c, $(CHILDREN), \
	   mkdir -p $(c); \
	   cd $(c); \
	   ln -sf ../../Lib/child.RBP.mak Makefile; \
	   make maker; \
	   cd ..; \
	)

doit:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   echo $(c); \
	   make doit; \
	   cd ..; \
	)

redo_pfms:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   echo $(c); \
	   make redo_pfms; \
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
	   cd $(c); \
	   make stats.tab; \
	   cd ..; \
	   cat $(c)/stats.tab \
	   | paste.pl $(c) - \
	   >> $@; \
	)

all_7mers.tab:
	rm -f all_7mers.tmp;
	$(foreach c, $(CHILDREN), \
	   cat $(c)/setAB/top7mers.lst \
	   >> all_7mers.tmp; \
	)
	sort all_7mers.tmp > all_7mers.tab;
	rm -f all_7mers.tmp;

unique_7mers.tab: all_7mers.tab 
	cat $< \
	| sort -u \
	> $@;


include $(HOME)/RNAcompete/Templates/Make/quick.mak
