function [nmer_scores] = script_Misc1_final(col_type, quantile_type, trim_type, trim_cutoff )
%function [nmer_scores] = rnacompete_norm_script_fly(outfilename, phase)
% Arguments
%
% data : struct containing the pulldown, rowlabels, collabels, flags etc.
% transformed probe score distributions
% phase : name of the phase, will be used in names of the output files
% containing histograms
% 
% What it does: 
% 1. remove the pool
% 2. run quantile normalization + z-score transformation
% 3. calculate 7mer scores

figure_size = 16

load raw_data.mat

if(strcmp(trim_type, 'median'))
	key = [ 'mad_'  col_type '_' quantile_type '_trimmedian']
else
	key = [ 'mad_' col_type '_' quantile_type '_trim_' num2str(trim_cutoff) ]
end
outfilename = ['PhaseVII_' key '.txt']
data_key ='PhaseVII_data';


%load human_indices_tobe_removed.mat
%data.pool_flags(human_indices_tobe_removed) = 1;


%load human_pool_remove.mat;
%data.pool_flags(human_pool_remove) = 1;


%load indices_more_50p_top5k.mat;
%data.pool_flags(indices_more_50p_top5k) = 1;


if (isfield(Data, 'selected_flags'))
    union_flags = Data.selected_flags + Data.flags;
else
    union_flags =  Data.flags;
end

num_hyb = size(Data.pulldown,2);
num_worked = num_hyb;
num_flagged_all = zeros(num_worked);

for ii = 1:num_hyb
    Data.pulldown(union_flags(:,ii)  > 0, ii) = NaN;
    num_flagged_all(ii) = nnz(union_flags(:,ii));	
end

clear union_flags;


worked_indices = 1:1:num_worked;



array_size = size(Data.pulldown,1);

pulldown = zeros(array_size, num_worked);
num_flagged = zeros(num_worked);

for ii = 1:num_worked
   pulldown(:, ii) = Data.pulldown(:, worked_indices(ii));
   collabels(ii) = Data.collabels(worked_indices(ii));
   num_flagged(ii)= num_flagged_all(worked_indices(ii));
end

if(strcmp(quantile_type,'matlab'))
	pulldown = quantilenorm(pulldown);
elseif(strcmp(quantile_type, 'matlab_median'))
	pulldown = quantilenorm(pulldown, 'MEDIAN', true);
else
	pulldown = quantileNormNaN(pulldown);
end

%ZSCORE OF PROBES
dlmwrite([data_key '_after_quant.txt'], pulldown, '\t');


Data.pulldown = (pulldown - repmat(nanmedian(pulldown,2), 1, num_worked));

Data.pulldown = Data.pulldown ./ (1.4826 * repmat(mad(pulldown',1)', 1, num_worked));

dlmwrite([data_key '_after_rowzscores.txt'], Data.pulldown, '\t');

frowstats = fopen([data_key '_row_stats.txt'],'w');
row_median = nanmedian(pulldown,2);
row_mad = 1.4826 * mad(pulldown',1)';
row_mad_incorrect = 1.4826 * mad(pulldown')';
row_mean = nanmean(pulldown,2);
row_std = nanstd(pulldown')';
for ii=1:array_size
        fprintf(frowstats,'%s\t%f\t%f\t%f\t%f\t%f\n',Data.rowlabels{ii}, row_mean(ii),row_std(ii),  row_median(ii), row_mad(ii), row_mad_incorrect(ii));
end
fclose(frowstats);



Data.pulldown_col = zeros(size(pulldown,1), num_worked);

fcolstats = fopen([data_key '_col_stats.txt'],'w')

for ii=1:num_worked
    Data.pulldown_col(:,ii) = (Data.pulldown(:,ii) - nanmedian(Data.pulldown(:,ii))) ./ (1.4826 * mad(Data.pulldown(:,ii),1));
    fprintf(fcolstats,'%s\t%f\t%f\t%f\t%f\t%f\n', Data.collabels{ii},nanmean(Data.pulldown(:,ii)),nanstd(Data.pulldown(:,ii)), nanmedian(Data.pulldown(:,ii)),mad(Data.pulldown(:,ii),1) * 1.4826, mad(Data.pulldown(:,ii)) * 1.4826);
end
fclose(fcolstats)


write_data_matrix(Data, outfilename, col_type);

% SEVENMER ANALYSIS
load 7mer_data.mat
sevenmerfileA = ['7mer_scores_' key '_setA.txt'];
sevenmerfileB = ['7mer_scores_' key '_setB.txt'];

nmer_scores = nmer_analysis_final(Data, hs_7, sevenmerfileA, sevenmerfileB, trim_cutoff, col_type, trim_type,0);

setAnmers_quant = load_Nmer_data(sevenmerfileA);
setBnmers_quant = load_Nmer_data(sevenmerfileB);


[tmp, order] = sort(setAnmers_quant.collabels);
setAnmers_quant.collabels = tmp;
setAnmers_quant.data = setAnmers_quant.data(:, order);

[tmp, order] = sort(setBnmers_quant.collabels);
setBnmers_quant.collabels = tmp;
setBnmers_quant.data = setBnmers_quant.data(:, order);

sevenmerfileA = ['7mer_trimmedmeans_setA_' key '.txt'];
sevenmerfileB = ['7mer_trimmedmeans_setB_' key '.txt'];


write_norm_7mer_data(setAnmers_quant,setAnmers_quant.data,sevenmerfileA,['_' key]);
write_norm_7mer_data(setBnmers_quant,setBnmers_quant.data,sevenmerfileB,['_' key]);


