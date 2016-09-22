function write_norm_7mer_data(Data,normdata,fname,suffix)
%function write_data(Data, fname)
%
%  Write datas in the format:
%  probe name \t pool \t array 1 ratio \t array 2 ratio etc
%


%TmpData = zeros(length(Data.rowlabels), length(Data.collabels));
for ii = 1:length(Data.collabels)
    collabels{ii} = [Data.collabels{ii} suffix];
end
TmpData.rowlabels = Data.rowlabels;
TmpData.collabels = collabels;
TmpData.data = normdata;
fprintf('Writing %s data matrix to %s\n',suffix, fname);
write_gen_data_matrix(TmpData, fname);
clear TmpData.data;
clear TmpData.collabels;
clear TmpData;
