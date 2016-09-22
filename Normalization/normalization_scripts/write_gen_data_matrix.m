function write_gen_data_matrix(Data, fname)

len = length(Data.collabels);

fid = fopen(fname, 'w');
fprintf(fid,'Nmer');
for ii = 1:length(Data.collabels)
  fprintf(fid, '\t %s', Data.collabels{ii});
end
fprintf(fid, '\n');

for ii = 1:length(Data.rowlabels)
  fprintf(fid, '%s', Data.rowlabels{ii});
  fprintf(fid, [repmat('\t %f',1,len)],  Data.data(ii,:));  
  fprintf(fid, '\n');
end

fclose(fid);
