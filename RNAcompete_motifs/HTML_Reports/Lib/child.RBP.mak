include $(HOME)/RNAcompete/Templates/Make/quick.mak

DISPLAYID = $(THISDIR)
ID =  $(shell cat $(HOME)/RNAcompete/RNAcompete_motifs/Data/info_all.tab | grep '$(DISPLAYID)\t' | cut -f 1)
GENENAME = $(shell cat $(HOME)/RNAcompete/RNAcompete_motifs/Data/info_all.tab | grep '$(ID)\t' | cut -f 16)
SPECIES = $(shell cat $(HOME)/RNAcompete/RNAcompete_motifs/Data/info.tab | grep '$(ID)\t' | cut -f 4)
SETAFILE = $(HOME)/RNAcompete/RNAcompete_motifs/Data/Training_Data/$(ID)/z_setA.tab
SETBFILE = $(HOME)/RNAcompete/RNAcompete_motifs/Data/Training_Data/$(ID)/z_setB.tab
SETABFILE = $(HOME)/RNAcompete/RNAcompete_motifs/Data/Training_Data/$(ID)/z_setAB.tab
# ESCORESETAFILE = $(HOME)/RNAcompete/RNAcompete_motifs/Data/Training_Data/$(ID)/e_setA.tab
# ESCORESETBFILE = $(HOME)/RNAcompete/RNAcompete_motifs/Data/Training_Data/$(ID)/e_setB.tab
# ESCORESETABFILE = $(HOME)/RNAcompete/RNAcompete_motifs/Data/Training_Data/$(ID)/e_setAB.tab
METHODS = pwm_topX_w7
LOGODIR_SETA = $(HOME)/RNAcompete/RNAcompete_motifs/Figures/Logos/$(ID)/setA/Entropy_noborder
LOGODIR_SETB = $(HOME)/RNAcompete/RNAcompete_motifs/Figures/Logos/$(ID)/setB/Entropy_noborder
LOGODIR = $(HOME)/RNAcompete/RNAcompete_motifs/Figures/Logos/$(ID)/setAB/Entropy_noborder

IUPACDIR = $(HOME)/RNAcompete/RNAcompete_motifs/IUPACs/pwm_topX_w7/$(ID)/setAB

targets  =  7mertable.txt 7mertable_aligned.txt IUPAC.txt Species.txt ID.txt Gene.txt html scatter.png

a:
	echo $(ID);
	echo $(DISPLAYID)
	echo $(GENENAME)

all: $(targets)

clean:
	rm -f $(targets) $(wildcard *.tmp)

make:

IUPAC.txt: $(IUPACDIR)/motif.IUPAC.ed
	cat $< > $@;

Gene.txt:
	echo $(GENENAME) >> $@;

ID.txt:
	echo $(DISPLAYID) >> $@;

Species.txt: 
	cat $(HOME)/RNAcompete/RNAcompete_motifs/Data/info.tab \
	| grep '$(ID)\t' \
	| cut -f 4 \
	> $@;

scatter.png:
	join.pl $(SETAFILE) $(SETBFILE) \
	| cut -f 2,3 \
	| cap.pl setA,setB \
	> input.tmp;
	Rscript ../Lib/scatter.R input.tmp $@;

html: scatter.png 7mertable.txt 7mertable_aligned.txt
	cat ../Lib/header.txt \
	| sed 's/___TITLE___/$(DISPLAYID) \/ $(GENENAME) (Species:$(SPECIES))/' \
	> $(DISPLAYID)_report.html;
	\
	\
	echo '<h2>Motif</h2>' >> $(DISPLAYID)_report.html;
	echo 'SetAB: <img src="$(DISPLAYID)_pwm_topX_w7.png">' >> $(DISPLAYID)_report.html;
	echo '| SetA: <img src="$(DISPLAYID)_pwm_topX_w7_setA.png">' >> $(DISPLAYID)_report.html;
	echo '| SetB: <img src="$(DISPLAYID)_pwm_topX_w7_setB.png">' >> $(DISPLAYID)_report.html;
	\
	echo '<br />' >> $(DISPLAYID)_report.html;
	\
	echo '<table class="noborder"><tr><td>' >> $(DISPLAYID)_report.html;
	echo '<h2>7-mer scatter plot</h2>' >> $(DISPLAYID)_report.html;
	echo '<img src="scatter.png">' >> $(DISPLAYID)_report.html;
	echo '</td>' >> $(DISPLAYID)_report.html;
	\
	echo '<td>' >> $(DISPLAYID)_report.html;
	echo '<h2>Aligned top 7-mers</h2>' >> $(DISPLAYID)_report.html;
	cat 7mertable_aligned.txt >> $(DISPLAYID)_report.html;
	echo '</td>' >> $(DISPLAYID)_report.html;
	\
	echo '<td>' >>	$(DISPLAYID)_report.html;
	echo '<h2>Top 7-mers by Z-score</h2>' >> $(DISPLAYID)_report.html;
	cat 7mertable.txt >> $(DISPLAYID)_report.html;
	echo '</td></tr></table>' >> $(DISPLAYID)_report.html;
	\
	echo '<br />' >> $(DISPLAYID)_report.html;
	\
	\
	$(foreach m, $(METHODS), \
	   convert -resize 200x100 $(LOGODIR)/$(ID)_$(m).png ./$(DISPLAYID)_$(m).png ; \
	   convert -resize 200x100 $(LOGODIR_SETA)/$(ID)_$(m).png ./$(DISPLAYID)_$(m)_setA.png ; \
	   convert -resize 200x100 $(LOGODIR_SETB)/$(ID)_$(m).png ./$(DISPLAYID)_$(m)_setB.png ; \
	   echo '      <td class="noborder" > <img src="$(DISPLAYID)_$(m).png"> </td>' >> $@; \
	)
	\
	\
	cat ../Lib/footer.txt \
	| sed "s/___DATE___/`date`/" \
	>> $(DISPLAYID)_report.html;

methodtable.txt:
	echo '<table class="border" cellpadding=20px>' > $@;
	echo '   <tr>' >> $@;
	$(foreach m, $(METHODS), \
	   echo '      <td class="noborder"><h3>$(m)</h3></td>' >> $@; \
	)
	echo '   </tr>' >> $@;
	echo '   <tr>' >> $@;
	$(foreach m, $(METHODS), \
	   convert -resize 200x100 $(LOGODIR)/$(ID)_$(m).png ./$(DISPLAYID)_$(m).png ; \
	   convert -resize 200x100 $(LOGODIR_SETA)/$(ID)_$(m).png ./$(DISPLAYID)_$(m)_setA.png ; \
	   convert -resize 200x100 $(LOGODIR_SETB)/$(ID)_$(m).png ./$(DISPLAYID)_$(m)_setB.png ; \
	   echo '      <td class="noborder" > <img src="$(DISPLAYID)_$(m).png"> </td>' >> $@; \
	)
	echo '   </tr>' >> $@;
	echo '   <tr>' >> $@;
	$(foreach m, $(METHODS), \
	   echo '      <td class="noborder" >' >> $@; \
	   cat $(EVALDIR)/Pearson/avgstats.tab | grep '$(m)\t' | grep '$(ID)\t' | cut -f 3 | paste.pl Pearson - > s.tmp; \
	   cat $(EVALDIR)/Avg_Precision/avgstats.tab | grep '$(m)\t' | grep '$(ID)\t' | cut -f 3 | paste.pl Avg_Precision - >> s.tmp; \
	   cat s.tmp | cap.pl Eval_type,Score | ../Lib/tab2html.pl -l >> $@; \
	   echo '      </td>' >> $@; \
	)
	echo '   </tr>' >> $@;
	echo '</table>' >> $@;

7mertable.txt:
	cat $(SETAFILE) \
	| head -10 \
	| awk '{ printf "%s\t%3.2f\n",$$1,$$2}' \
	> a.tmp;
	cat $(SETBFILE) \
	| head -10 \
	| awk '{ printf "%s\t%3.2f\n",$$1,$$2}' \
	> b.tmp;
	cat $(SETABFILE) \
	| head -10 \
	| awk '{ printf "%s\t%3.2f\n",$$1,$$2}' \
	> ab.tmp;
	paste a.tmp b.tmp ab.tmp\
	| cap.pl 'Set A,score,Set B,score,Set A+B,score' \
	| ../Lib/tab2html.pl -c -l \
	>> $@;

Escoretable.txt:
	cat $(ESCORESETAFILE) \
	| head -10 \
	> a.tmp;
	cat $(ESCORESETBFILE) \
	| head -10 \
	> b.tmp;
	cat $(ESCORESETABFILE) \
	| head -10 \
	> ab.tmp;
	paste a.tmp b.tmp ab.tmp \
	| cap.pl 'Set A,score,Set B,score,All data,score' \
	| ../Lib/tab2html.pl -c -l \
	>> $@;
	rm a.tmp b.tmp ab.tmp

7mertable_aligned.txt:
	cat $(SETAFILE) \
	| head -10 \
	| cut -f 1 \
	| align_nmers.pl \
	> a.tmp;
	cat $(SETBFILE) \
	| head -10 \
	| cut -f 1 \
	| align_nmers.pl \
	> b.tmp;
	cat $(SETABFILE) \
	| head -10 \
	| cut -f 1 \
	| align_nmers.pl \
	> ab.tmp;
	paste a.tmp b.tmp ab.tmp \
	| cap.pl Set A,Set B,All data \
	| ../Lib/tab2html.pl -c -l \
	>> $@;
	rm a.tmp b.tmp ab.tmp
