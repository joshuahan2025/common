function stormData = readNikonSTORM(filename)
%READNIKONSTORM Imports Nikon STORM localization data from text file
%       
%   stormData = readNikonSTORM
%   stormData = readNikonSTORM(fileName)
%   
%   Reads Nikon storm localization files (text format). Note that these are
%   NOT the synthetic STORM images, but the raw localizations.
%   
%   Output:
%       stormData - structure with fields containing different storm data
%       fields, named in accordance with their name in the file. Most of
%       these are self-explanatory, with these exceptions:
%
%           Xc/Yc - the drift-corrected X and Y localization coordinates.
%           (This is what you want to use most of the time, not the X / Y
%           fields)
%
%           
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2013/05/01 17:08:17, modified by Hunter
% Elliott 4/2013

%% Initialize variables.
delimiter = '\t';
startRow = 2;
endRow = inf;


%% Format string for each line of text:
%   column1: text (%s)
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
%	column14: double (%f)
%   column15: double (%f)
%	column16: double (%f)
%   column17: double (%f)
%	column18: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';

%% Open the text file.

if nargin < 1 || isempty(filename)
    [filename, filepath] = uigetfile('*.txt','Select the storm localization file to open:');
    filename = [filepath filename];
end

fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
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
stormData.ChannelName = dataArray{:, 1};
stormData.X = dataArray{:, 2};
stormData.Y = dataArray{:, 3};
stormData.Xc = dataArray{:, 4};
stormData.Yc = dataArray{:, 5};
stormData.Height = dataArray{:, 6};
stormData.Area1 = dataArray{:, 7};
stormData.Width = dataArray{:, 8};
stormData.Phi = dataArray{:, 9};
stormData.Ax = dataArray{:, 10};
stormData.BG = dataArray{:, 11};
stormData.I = dataArray{:, 12};
stormData.Frame = dataArray{:, 13};
stormData.Length = dataArray{:, 14};
stormData.Link = dataArray{:, 15};
stormData.Valid = dataArray{:, 16};
stormData.Z = dataArray{:, 17};
stormData.Zc = dataArray{:, 18};

