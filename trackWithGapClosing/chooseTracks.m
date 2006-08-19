function [trackIndx,errFlag] = chooseTracks(trackedFeatureInfo,criteria)
%CHOOSETRACKS outputs the indices of tracks that satisfy the input criteria
%
%SYNOPSIS [trackIndx,errFlag] = chooseTracks(trackedFeatureInfo,criteria);
%
%INPUT  trackedFeatureInfo: Matrix indicating the positions and amplitudes 
%                           of the tracked features to be plotted. Number 
%                           of rows = number of tracks, while number of 
%                           columns = 8*number of time points. Each row 
%                           consists of 
%                           [x1 y1 z1 a1 dx1 dy1 dz1 da1 x2 y2 z2 a2 dx2 dy2 dz2 da2 ...]
%                           in image coordinate system (coordinates in
%                           pixels). NaN is used to indicate time points 
%                           where the track does not exist.
%       criteria          : Structure with fields:
%           .lifeTime        :Structure with fields:
%               .min            :minimum lifetime.
%               .max            :maximum lifetime.
%           .startTime       :Structure with fields:
%               .min            :minimum start time.
%               .max            :maximum start time.
%           .endTime         :Structure with fields:
%               .min            :minimum end time.
%               .max            :maximum end time.
%           .initialAmp      :Structure with fields:
%               .min            :minimum initial amplitude.
%               .max            :maximum initial amplitude.
%           .initialXCoord   :Structure with fields:
%               .min            :minimum x-coordinate.
%               .max            :maximum x-coordinate.
%           .initialYCoord   :Structure with fields:
%               .min            :minimum y-coordinate.
%               .max            :maximum y-coordinate.
%           .initialZCoord   :Structure with fields:
%               .min            :minimum z-coordinate.
%               .max            :maximum z-coordinate.
%                           All criteria are optional. Leave out or give as
%                           [] if not of interest.
%
%OUTPUT trackIndx         : Indices of tracks that satisfy the input criteria.
%       errFlag           : 0 if function executes normally, 1 otherwise
%
%Khuloud Jaqaman, August 2006

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

trackIndx = [];
errFlag = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%check whether correct number of input arguments was used
if nargin < 2
    disp('--chooseTracks: Incorrect number of input arguments!');
    errFlag = 1;
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Track indices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%get number of tracks and time points
numTracks = size(trackedFeatureInfo,1);

%get track start, end and life times
trackSEL = getTrackSEL(trackedFeatureInfo);

%initialize vector of track indices
trackIndx = ones(numTracks,1);

%Check lifetime criterion
if isfield(criteria,'lifeTime') && ~isempty(criteria.lifeTime)
    
    %find track lifetimes
    comparisonVec = trackSEL(:,3);

    %get minimum lifetime
    if isfield(criteria.lifeTime,'min') && ~isempty(criteria.lifeTime.min)
        minCrit = criteria.lifeTime.min;
    else
        minCrit = min(comparisonVec) - 1;
    end
    
    %get maximum lifetime
    if isfield(criteria.lifeTime,'max') && ~isempty(criteria.lifeTime.max)
        maxCrit = criteria.lifeTime.max;
    else
        maxCrit = max(comparisonVec) + 1;
    end
    
    %assign one to tracks that satisfy this criterion (plus all criteria above)
    trackIndx = trackIndx & comparisonVec >= minCrit & comparisonVec <= maxCrit;
end

%Check start time criterion
if isfield(criteria,'startTime') && ~isempty(criteria.startTime)
    
    %find track start times
    comparisonVec = trackSEL(:,1);

    %get minimum start time
    if isfield(criteria.startTime,'min') && ~isempty(criteria.startTime.min)
        minCrit = criteria.startTime.min;
    else
        minCrit = min(comparisonVec) - 1;
    end
    
    %get maximum start time
    if isfield(criteria.startTime,'max') && ~isempty(criteria.startTime.max)
        maxCrit = criteria.startTime.max;
    else
        maxCrit = max(comparisonVec) + 1;
    end
    
    %assign one to tracks that satisfy this criterion (plus all criteria above)
    trackIndx = trackIndx & trackSEL(:,1) >= minCrit & trackSEL(:,1) <= maxCrit;
end

%Check end time criterion
if isfield(criteria,'endTime') && ~isempty(criteria.endTime)
    
    %find track end times
    comparisonVec = trackSEL(:,2);

    %get minimum end time
    if isfield(criteria.endTime,'min') && ~isempty(criteria.endTime.min)
        minCrit = criteria.endTime.min;
    else
        minCrit = min(comparisonVec) - 1;
    end
    
    %get maximum end time
    if isfield(criteria.endTime,'max') && ~isempty(criteria.endTime.max)
        maxCrit = criteria.endTime.max;
    else
        maxCrit = max(comparisonVec) + 1;
    end
    
    %assign one to tracks that satisfy this criterion (plus all criteria above)
    trackIndx = trackIndx & trackSEL(:,2) >= minCrit & trackSEL(:,2) <= maxCrit;
end

%Check initial amplitude criterion
if isfield(criteria,'initialAmp') && ~isempty(criteria.initialAmp)
    
    %find initial amplitudes
    comparisonVec = zeros(numTracks,1);
    for i=1:numTracks
        comparisonVec(i) = trackedFeatureInfo(i,(trackSEL(i,1)-1)*8+4);
    end
    
    %get minimum initial amplitude
    if isfield(criteria.initialAmp,'min') && ~isempty(criteria.initialAmp.min)
        minCrit = criteria.initialAmp.min;
    else
        minCrit = min(comparisonVec) - 1;
    end
    
    %get maximum initial amplitude
    if isfield(criteria.initialAmp,'max') && ~isempty(criteria.initialAmp.max)
        maxCrit = criteria.initialAmp.max;
    else
        maxCrit = max(comparisonVec) + 1;
    end
    
    %assign one to tracks that satisfy this criterion (plus all criteria above)
    trackIndx = trackIndx & comparisonVec >= minCrit & comparisonVec <= maxCrit;
end

%Check initial x-coordinates
if isfield(criteria,'initialXCoord') && ~isempty(criteria.initialXCoord)
    
    %find initial x-coordinates
    comparisonVec = zeros(numTracks,1);
    for i=1:numTracks
        comparisonVec(i) = trackedFeatureInfo(i,(trackSEL(i,1)-1)*8+1);
    end
    
    %get minimum initial x-coordinate
    if isfield(criteria.initialXCoord,'min') && ~isempty(criteria.initialXCoord.min)
        minCrit = criteria.initialXCoord.min;
    else
        minCrit = min(comparisonVec) - 1;
    end
    
    %get maximum initial x-coordinate
    if isfield(criteria.initialXCoord,'max') && ~isempty(criteria.initialXCoord.max)
        maxCrit = criteria.initialXCoord.max;
    else
        maxCrit = max(comparisonVec) + 1;
    end
    
    %assign one to tracks that satisfy this criterion (plus all criteria above)
    trackIndx = trackIndx & comparisonVec >= minCrit & comparisonVec <= maxCrit;
end

%Check initial y-coordinates
if isfield(criteria,'initialYCoord') && ~isempty(criteria.initialYCoord)
    
    %find initial y-coordinates
    comparisonVec = zeros(numTracks,1);
    for i=1:numTracks
        comparisonVec(i) = trackedFeatureInfo(i,(trackSEL(i,1)-1)*8+2);
    end
    
    %get minimum initial y-coordinate
    if isfield(criteria.initialYCoord,'min') && ~isempty(criteria.initialYCoord.min)
        minCrit = criteria.initialYCoord.min;
    else
        minCrit = min(comparisonVec) - 1;
    end
    
    %get maximum initial y-coordinate
    if isfield(criteria.initialYCoord,'max') && ~isempty(criteria.initialYCoord.max)
        maxCrit = criteria.initialYCoord.max;
    else
        maxCrit = max(comparisonVec) + 1;
    end
    
    %assign one to tracks that satisfy this criterion (plus all criteria above)
    trackIndx = trackIndx & comparisonVec >= minCrit & comparisonVec <= maxCrit;
end

%Check initial z-coordinates
if isfield(criteria,'initialZCoord') && ~isempty(criteria.initialZCoord)
    
    %find initial z-coordinates
    comparisonVec = zeros(numTracks,1);
    for i=1:numTracks
        comparisonVec(i) = trackedFeatureInfo(i,(trackSEL(i,1)-1)*8+3);
    end
    
    %get minimum initial z-coordinate
    if isfield(criteria.initialZCoord,'min') && ~isempty(criteria.initialZCoord.min)
        minCrit = criteria.initialZCoord.min;
    else
        minCrit = min(comparisonVec) - 1;
    end
    
    %get maximum initial z-coordinate
    if isfield(criteria.initialZCoord,'max') && ~isempty(criteria.initialZCoord.max)
        maxCrit = criteria.initialZCoord.max;
    else
        maxCrit = max(comparisonVec) + 1;
    end
    
    %assign one to tracks that satisfy this criterion (plus all criteria above)
    trackIndx = trackIndx & comparisonVec >= minCrit & comparisonVec <= maxCrit;
end

%keep only the indices of tracks that satisfy all input criteria
trackIndx = find(trackIndx);


%%%%% ~~ the end ~~ %%%%%

