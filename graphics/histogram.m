function [N,X,sp] = histogram(data,factor)
% HISTOGRAM generates a histogram using the "optimal" number of bins
%
% If called with no output argument, histogram plots into the current axes
%
% SYNOPSIS [N,X] = histogram(data,factor)
%
% INPUT    data: vector of input data
%          factor: (opt) factor by which the bin-widths are multiplied
%                   if "smooth", a smooth histogram will be formed.
%                   (requires the spline toolbox)
%
% OUTPUT   N   : number of points per bin (value of spline)
%          X   : center position of bins (sorted input data)
%          sp  : definition of the smooth spline
%
% REMARKS: The smooth histogram is formed by calculating the cumulative
%           histogram, fitting it with a smoothening spline and then taking
%           the analytical derivative. If the number of data points is
%           markedly above 1000, the spline is fitting the curve too
%           locally, so that the derivative can have huge peaks. Therefore,
%           only 1000-1999 points are used for estimation.
%           Note that the integral of the spline is almost exactly the
%           total number of data points. For a standard histogram, the sum
%           of the hights of the bins (but not their integral) equals the
%           total number of data points. Therefore, the counts might seem
%           off.
%
% c: 2/05 jonas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% test input
data = data(:);

if nargin < 2 || isempty(factor)
    factor = 1;
end
if isstr(factor) 
    if strmatch(factor,'smooth')
    factor = -1;
else
    error('only string input permitted is ''smooth''')
    end
end

nData = length(data);
% check whether we do a standard or a smooth histogram
if factor ~= -1
if nData < 20
    warning('Less than 20 data points!')
    nBins = ceil(nData/4);
else


    % create bins with the optimal bin width
    % W = 2*(IQD)*N^(-1/3)
    interQuartileDist = diff(prctile(data,[25,75]));
    binLength = 2*interQuartileDist*length(data)^(-1/3)*factor;

    % number of bins: divide data range by binLength
    nBins = floor((max(data)-min(data))/binLength);

    if ~isfinite(nBins)
        nBins = length(unique(data));
    end

end

% histogram
if nargout > 0
    [N,X] = hist(data,nBins);
else
    hist(data,nBins);
end

else
    % make cdf, smooth with spline, then take the derivative of the spline
    
    % cdf
    xData = sort(data);
    yData = 1:nData;
    
    % when using too many data points, the spline fits very locally, and
    % the derivatives can still be huge. Good results can be obtained with
    % 500-1000 points. Use 1000 for now
    step = max(floor(nData/1000),1);
    xData2 = xData(1:step:end);
    yData2 = yData(1:step:end);
    
    % spline. Use strong smoothing
    cdfSpline = csaps(xData2,yData2,1./(1+mean(diff(xData2))^3/0.0006));
    
    % pdf is the derivative of the cdf
    pdfSpline = fnder(cdfSpline);
    
    % histogram
    if nargout > 0
        N = fnval(pdfSpline,xData);
        X = xData;
        sp = pdfSpline;
        
    else
        plot(xData,fnval(pdfSpline,xData));
    end
end