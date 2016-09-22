function write_data_matrix(Data, fname, col_type)
%function write_data_matrix(Data, fname)
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
if(strcmp(col_type,'col') & isfield(Data,'pulldown_col'))
	Data.pulldown = Data.pulldown_col;
end
len = length(Data.collabels);

fid = fopen(fname, 'w');
fprintf(fid,'Probe_ID');
for ii = 1:length(Data.collabels)
  fprintf(fid, '\t %s', Data.collabels{ii});
end
fprintf(fid, '\n');


for ii = 1:length(Data.rowlabels)
  fprintf(fid, '%s', Data.rowlabels{ii});
  fprintf(fid, [repmat('\t %f',1,len)],  Data.pulldown(ii,:));
  fprintf(fid, '\n');
end

fclose(fid);
