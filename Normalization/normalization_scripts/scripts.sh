#!/bin/sh

matlab -nodesktop -nojvm -nodisplay -r " load_data_from_single_file('raw_data.txt'); exit;"
matlab -nodesktop -nojvm -nodisplay -r " script_final('col', 'quant', 'trim', 5); exit;"
