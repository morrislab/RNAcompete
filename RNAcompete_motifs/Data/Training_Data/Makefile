include $(HOME)/RNAcompete/Templates/Make/quick.mak

CHILDREN = $(shell cat ../id.lst)

targets  = data.tab answers.tab ranks.tab 

all: $(targets)

clean:
	rm -f $(targets) $(wildcard *.tmp)

make:

a:
	echo $(CHILDREN)

doit:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   echo $(c); \
	   make base; \
	   cd ..; \
	)

doit_escores:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   echo $(c); \
	   make escores; \
	   cd ..; \
	)


doit_rawfix:
	$(foreach c, $(CHILDREN_RAW_FIX), \
	   cd $(c); \
	   echo $(c); \
	   rm -f raw_data.tab; \
	   rm -f raw_data.tab.gz; \
	   make raw_data.tab.gz; \
	   cd ..; \
	)

top_7mers.tab:
	echo 'RBP$(TAB)kmer$(TAB)score' > $@;
	$(foreach c, $(CHILDREN), \
	   cat $(c)/z_setAB.tab \
	   | head -1 \
	   | add_column.pl - -b  -s $(c) \
	   >> $@; \
	)


all7mers:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   echo $(c); \
	   make 7mers_all.tab; \
	   cd ..; \
	)

escores_setA_setB_firsthalf.txt:
	cat RBP_1/e_setA.tab \
	| sort \
	| cut -f 1 \
	| cap.pl 7mer \
	> 1.tmp;
	$(foreach c, $(CHILDREN_FIRSTHALF), \
		cat ../info.tab \
		| grep -P '$(c)\t' \
		| cut -f 3 \
		| paste.pl -d '' $(c) _ - _ setA \
		> h.tmp; \
		cat $(c)/e_setA.tab \
		| sort \
		| cut -f 2 \
		| cap.pl -f h.tmp \
		| paste 1.tmp - \
		> 2.tmp; \
		cat ../info.tab \
		| grep -P '$(c)\t' \
		| cut -f 3 \
		| paste.pl -d '' $(c) _ - _ setB \
		> h.tmp; \
		cat $(c)/e_setB.tab \
		| sort \
		| cut -f 2 \
		| cap.pl -f h.tmp \
		| paste 2.tmp - \
		> 1.tmp; \
	)
	cat 1.tmp > $@;
	rm -f 1.tmp 2.tmp h.tmp;




escores_setA_setB_secondhalf.txt:
	cat RBP_1/e_setA.tab \
	| sort \
	| cut -f 1 \
	| cap.pl 7mer \
	> 1.tmp;
	$(foreach c, $(CHILDREN_SECONDHALF), \
		cat ../info.tab \
		| grep -P '$(c)\t' \
		| cut -f 3 \
		| paste.pl -d '' $(c) _ - _ setA \
		> h.tmp; \
		cat $(c)/e_setA.tab \
		| sort \
		| cut -f 2 \
		| cap.pl -f h.tmp \
		| paste 1.tmp - \
		> 2.tmp; \
		cat ../info.tab \
		| grep -P '$(c)\t' \
		| cut -f 3 \
		| paste.pl -d '' $(c) _ - _ setA \
		> h.tmp; \
		cat $(c)/e_setB.tab \
		| sort \
		| cut -f 2 \
		| cap.pl -f h.tmp \
		| paste 2.tmp - \
		> 1.tmp; \
	)
	cat 1.tmp > $@;
	rm -f 1.tmp 2.tmp h.tmp;

done.tab:
	rm -f done.tmp;
	$(foreach c, $(CHILDREN), \
		ls -l $(c)/*mers_set*.tab \
		| cut.pl -d ' ' -f -5,-1 \
		| sed 's/RBP_[0-9]*\///' \
		| paste.pl $(c) - \
		>> done.tmp; \
	)	\
	cat done.tmp \
	| expand.pl \
	| join.pl ../ids_2014.lst - -o "MISSING" \
	> $@; \


done_escores.tab:
	rm -f done.tmp;
	$(foreach c, $(CHILDREN), \
		ls -l $(c)/e*.tab \
		| cut.pl -d ' ' -f -5,-1 \
		| sed 's/RBP_[0-9]*\///' \
		| paste.pl $(c) - \
		>> done.tmp; \
	)	\
	cat done.tmp \
	| expand.pl \
	| join.pl ../ids_2014.lst - -o "MISSING" \
	> $@; \

redo_zscores:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   rm -f z_*; \
	   make all; \
	   cd ..; \
	)


fix:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   echo $(c); \
	   make fix; \
	   cd ..; \
	)

data.tab:
	cat */data.tab \
	| head -n 1 \
	> $@; \
	\
	$(foreach c, $(CHILDREN), \
	   cat $(c)/data.tab \
	   | sed -e 1d \
	   >> $@; \
	)

answers.tab:
	cat */answers.tab \
	| head -n 1 \
	> $@; \
	\
	$(foreach c, $(CHILDREN), \
	   cat $(c)/answers.tab \
	   | sed -e 1d \
	   >> $@; \
	)

ranks.tab:
	cat */ranks.tab \
	| head -n 1 \
	| paste.pl `echo Id` - \
	> $@; \
	\
	$(foreach c, $(CHILDREN), \
	   cat $(c)/ranks.tab \
	   | sed -e 1d \
	   | paste.pl `echo $(c)` - \
	   >> $@; \
	)

stats.tab:
	$(foreach c, $(CHILDREN), \
	   cat $(c)/stats.tab \
	   | add_column.pl - -s $(c) -b \
	   >> $@; \
	)

top_escores.tab:
	$(foreach c, $(CHILDREN), \
	   cat $(c)/e_setAB.tab \
	   | head -1 \
	   | add_column.pl - -s $(c) -b \
	   >> $@; \
	)


maker:
	$(foreach c, $(CHILDREN), \
	   mkdir -p $(c); \
	   cd $(c); \
	   ln -sf ../Lib/child.mak Makefile; \
	   cd ..; \
	)

raw_data_head.tab:
	rm -f raw_data_head.tmp;
	touch raw_data_head.tmp;
	$(foreach c, $(CHILDREN_TEST), \
	   zcat $(c)/raw_data.tab.gz \
	   | sed -e 1d \
	   | head -100 \
	   | tail -10 \
	   | cut -f 4 \
	   | cap.pl $(c) \
	   | paste raw_data_head.tmp - \
	   > raw_data_head.tab; \
	   mv raw_data_head.tab raw_data_head.tmp; \
	)
	mv raw_data_head.tmp raw_data_head.tab;


escores_20150429.txt:
	cat RBP_1/e_setA.tab \
	| sort \
	| cut -f 1 \
	| cap.pl 7mer \
	> 1.tmp;
	$(foreach c, $(CHILDREN), \
		cat ../info.tab \
		| grep -P '$(c)\t' \
		| cut -f 3 \
		| paste.pl -d '' $(c) _ - _ setA \
		> h.tmp; \
		cat $(c)/e_setA.tab \
		| sort \
		| cut -f 2 \
		| cap.pl -f h.tmp \
		| paste 1.tmp - \
		> 2.tmp; \
		cat ../info.tab \
		| grep -P '$(c)\t' \
		| cut -f 3 \
		| paste.pl -d '' $(c) _ - _ setB \
		> h.tmp; \
		cat $(c)/e_setB.tab \
		| sort \
		| cut -f 2 \
		| cap.pl -f h.tmp \
		| paste 2.tmp - \
		> 1.tmp; \
		cat ../info.tab \
		| grep -P '$(c)\t' \
		| cut -f 3 \
		| paste.pl -d '' $(c) _ - _ setAB \
		> h.tmp; \
		cat $(c)/e_setAB.tab \
		| sort \
		| cut -f 2 \
		| cap.pl -f h.tmp \
		| paste 1.tmp - \
		> 2.tmp; \
		mv 2.tmp 1.tmp; \
	)
	cat 1.tmp > $@;
	rm -f 1.tmp 2.tmp h.tmp;



zscores_20150429.txt:
	cat RBP_1/e_setA.tab \
	| sort \
	| cut -f 1 \
	| cap.pl 7mer \
	> 1.tmp;
	$(foreach c, $(CHILDREN), \
		cat ../info.tab \
		| grep -P '$(c)\t' \
		| cut -f 3 \
		| paste.pl -d '' $(c) _ - _ setA \
		> h.tmp; \
		cat $(c)/z_setA.tab \
		| sort \
		| cut -f 2 \
		| cap.pl -f h.tmp \
		| paste 1.tmp - \
		> 2.tmp; \
		cat ../info.tab \
		| grep -P '$(c)\t' \
		| cut -f 3 \
		| paste.pl -d '' $(c) _ - _ setB \
		> h.tmp; \
		cat $(c)/z_setB.tab \
		| sort \
		| cut -f 2 \
		| cap.pl -f h.tmp \
		| paste 2.tmp - \
		> 1.tmp; \
		cat ../info.tab \
		| grep -P '$(c)\t' \
		| cut -f 3 \
		| paste.pl -d '' $(c) _ - _ setAB \
		> h.tmp; \
		cat $(c)/z_setAB.tab \
		| sort \
		| cut -f 2 \
		| cap.pl -f h.tmp \
		| paste 1.tmp - \
		> 2.tmp; \
		mv 2.tmp 1.tmp; \
	)
	cat 1.tmp > $@;
	rm -f 1.tmp 2.tmp h.tmp;

probe_scores_20150429.txt:
	cat RBP_1/setAB.tab \
	| cut.pl -f 5,2,3 \
	> 1.tmp;
	$(foreach c, $(CHILDREN), \
		cat ../info.tab \
		| grep -P '$(c)\t' \
		| cut -f 3 \
		| paste.pl -d '' $(c) _ - \
		> h.tmp; \
		cat $(c)/setAB.tab \
		| sed -e 1d \
		| cut -f 4 \
		| cap.pl -f h.tmp \
		| paste 1.tmp - \
		> 2.tmp; \
		mv 2.tmp 1.tmp; \
	)
	cat 1.tmp > $@;
	rm -f 1.tmp 2.tmp h.tmp;



include $(HOME)/RNAcompete/Templates/Make/quick.mak
