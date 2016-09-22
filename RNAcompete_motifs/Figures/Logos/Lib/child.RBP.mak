include $(HOME)/RNAcompete/Templates/Make/quick.mak

CHILDREN = setA setB setAB

targets  = data.tab

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
	   ln -sf ../../Lib/child.set.mak Makefile; \
	   cd ..; \
	)


doit:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   echo $(c) ; \
	   make files; \
	   cd ..; \
	)


include $(HOME)/RNAcompete/Templates/Make/quick.mak
