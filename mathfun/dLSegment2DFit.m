function [F J] = dLSegment2DFit(x, I, sigmaPSF)
% This function computes I - Im, where I is an image and Im is an image
% model defined by the sum of 2D diffraction-limited segment model
% caracterize by params x (see dLSegment2DImageModel.m for mode details).
% This function intends to be used as a function handler in lsqnonlin,
% lsqlin, etc. optimization functions.
%
% [F J] = dlSegment2DFit(x, I, sigmaPSF)
%
% Parameters:
% x            a nx5 matrix where n is the number of segments and their
%              parameters, i.e. xC, yC, A, l, t are stored column-wise (see
%              dLSegment2D.m for more details)
%
% I            image
%
% sigmaPSF     half width of the gaussian PSF model
%
% Output:
% F            F = I - model
%
% J            J is an MxN matrix where M = numel(I) and N = numel(x). This
%              correspond to the jacobian of I against x (see lsqnonlin for
%              mode details)

[n p] = size(x);

if p ~= 5
    error('Invalid number of segment parameters.');
end

[nrows ncols] = size(I);

m = nrows * ncols;
    
xRange = cell(n, 1);
yRange = cell(n, 1);

% The following loop could be simply replaced by:
% F = reshape(I - dlSegment2DImageModel(x, sigmaPSF, [nrows ncols]), m, 1)
% But we want to keep xRange yRange since they are required to compute J.

F = zeros(nrows,ncols);

for i = 1:n
    xC = x(i,1);
    yC = x(i,2);
    A = x(i,3);
    l = x(i,4);
    t = x(i,5);
    
    [xR yR] = dLSegment2DSupport(xC, yC, sigmaPSF, l, t);

    xRange{i} = max(xR(1),1):min(xR(end),size(Iu,2));
    yRange{i} = max(yR(1),1):min(yR(end),size(Iu,1));
    
    S = dLSegment2D(xRange{i}, yRange{i}, xC, yC, A, sigmaPSF, l, t);

    F(yRange,xRange) = I(yRange,xRange) - S;
end

F = F(:);

if nargout > 1
    indPixels = cell(n,1);
    indParams = cell(n,1);
    val = cell(n,1);    
    
    for i = 1:n
        xC = x(i,1);
        yC = x(i,2);
        A = x(i,3);
        l = x(i,4);
        t = x(i,5);
        
        % Compute all partial derivatives of segment parameters
        [dFdXc, dFdYc, dFdA, dFds, dFdl, dFdt] = ...
            dlSegment2DJacobian(xRange{i}, yRange{i}, xC, yC, A, ...
            sigmaPSF, l, t); %#ok<ASGLU>
        
        [X Y] = meshgrid(xRange{i}, yRange{i});
        ind = sub2ind([nrows ncols], Y(:), X(:));
        
        indPixels{i} = repmat(ind, p, 1);
        indParams{i} = vertcat(arrayfun(@(k) ones(numel(ind), 1) * i + ...
            k * n, 0:p-1, 'UniformOutput', 'false'));        
        val{i} = vertcat(dFdXc(:), dFdYc(:), dFdA(:), dFdl(:), dFdt(:));
    end
    
    indPixels = vertcat(indPixels{:});
    indParams = vertcat(indParams{:});
    val = vertcat(val{:});
    J = sparse(indPixels, indParams, val, m, n * p, length(val));
end