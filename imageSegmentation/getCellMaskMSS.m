% [cellMask cellBoundary] = getCellMaskMSS(img, varargin) estimates the cell mask/outline using multi-scale steerable filters
%
% Inputs:
%             img : input image
% 
% Options:
%        'Scales' : vector of scales (sigma) used by the filter. Default: [1 2 4].
%   'FilterOrder' : order of the filters. Default: 3.
%  'RemoveRadius' : radius of the final erosion/refinement step
%
% Outputs:
%        cellMask : binary mask of the cell 
%    cellBoundary : binary mask of the cell outline

% Francois Aguet, September 2011 (last modified: 10/23/2011)

function [cellMask, cellBoundary] = getCellMaskMSS(img, varargin)

ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('img');
ip.addParamValue('Scales', [1 2 4], @isvector);
ip.addParamValue('FilterOrder', 3, @(x) ismember(x, [1 3 5]));
ip.addParamValue('SearchRadius', 6, @isscalar);
ip.addParamValue('NormalizeResponse', false, @islogical);
ip.addParamValue('Mask', []);
ip.parse(img, varargin{:});
scales = ip.Results.Scales;

[ny,nx] = size(img);
% ordered index, column-order CCW
borderIdx = [1:ny 2*ny:ny:(nx-1)*ny nx*ny:-1:(nx-1)*ny+1 (nx-2)*ny+1:-ny:ny+1];
borderMask = zeros(ny,nx);
borderMask(borderIdx) = 1;

%------------------------------------------------------------------------------
% I. Multi-scale steerable filter
%------------------------------------------------------------------------------
[res, theta, nms] = multiscaleSteerableDetector(img, ip.Results.FilterOrder, scales);

if ip.Results.NormalizeResponse
    res = res ./ filterGauss2D(res, 5);
    %nms = nonMaximumSuppression(res, theta);
    % -or-
    nms = (nms~=0).*res; % better
end

% Mask of candidate edges
edgeMask = double(bwmorph(nms~=0, 'thin'));

% Break any Y or higher order junctions
nn = (imfilter(edgeMask, ones(3), 'same')-1) .* edgeMask;

junctionMatrix = nn>2;
segmentMatrix = edgeMask .* ~junctionMatrix;

% endpoints of all segments
endpointMatrix = (imfilter(segmentMatrix, ones(3), 'same')-1) .* segmentMatrix;
endpointMatrix = endpointMatrix==1;

% generate list of segments and add associated properties
CC = bwconncomp(segmentMatrix, 8);

% identify and remove single pixels, update segment matrix
csize = cellfun(@numel, CC.PixelIdxList);
singletonIdx = CC.PixelIdxList(csize==1);
segmentMatrix([singletonIdx{:}]) = 0;
CC.PixelIdxList(csize==1) = [];
CC.NumObjects = numel(CC.PixelIdxList);
csize(csize==1) = [];

% labels of connected components
labels = double(labelmatrix(CC));

% order the pixels of each segment from one endpoint to the other
nn = (imfilter(segmentMatrix, ones(3), 'same')-1) .* segmentMatrix;
PixelIdxList = vertcat(CC.PixelIdxList{:});
endpointIdxList = PixelIdxList(nn(PixelIdxList)==1);
% each segment has two endpoints
endpointIdxList = [endpointIdxList(1:2:end) endpointIdxList(2:2:end)];
tmp = NaN(CC.NumObjects,2);
tmp(labels(endpointIdxList(:,1)),:) = endpointIdxList;
endpointIdxList = tmp;

tmp = endpointIdxList(:,1);
D = bwdistgeodesic(logical(segmentMatrix), tmp(~isnan(tmp)));
D(isinf(D)) = 0;
CC.PixelOrder = mat2cell(D(PixelIdxList)+1, csize, 1);
CC.endpointIdx = mat2cell(endpointIdxList, ones(size(endpointIdxList,1),1), 2);
for i = 1:CC.NumObjects
    CC.PixelIdxList{i} = CC.PixelIdxList{i}(CC.PixelOrder{i});
end
PixelIdxList = vertcat(CC.PixelIdxList{:});

% compute intensity on side of all segments
angleVect = theta(PixelIdxList);
cost = cos(angleVect);
sint = sin(angleVect);
[x,y] = meshgrid(1:nx,1:ny);
% 'positive' or 'right' side
[yi, xi] = ind2sub([ny nx], PixelIdxList);
X = [xi+cost xi+2*cost];
Y = [yi+sint yi+2*sint];
interp2(x, y, img, X, Y);
CC.rval = mat2cell(interp2(x, y, img, X, Y), csize, 2);
% 'negative' or 'left' side
X = [xi-cost xi-2*cost];
Y = [yi-sint yi-2*sint];
CC.lval = mat2cell(interp2(x, y, img, X, Y), csize, 2);

%hval = zeros(1,CC.NumObjects);
%for k = 1:CC.NumObjects
%    hval(k) = kstest2(CC.rval{k}(:), CC.lval{k}(:));
%end

%------------------------------------------------------------------------------
% II. Rough estimate of the cell outline based on threshold: coarseMask
%------------------------------------------------------------------------------
coarseMask = ip.Results.Mask;
if isempty(coarseMask)
    % threshold 1st mode (background) of histogram
    img_smooth = filterGauss2D(img, 1);
    T = thresholdFluorescenceImage(img_smooth);
    coarseMask = double(img_smooth>T);
    coarseMask = bwmorph(coarseMask, 'fill'); % clean up isolated negative pixels
end
% get boundary from this mask
bdrVect = bwboundaries(coarseMask);
bdrVect = vertcat(bdrVect{:});
coarseBdr = zeros(ny,nx);
coarseBdr(sub2ind([ny nx], bdrVect(:,1), bdrVect(:,2))) = 1;

% endpoints/intersection of boundary w/ border
borderIS = coarseBdr & borderMask;
borderIS = double(borderIS(borderIdx));
borderIS = borderIdx((conv([borderIS(end) borderIS borderIS(1)], [1 1 1], 'valid')-1)==1);

% clean up, remove image border, add intersects
coarseBdr = bwmorph(coarseBdr, 'thin');
coarseBdr(borderIdx) = 0;
coarseBdr(borderIS) = 1;

edgeSearchMask = imdilate(coarseBdr, strel('disk', 20)); % dilation is arbitrary...

% labels within search area
idx = unique(labels.*edgeSearchMask);
idx(idx==0) = []; % remove background label

% update connected components list
CC.NumObjects = numel(idx);
CC.PixelIdxList = CC.PixelIdxList(idx);
csize = csize(idx);

% mask with average intensity of each segment
avgInt = cellfun(@(px) sum(nms(px)), CC.PixelIdxList) ./ csize;
edgeMask = zeros(ny,nx);
for k = 1:CC.NumObjects
    edgeMask(CC.PixelIdxList{k}) = avgInt(k);
end

% Some of the edges are background noise -> bimodal distribution of edge intensities
val = nms(edgeMask~=0); % intensities of edges
minv = min(val);
maxv = max(val);
T = graythresh(scaleContrast(val, [], [0 1]));
T = T*(maxv-minv)+minv;

% initial estimate of cell contour
cellBoundary = edgeMask > T;
% cellBoundary = edgeMask > min(T, thresholdRosin(val));
%cellBoundary = edgeMask;

% 1st graph matching based on orientation at endpoints, with small search radius
[matchedMask] = matchSegmentEndPoints(cellBoundary, theta, 'SearchRadius', ip.Results.SearchRadius, 'Display', false);

% The connected components in this mask are no longer segments. For the next matching 
% steps, the two outermost endpoints are needed.

% find endpoint candidates on skeleton
nn = double(bwmorph(matchedMask, 'thin'));
nn = (imfilter(nn, ones(3), 'same')-1) .* nn;
endpointMatrix = nn==1;
endpointIdx = find(endpointMatrix);

% calculate new connected components
CC = bwconncomp(matchedMask, 8);
for k = 1:CC.NumObjects
    CC.endpointIdx{k} = intersect(CC.PixelIdxList{k}, endpointIdx);
end

% retain the two endpoints that are furthest apart for later matching
nEndpoint = cellfun(@numel, CC.endpointIdx);
for k = 1:max(nEndpoint)
    idx = find(nEndpoint>=max(3,k));
    % seed point indexes
    sp = cellfun(@(x) x(k), CC.endpointIdx(idx));
    seedMatrix = false(ny,nx);
    seedMatrix(sp) = true;
    D = bwdistgeodesic(matchedMask, seedMatrix);
    for i = 1:numel(idx)
        CC.endpointDist{idx(i)}(k) = max(D(CC.PixelIdxList{idx(i)}));
    end    
end
idx = find(nEndpoint>2);
for k = 1:numel(idx)
    [~,si] = sort(CC.endpointDist{idx(k)}, 'descend');
    [~,si] = sort(si, 'descend');
    CC.endpointIdx{idx(k)} = CC.endpointIdx{idx(k)}(si<=2);
end
if isfield(CC, 'endpointDist') % ! clean this mess up at some point !
    CC = rmfield(CC, 'endpointDist');
end
matchedMask = double(matchedMask);

csize = cellfun(@numel, CC.PixelIdxList);
avgInt = cellfun(@(px) sum(res(px)), CC.PixelIdxList) ./ csize;
for k = 1:CC.NumObjects
    matchedMask(CC.PixelIdxList{k}) = avgInt(k);
    %CC.isSegment(k) = max(nn(CC.PixelIdxList{k}))<3;
    %CC.endpointIdx{k} = intersect(CC.PixelIdxList{k}, endpointIdx);
    if isempty(CC.endpointIdx{k})
        CC.endpointIdx{k} = CC.PixelIdxList{k}(1);
    end
end

% get intensity information adjacent to each segment
CC = computeSegmentProperties(CC, img, theta);
labels = double(labelmatrix(CC));

% re-order interpolated intensities such that the lower intensities are always in 'lval'
for k = 1:CC.NumObjects
    rmean = nanmean(CC.rval{k}(:));
    lmean = nanmean(CC.lval{k}(:));
    if rmean<lmean
        tmp = CC.rval{k};
        CC.rval{k} = CC.lval{k};
        CC.lval{k} = tmp;
    end
end


matchesFound = true;
iter = 0;
while matchesFound
    
    % for each remaining endpoint, find closest edge and get its label
    endpointIdx = vertcat(CC.endpointIdx{:});
    endpointLabel = labels(endpointIdx);
    pidx = vertcat(CC.PixelIdxList{:});
    [yi, xi] = ind2sub([ny nx], pidx);
    X = [xi yi];
    [yi, xi] = ind2sub([ny nx], endpointIdx);
    [idx, dist] = KDTreeBallQuery(X, [xi yi], 10); % ! make this a parameter !
    matchList = zeros(0,2);
    for k = 1:numel(endpointLabel)
        % remove self queries
        rmIdx = labels(pidx(idx{k}))==endpointLabel(k);
        idx{k}(rmIdx) = [];
        dist{k}(rmIdx) = [];
        % label of closest point
        if ~isempty(idx{k})
            imatch = sort([endpointLabel(k) labels(pidx(idx{k}(1)))]);
            if ~any(matchList(:,1)==imatch(1) & matchList(:,2)==imatch(2))
                matchList = [matchList; imatch];
            end
        end
    end
    [~,idx] = sort(matchList(:,1));
    matchList = matchList(idx,:);
    
    % cost based on KS distance
    cost = zeros(size(matchList,1),1);
    for k = 1:size(matchList,1)
        [~,~,ksLL] = kstest2(CC.lval{matchList(k,1)}(:), CC.lval{matchList(k,2)}(:));
        [~,~,ksHH] = kstest2(CC.rval{matchList(k,1)}(:), CC.rval{matchList(k,2)}(:));
        
        %[~,~,ks1] = kstest2(CC.lval{matchList(k,1)}(:), CC.rval{matchList(k,1)}(:));
        %[~,~,ks2] = kstest2(CC.lval{matchList(k,2)}(:), CC.rval{matchList(k,2)}(:));
        
        cost(k) = 1-max([ksLL ksHH]);
        %cost(k) = 1-mean([ksLL ksHH]);
        
        % penalize cost when left/right distributions of a segment are close
        %cost(k) = cost(k) * min(ks1,ks2);
        %cost(k) = cost(k) * (1-(1-ks1)*(1-ks2));
        
    end
    rmIdx = cost<0.2;
    matchList(rmIdx,:) = [];
    cost(rmIdx) = [];

    M = maxWeightedMatching(CC.NumObjects, matchList, cost); % returns index (M==true) of matches
    matchList = matchList(M,:);
    if isempty(matchList)
        matchesFound = false;
    end
    
    % rudimentary linking between matched pairs: shortest projection
    for k = 1:size(matchList,1)
        imatch = zeros(2,3); % distance, endpoint idx, matched pixel idx
        newEP = [];
        
        [yi, xi] = ind2sub([ny nx], CC.PixelIdxList{matchList(k,1)});
        X = [xi yi];
        [yi, xi] = ind2sub([ny nx], CC.endpointIdx{matchList(k,2)});
        [idx, dist] = KDTreeClosestPoint(X, [xi, yi]);
        i = find(dist==min(dist), 1, 'first');
        imatch(1,:) = [dist(i) CC.endpointIdx{matchList(k,2)}(i) CC.PixelIdxList{matchList(k,1)}(idx(i))];
        newEP = [newEP; CC.endpointIdx{matchList(k,2)}(setdiff(1:numel(dist), i))];
        
        [yi, xi] = ind2sub([ny nx], CC.PixelIdxList{matchList(k,2)});
        X = [xi yi];
        [yi, xi] = ind2sub([ny nx], CC.endpointIdx{matchList(k,1)});
        [idx, dist] = KDTreeClosestPoint(X, [xi, yi]);
        i = find(dist==min(dist), 1, 'first');
        imatch(2,:) = [dist(i) CC.endpointIdx{matchList(k,1)}(i) CC.PixelIdxList{matchList(k,2)}(idx(i))];
        newEP = [newEP; CC.endpointIdx{matchList(k,1)}(setdiff(1:numel(dist), i))];
        
        i = find(imatch(:,1)==min(imatch(:,1)), 1, 'first');
        imatch = imatch(i,:);
        
        % add connection to matchedMask
        [y0, x0] = ind2sub([ny nx], imatch(2));
        [y1, x1] = ind2sub([ny nx], imatch(3));
        iseg = bresenham([x0 y0], [x1 y1]);
        iseg = sub2ind([ny nx], iseg(:,2), iseg(:,1));
        
        matchedMask(iseg) = 1;
        
        % merge CCs
        CC.endpointIdx{matchList(k,1)} = newEP;
        CC.endpointIdx{matchList(k,2)} = [];
        CC.PixelIdxList{matchList(k,1)} = [CC.PixelIdxList{matchList(k,1)}; iseg; CC.PixelIdxList{matchList(k,2)}];
        CC.PixelIdxList{matchList(k,2)} = [];
        %CC.rawAngle{matchList(k,1)} = [CC.rawAngle{matchList(k,1)} CC.rawAngle{matchList(k,2)}];
        CC.rval{matchList(k,1)} = [CC.rval{matchList(k,1)}; CC.rval{matchList(k,2)}];
        CC.rval{matchList(k,2)} = [];
        CC.lval{matchList(k,1)} = [CC.lval{matchList(k,1)}; CC.lval{matchList(k,2)}];
        CC.lval{matchList(k,2)} = [];
        
        % update labels
        labels(CC.PixelIdxList{matchList(k,1)}) = matchList(k,1);
    end
    iter = iter + 1;
end

% score edges: background vs. foreground

% endpoints of foreground edges


img0 = scaleContrast(img);
img1 = img0;
img0(matchedMask~=0) = 0;
img1(matchedMask~=0) = 255;
rgb = uint8(cat(3, img1, img0, img0));
figure; imagesc(rgb); colormap(gray(256)); axis image; colorbar;

%figure; imagesc(rgbOverlay(img, matchedMask, [1 0 0])); colormap(gray(256)); axis image; colorbar;

cellMask = [];
return







%------------------------------------------------------------------------------
% III. Join remaining segments/endpoints using graph matching
%------------------------------------------------------------------------------

% Remove long spurs
cellBoundary = bwmorph(cellBoundary, 'thin');
cellBoundary = bwmorph(cellBoundary, 'spur', 100);
cellBoundary = bwmorph(cellBoundary, 'clean'); % spur leaves single pixels -> remove

% Create mask, use largest connected component within coarse threshold (removes potential loops in boundary)
maskCC = bwconncomp(~cellBoundary, 4);
csize = cellfun(@(c) numel(c), maskCC.PixelIdxList);
[~,idx] = sort(csize, 'descend');
% two largest components: cell & background
int1 = mean(img(maskCC.PixelIdxList{idx(1)}));
int2 = mean(img(maskCC.PixelIdxList{idx(2)}));
cellMask = zeros(ny,nx);
if int1 > int2
    cellMask(maskCC.PixelIdxList{idx(1)}) = 1;
else
    cellMask(maskCC.PixelIdxList{idx(2)}) = 1;
end

% loop through remaining components, check whether part of foreground or background
for i = idx(3:end)
    px = coarseMask(maskCC.PixelIdxList{i});
    if sum(px) > 0.6*numel(px)
        cellMask(maskCC.PixelIdxList{i}) = 1;
    end
end
cellMask = imdilate(cellMask, strel('disk',1));

% Optional: erode filopodia-like structures
if ~isempty(ip.Results.RemoveRadius)
    cellMask = imopen(cellMask, strel('disk', ip.Results.RemoveRadius));
end
    
% Final contour: pixels adjacent to mask
B = bwboundaries(cellMask);
cellBoundary = zeros(ny,nx);
cellBoundary(sub2ind([ny nx], B{1}(:,1), B{1}(:,2))) = 1;



function out = connectEndpoints(inputPoints, queryPoints, radius, labels, cellBoundary, updateBoundary)
if nargin<6
    updateBoundary = true;
end

dims = size(cellBoundary);
out = zeros(dims);
nq = size(queryPoints,1);
[idx, dist] = KDTreeBallQuery(inputPoints, queryPoints, radius);

labSelf = labels(sub2ind(dims, queryPoints(:,2), queryPoints(:,1)));
labAssoc = cellfun(@(i) labels(sub2ind(dims, inputPoints(i,2), inputPoints(i,1))), idx, 'UniformOutput', false);

% idx of endpoints belonging to other edges
otherIdx = arrayfun(@(i) labAssoc{i}~=labSelf(i), 1:nq, 'UniformOutput', false);

% remove segment self-association (and thus query self-association)
idx = arrayfun(@(i) idx{i}(otherIdx{i}), 1:nq, 'UniformOutput', false);
dist = arrayfun(@(i) dist{i}(otherIdx{i}), 1:nq, 'UniformOutput', false);

% generate edge map
E = arrayfun(@(i) [repmat(i, [numel(idx{i}) 1]) idx{i}], 1:nq, 'UniformOutput', false);
E = vertcat(E{:});

if ~isempty(E)
    idx = E(:,1) < E(:,2);
    
    E = E(idx,:); % remove redundancy
    
    % generate weights
    D = vertcat(dist{:});
    D = D(idx);
    
    D = max(D)-D;
    M = maxWeightedMatching(size(inputPoints,1), E, D);
    
    E = E(M,:);
    
    % add linear segments corresponding to linked endpoints
    for i = 1:size(E,1)
        iseg = bresenham([queryPoints(E(i,1),1) queryPoints(E(i,1),2)],...
            [inputPoints(E(i,2),1) inputPoints(E(i,2),2)]);
        out(sub2ind(dims, iseg(:,2), iseg(:,1))) = 1;
    end
end

if updateBoundary
    out = double(out | cellBoundary);
end
