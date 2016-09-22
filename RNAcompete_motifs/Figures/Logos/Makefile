include $(HOME)/RNAcompete/Templates/Make/quick.mak

CHILDREN = $(shell cat $(HOME)/RNAcompete/RNAcompete_motifs/Data/id.lst )

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
	   ln -sf ../Lib/child.RBP.mak Makefile; \
	   make maker; \
	   cd ..; \
	)

doit:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   echo $(c) ; \
	   make doit ; \
	   cd ..; \
	)

collect:
	mkdir -p $@;
	$(foreach c, $(CHILDREN), \
	   cp $(c)/setAB/Entropy_noborder/*pwm_topX_w7.png $@/$(c)_pwm_topX_w7.png; \
	)

collect_trimmed:
	mkdir -p $@;
	$(foreach c, $(CHILDREN), \
	   cp $(c)/setAB/Entropy_noborder_trimmed/*pwm_topX_w7.png $@/$(c)_pwm_topX_w7.png; \
	)

collect_med:
	mkdir -p $@;
	$(foreach c, $(CHILDREN), \
	   cp $(c)/setAB/Entropy_noborder_med/*pwm_topX_w7.png $@/$(c)_pwm_topX_w7.png; \
	)

collect_tiny:
	mkdir -p $@;
	$(foreach c, $(CHILDREN), \
	   cp $(c)/setAB/Entropy_noborder_tiny/*pwm_topX_w7.png $@/$(c)_pwm_topX_w7.png; \
	)

collect_small:
	mkdir -p $@;
	$(foreach c, $(CHILDREN), \
	   cp $(c)/setAB/Entropy_noborder_small/*pwm_topX_w7.png $@/$(c)_pwm_topX_w7.png; \
	)

collect_freq:
	mkdir -p $@;
	$(foreach c, $(CHILDREN), \
	   cp $(c)/setAB/Freq_noborder/*pwm_topX_w7.png $@/$(c)_pwm_topX_w7.png; \
	)


include $(HOME)/RNAcompete/Templates/Make/quick.mak
