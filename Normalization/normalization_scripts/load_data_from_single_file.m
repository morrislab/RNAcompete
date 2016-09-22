function Data = load_data_from_single_file(filedescriptor)

load metadata.mat

Data.set = Metadata.set;
Data.seqs = Metadata.seqs;
Data.rows = Metadata.rows;
Data.cols = Metadata.cols;

clear Metadata;
    
Data.collabels = {};
display(sprintf('Loading %s\n', filedescriptor));

% load first line only to get channel names
fid = fopen(filedescriptor, 'r');
topLine = fgetl(fid);
fclose(fid);
cc = strread(topLine, '%s', 'delimiter', '\t');
numsamples = (size(cc,1) - 1)/2;

display(sprintf('%u protein+pool samples in file %s\n',numsamples,filedescriptor));

for d = 1:numsamples
	Data.collabels{d} = cc{1+d*2};
end



% read array data, flags and channel names
formatlabels = strcat('%s',repmat(' %*s',1,numsamples*2));
%display(sprintf('%s is the label format string\n',formatlabels));

formatdata = strcat('%*s',repmat(' %f %*s',1,numsamples));
%display(sprintf('%s is the data format string\n',formatdata));

formatflags = strcat('%*s',repmat(' %*s %f',1,numsamples));
%display(sprintf('%s is the flags format string\n',formatflags));

fid = fopen(filedescriptor, 'r');
probeids = textscan(fid, formatlabels, 'HeaderLines', 1, 'Delimiter', '\t');
fclose(fid);

probleids = probeids{1,1};

Data.rowlabels = probleids;
%Data.data = zeros(length(Data.rowlabels), 2*length(Data.collabels));
Data.flags = zeros(length(Data.rowlabels), 2*length(Data.collabels));

fid = fopen(filedescriptor, 'r');
datacell = textscan(fid, formatdata, 'headerlines', 1, 'delimiter', '\t');
fclose(fid);
fid = fopen(filedescriptor, 'r');
flagcell = (textscan(fid, formatflags, 'headerlines', 1, 'delimiter', '\t'));
fclose(fid);


%Data.data = cell2mat(datacell);
Data.pulldown = cell2mat(datacell);
Data.flags = cell2mat(flagcell);

save('raw_data.mat')
