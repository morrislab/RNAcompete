include $(HOME)/RNAcompete/Templates/Make/quick.mak

CHILDREN = $(shell cat $(HOME)/RNAcompete/RNAcompete_motifs/Data/id.lst )
INFOFILE = $(HOME)/RNAcompete/RNAcompete_motifs/Data/info_all.tab
IUPACDIR = $(HOME)

targets  = RNAcompete_report_index.html

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
	   cd ..; \
	)

doit:
	$(foreach c, $(CHILDREN), \
	   cd $(c); \
	   echo $(c) ; \
	   rm -f *.txt; \
	   rm -f *.html ; \
	   rm -f *.png ; \
	   make all ; \
	   cd ..; \
	)

RNAcompete_report_index.html:
	cat ./Lib/header_main.txt \
	> $@;
	\
	$(foreach c, $(CHILDREN), \
	   cat $(INFOFILE) \
	   | grep '$(c)\t' \
	   | cut.pl -f 16,3 \
	   | tr '\t' : \
	   | paste.pl -d '' '<a href="$(c)/$(c)_report.html">' - '</a>' \
	   | paste.pl - $(c) `cat $(c)/Species.txt` `cat $(c)/IUPAC.txt` '<img src="$(c)/$(c)_pwm_topX_w7.png" />' \
	   >> table.tmp; \
	)
	cat table.tmp \
	| sort -n -t : -k 2 \
	| tr : '\t' \
	| cap.pl 'Gene name,Hyb ID,RNAcompete ID,Species,IUPAC,Logo' \
	| ./Lib/tab2html.pl -l \
	>> $@;
	\
	cat ./Lib/footer.txt \
	| sed "s/___DATE___/`date`/" \
	>> $@;

include $(HOME)/RNAcompete/Templates/Make/quick.mak
