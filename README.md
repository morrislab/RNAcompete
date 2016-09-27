# RNAcompete #

Data analysis scripts for the RNAcompete analysis.

## Input file##

* [To be added]
* We included an **example** `raw_data.txt` file in this package.

## Analyzing RNAcompete data ##

### 1. Download ###

Clone or download the code and move the `/RNAcompete` folder to `$HOME` directory.


### 2. Install dependencies ###

* [Perl 5](https://www.perl.org/)

    Add our perl scripts to `$PATH` and Perl library:
    
    ```
    export PATH=$HOME/RNAcompete/perl5/perl_tools:$PATH;
    export PERL5LIB=$HOME/RNAcompete/perl5/perl_tools:$HOME/RNAcompete/perl5/modules:$PERL5LIB
    ```
    
* [Matlab 2015b](https://www.mathworks.com/)
* [R](https://www.r-project.org/)
* [ImageMagick](http://www.imagemagick.org/)
* [REDUCE Suite 2](http://bussemakerlab.org/lab/)
  * Download the version compatible with your system and move the `/REDUCE_Suite` folder to `~/RNAcompete`.
  * Check README by running:
  
    ```
    cd ~/RNAcompete/REDUCE_Suite/bin; ./REDUCE_Suite_setup
    ```
    
  * Run the following command to set up REDUCE Suite:
  
    ```
    export REDUCE_SUITE=$HOME/RNAcompete/REDUCE_Suite;
    export PATH=$HOME/RNAcompete/REDUCE_Suite/bin:$PATH
    ```
  * The default colors for nucleotides are A, green; C, blue; G, orange; U, cyan. Users may customize the coloring scheme by editing the following code in `~/RNAcompete/REDUCE_Suite/html/LogoGenerator_PS.def`:
    
    ```
    /colorDict <<
    (A) green       (a) m_green
    (C) blue        (c) m_blue
    (G) orange      (g) m_orange
    (T) red         (t) m_red
    (U) cyan        (u) m_cyan
    (X) white
    >> def
    ```
    
### 3.  Normalization ###

* (The raw data file we use is the **example** `raw_data.txt` file in `~/RNAcompete/Normalization/run_normalization/`)

* Copy and paste everything in `~/RNAcompete/Normalization/normalization_scripts/` to `~/RNAcompete/Normalization/run_normalization/` by running:
    
    ```
    cp ~/RNAcompete/Normalization/normalization_scripts/* ~/RNAcompete/Normalization/run_normalization/
    ```
    
* Run normalization from `/run_normalization` directory:

    ```
    cd ~/RNAcompete/Normalization/run_normalization/;
    ./scripts.sh
    ```

### 4.  Motif Generation ###

#### RBP data setup ####

* Move the normalized intensity file (`PhaseVII_mad_col_quant_trim_5.txt`) to motif generation directories:

    ```
    mkdir ~/RNAcompete/RNAcompete_motifs/Data/normalized_probe_scores;
    mv ~/RNAcompete/Normalization/run_normalization/PhaseVII_mad_col_quant_trim_5.txt ~/RNAcompete/RNAcompete_motifs/Data/normalized_probe_scores/
    ```
    
* Add information of RBP of interested to `info.tab` and `info_all.tab` files under `~/RNAcompete/RNAcompete_motifs/Data`
* Edit `~/RNAcompete/RNAcompete_motifs/Data/id.lst` to include only RBPs of interested (one RBP_id per line)

#### Calculate 7mer scores ####

```
cd ~/RNAcompete/RNAcompete_motifs/Data/Training_Data/; make maker; make doit
```
    
#### Calculate motifs ####

```
cd ~/RNAcompete/RNAcompete_motifs/Predictions/pwm_topX_w7/; make maker; make doit
```
    
#### Create motif logos ####

```
cd ~/RNAcompete/RNAcompete_motifs/Figures/logos/; make maker; make doit
```

#### Generate IUPAC motifs ####

```
cd ~/RNAcompete/RNAcompete_motifs/IUPACs/pwm_topX_w7/; make maker; make doit
```

#### Create HTML output ####

```
cd ~/RNAcompete/RNAcompete_motifs/HTML_Reports/; make maker; make doit; make RNAcompete_report_index.html
```

## Related Publications ##

* D. Ray, H. Kazan, K.B. Cook, M.T. Weirauch, H.S. Najafabadi, X. Li, S. Gueroussov, M. Albu, H. Zheng, A. Yang, H. Na, M. Irimia, L.H. Matzat, R.K. Dale, S.A. Smith, C.A. Yarosh, S.M. Kelly, B. Nabet, D. Mecenas, W. Li, R.S. Laishram, M. Qiao, H.D. Lipshitz, F. Piano, A.H. Corbett, R.P. Carstens, B.J. Frey, R.A. Anderson, K.W. Lynch, L.O. Penalva, E.P. Lei, A.G. Fraser, B.J. Blencowe, Q.D. Morris, T.R. Hughes, **A compendium of RNA-binding motifs for decodng gene regulation**, *Nature* 499(7457) (2013) 172-7. [[Pubmed]](http://www.ncbi.nlm.nih.gov/pubmed/23846655)

* D. Ray, H. Kazan, E.T. Chan, L. Pena Castillo, S. Chaudhry, S. Talukder, B.J. Blencowe, Q. Morris, T.R. Hughes, **Rapid and systematic analysis of the RNA recognition specificities of RNA-binding proteins**, *Nature biotechnology* 27(7) (2009) 667-70. [[Pubmed]](http://www.ncbi.nlm.nih.gov/pubmed/19561594)
