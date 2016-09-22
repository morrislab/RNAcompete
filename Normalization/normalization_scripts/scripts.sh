#!/bin/sh

   /opt/sw/matlab/bin/matlab -nodesktop -nojvm -nodisplay -r " load_data_from_single_file('raw_data.txt'); exit;"
   /opt/sw/matlab/bin/matlab -nodesktop -nojvm -nodisplay -r " script_final('col', 'quant', 'trim', 5); exit;"
# submitjob /opt/sw/matlab2010a/bin/matlab -nodesktop -nojvm -nodisplay -r " script_human_final('col', 'quant', 'trim', 5); exit;"
#submitjob   /opt/sw/matlab2010a/bin/matlab -nodesktop -nojvm -nodisplay -r " script_human_final('col', 'quant', 'median', 0); exit;"

#  /opt/sw/matlab2010a/bin/matlab -nodesktop -nojvm -nodisplay -r " script_human_final('col', 'matlab_median', 'trim', 0);exit;"
# submitjob   /opt/sw/matlab2010a/bin/matlab -nodesktop -nojvm -nodisplay -r " script_human_final('col', 'matlab_median', 'trim', 5);exit;"
 # /opt/sw/matlab2010a/bin/matlab -nodesktop -nojvm -nodisplay -r " script_human_final('col', 'matlab_median', 'median', 0);exit;"
