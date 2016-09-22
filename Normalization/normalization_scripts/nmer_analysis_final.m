function results =  nmer_analysis_final(Data, hs, outfileA, outfileB, trim, col_type, trim_type, cutoff) 

if(~isfield(Data, 'pulldown'))

    if(isfield(Data, 'ratios'))
        Data.pulldown = Data.ratios;
        Data.ratios = [];
    end

    if(isfield(Data, 'data'))
        Data.pulldown = Data.data;
        Data.data = [];
    end
end
if(strcmp(col_type, 'col'))
	Data.pulldown = Data.pulldown_col;
end


% if cutoff is specified
if nargin == 8
    Data.pulldown(Data.pulldown<cutoff) = 0;
end

SetA_indices = find(strcmp(hs.set, 'SetA'));
SetB_indices = find(strcmp(hs.set, 'SetB'));

hs_A_data = hs.data(SetA_indices,:);
hs_B_data = hs.data(SetB_indices,:);



numExps = size(Data.pulldown,2);
num_nmers = size(hs.data,2);

nmer_scores_A = zeros(numExps,num_nmers);

nmer_scores_B = zeros(numExps,num_nmers);

%numExps =1;
for i=1:numExps
    
    for n = 1:num_nmers
        [rr cc ss] = find(hs_A_data(:,n));
         
        current_intensities = Data.pulldown(SetA_indices(rr),i);
        if(strcmp(trim_type,'median'))
		nmer_score = nanmedian(current_intensities);
	else
		nmer_score = trimmean(current_intensities, trim);
	end
        nmer_scores_A(i, n) = nmer_score;
      
    end

    for n = 1:num_nmers
        [rr cc ss] = find(hs_B_data(:,n));
       
        current_intensities = Data.pulldown(SetB_indices(rr),i);
        if(strcmp(trim_type,'median'))
                nmer_score = nanmedian(current_intensities);
        else
                nmer_score = trimmean(current_intensities, trim);
        end

	nmer_scores_B(i, n) = nmer_score;
    %    num_rr_B(i, n) = length(rr);
    end
 
end

results.nmer_scores_A  = nmer_scores_A;

results.nmer_scores_B = nmer_scores_B;


len = length(Data.collabels);
display(len)

fid = fopen(outfileA, 'w');
fprintf(fid,'Nmer');
for i = 1:numExps
    fprintf(fid, '\t %s', Data.collabels{i});
end
fprintf(fid, '\n');


for n = 1:num_nmers
    fprintf(fid, '%s', hs.collabels{n});
    fprintf(fid, [repmat('\t %f',1,len)],  nmer_scores_A(:,n));
    fprintf(fid, '\n');
end
fclose(fid);


fid = fopen(outfileB, 'w');
fprintf(fid,'Nmer');
for i = 1:numExps
    fprintf(fid, '\t %s', Data.collabels{i});
end
fprintf(fid, '\n');


for n = 1:num_nmers
    fprintf(fid, '%s', hs.collabels{n});
    fprintf(fid, [repmat('\t %f',1,len)],  nmer_scores_B(:,n));
    fprintf(fid, '\n');
end
fclose(fid);
