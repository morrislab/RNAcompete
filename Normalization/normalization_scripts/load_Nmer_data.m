function Data = load_Nmer_data(filedescriptor)


Data.collabels = {};
display(sprintf('Loading %s\n', filedescriptor));
	
% load RBP headers
fid = fopen(filedescriptor, 'r');
topLine = fgetl(fid);
fclose(fid);
cc = strread(topLine, '%s', 'delimiter', '\t');
numsamples = (size(cc,1)-1); % changed

display(sprintf('%u RBPs in file %s\n',numsamples,filedescriptor));

for d = 1:numsamples
	Data.collabels{d} = cc{1+d}; % changed
end



% read Nmer data
formatlabels = strcat('%s',repmat(' %*s',1,numsamples));
formatmeans = strcat('%*s',repmat(' %f',1,numsamples));


fid = fopen(filedescriptor, 'r');
Nmers = textscan(fid, formatlabels, 'HeaderLines', 1, 'Delimiter', '\t');
fclose(fid);
Nmers = Nmers{1,1};

Data.rowlabels = Nmers;
Data.data = zeros(length(Data.rowlabels), length(Data.collabels));

fid = fopen(filedescriptor, 'r');
meancell = textscan(fid, formatmeans, 'headerlines', 1, 'delimiter', '\t');
fclose(fid);

Data.data = cell2mat(meancell);



