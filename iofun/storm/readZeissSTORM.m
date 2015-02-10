function stormData = readZeissSTORM(fileName)
%READZEISSSTORM Imports Zeiss STORM localization data from text file
%
%   stormData = readZeissSTORM
%   stormData = readZeissSTORM(fileName)
%   
%   Reads Zeiss storm localization files (text format). Note that these are
%   NOT the synthetic STORM images, but the raw localizations.
%   
%   Output:
%       stormData - structure with fields containing different storm data
%       fields, named in accordance with their name in the file. Most of
%       these are self-explanatory.
%
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2015/01/15 10:20:52, modified by Hunter
% Elliott 1/2015


%% Initialize variables.
delimiter = '\t';
if nargin<=2
    startRow = 2;
    endRow = Inf;
end


%% Open the text file.

if nargin < 1
    fileName = '';
end

[filePath,fileName] = optionalFileInput(fileName,'*.txt','Select the storm localization file to open:');

fileName = [filePath fileName];

%% check file type

assert(isFileZeissSTORM(fileName),'Incorrect file format!')

fileID = fopen(fileName,'r');

%% ---- Determine number of localizations ---- %%

%Because zeiss puts extra, differently formatted info at the END of the
%file, we do this stupid workaround of reading the second column first to
%get the number of localizations (using matlabs suggested method of reading
%all as strings and then converting is SLOW)

formatSpec = '%*s%f%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%[^\n\r]';

textscan(fileID, '%[^\n\r]', startRow(1)-1, 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'ReturnOnError', true);

%Now use this to determine the number of rows to read below
endRow = find(~isnan(dataArray{1}),1,'last')+startRow-1;

fclose(fileID);%Close so that the blocks below start at beginning of file. It's already a kludgy function anyways....

%% Format string for each line of text:
%   column1: double (%f)
%	column2: double (%f)
%   column3: double (%f)
%	column4: double (%f)
%   column5: double (%f)
%	column6: double (%f)
%   column7: double (%f)
%	column8: double (%f)
%   column9: double (%f)
%	column10: double (%f)
%   column11: double (%f)
%	column12: double (%f)
%   column13: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.

fileID = fopen(fileName,'r');

textscan(fileID, '%[^\n\r]', startRow(1)-1, 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    textscan(fileID, '%[^\n\r]', startRow(block)-1, 'ReturnOnError', false);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Allocate imported array to column variable names
stormData.Index = dataArray{:, 1};
stormData.FirstFrame = dataArray{:, 2};
stormData.NumberFrames = dataArray{:, 3};
stormData.FramesMissing = dataArray{:, 4};
stormData.PositionXnm = dataArray{:, 5};
stormData.PositionYnm = dataArray{:, 6};
stormData.Precisionnm = dataArray{:, 7};
stormData.NumberPhotons = dataArray{:, 8};
stormData.Backgroundvariance = dataArray{:, 9};
stormData.Chisquare = dataArray{:, 10};
stormData.PSFwidthnm = dataArray{:, 11};
stormData.Channel1 = dataArray{:, 12};
stormData.ZSlice = dataArray{:, 13};

