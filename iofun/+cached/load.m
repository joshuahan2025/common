function [ S , cached] = load( filename, varargin )
% function [ S , cached] = cached.load( filename, '-cacheFlag', '-loadFlag', variables )
%cached.load Emulates the built-in load but adds a caching facility so that
%subsequent loads read from memory rather than disk
%
% cached.load resolves the location of the MAT file indicated by filename
% and stores the contents in memory. The next request to load that MAT file
% is loaded from memory rather than the disk. 
%
% If any variables are indicated, then the cache is checked for those
% variables and loaded if necessary. This is highly recommended to
% ensure the needed variables are loaded.
%
% If all variables contained in the file are needed and variables are not
% listed, it is recommended that the -reset flag is used to ensure all
% variables are loaded at least once. Otherwise, only the previously
% requested variables may be returned. While this will not cache the
% current loading operation, it may assist subsequent loads.
%
% This function is faster if filename is an absolute path.
%
% Usage
% -----
% S = cached.load( ____ );
%     Just like the built-in load, caches the output
% S = cached.load(filename, '-reset', ____ )
%     resets the cache for filename
% S = cached.load(filename, '-useCache', false , ____ )
%     resets the cache for filename
% S = cached.load(filename, '-useCache', true , ____ )
%     same as loadCached(filename, _____)
% cached.load('-clear') 
%     clears the entire cache
%
% See also load
% 
% Output
% ------
% S is the structure output by load or empty
% cached is a logical flag indicating if the cached was used
%
% Mark Kittisopikul
% December 2014

% Outline
% 1. Process arguments and check version
% 2. Attempt to load from the cache
% 3. If cache is invalid, then load the file
% 4. Remove variables in the matfile that were not requested

persistent cache;

% reset is false by default
reset = false;
% S is empty as a flag if successfully loaded the cache
S = [];
cached = false;

%% 1. Process arguments

% First argument can be an optional argument to clear the entire cache
if(strcmp(filename,'-clear'))
    delete(cache);
    return;
end

forwarded = varargin;

for ii=1:length(varargin)
    switch(varargin{ii})
        case '-reset'
        % Second argument can be an optional reset flag which will clear the cache
        % corresponding to the other arguments
        
        % remove the -reset option since we do not want to forward it to load
            forwarded = varargin([1:ii-1 ii+1:end]);
            reset = true;
        case '-useCache'
        % Second argument can also be a -useCache parameter followed by a boolean
            assert(islogical(varargin{ii+1}),'-useCache must be followed by a logical');
            % if useCache == true, then do not reset. Reset otherwise.
            reset = ~varargin{ii+1};
            % remove the name/value since we do not want to forward it to load
            forwarded = varargin([1:ii-1 ii+2:end]);
        case '-clear'
            error('Argument -clear must be the first and only argument');
    end
end



% Create the cache if it has not been created
if(~isa(cache,'containers.Map') || ~isvalid(cache))
    % If we are using a version less than 2008b, then just load and do not
    % cache since containers.Map was not introduced until 2008b
    if(verLessThan('matlab','7.7'))
        S = load(filename,forwarded{:});
        return;
    else
        cache = containers.Map;
    end
end

% Options begin with a dash
isOption = strncmp(forwarded,'-',1);
options = forwarded(isOption);
% Variables do not begin with a dash
variables = forwarded(~isOption);

% Resolve the full file location
if(~cache.isKey(filename))
    filename = whichMatFile(filename);
end

% The Map key is the filename and options joined together
key = filename;
if(~isempty(options))
    key = strjoin( [filename options], ',');
end

if(reset && cache.isKey(key))
    cache.remove(key);
end


%% 2. Attempt to retrieve from the cache
if(cache.isKey(key))
    S = cache(key);
    cached = true;
    if(~isempty(variables) && any(~isfield(S,variables)))
        % if any of the requested variables are not present,
        % then update the cache
        newVariables = setdiff(variables,fields(S));
        newS = load(filename,options{:},newVariables{:});
        S = mergestruct(S,newS);
        cache(key) = S;
    end
end

%% 3. Cache is invalid so load it normally
if(isempty(S))
    S = load(filename,forwarded{:});
    cache(key) = S;
    cached = false;
end

%% 4. Limit output structure to only the variables requested
if(~isempty(variables))
    notRequested = setdiff(fields(S),variables);
    S = rmfield(S,notRequested);
end

end

