include $(HOME)/RNAcompete/Templates/Make/quick.mak

CHILDREN = setA setB setAB

targets  = 

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
	   ln -sf ../../../Lib/child.set.mak Makefile; \
	   ln -sf ../../../Lib/convert_pfm_to_iupac.pl convert_pfm_to_iupac.pl; \
	   cd ..; \
	)


doit:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   echo $(c) ; \
	   make clean; \
	   make all; \
	   cd ..; \
	)


include $(HOME)/RNAcompete/Templates/Make/quick.mak
