function [workTS,interval,varUsed] = removeMeanTrendNaN(TS)
%Removes mean, trend and NaN from input time series TS
%
%Synopsis:
%         [outTS,interval] = removeMeanTrendNaN(TS)   
%Input:
%       TS        - time series (number of points,number of variables)
%
%Output:
%       outTS{# of variables}(# of good points)  - cell array with a continuous time series points
%       interval - good points interval    
%       varUsed  - Index of variable with some information

%Marco Vilela, 2011


[nobs,nvar] = size(TS);
workTS      = cell(1,nvar);
interval    = cell(1,nvar);
idx         = false(1,nobs);


for i=1:nvar
    
    xi          = find(isnan(TS(:,i)));
    [nanB,nanL] = findBlock(xi,1);
    exclude     = [];
    
    for j=1:length(nanB)%excluding gaps larger than 2 points and extremes (1 and N points)
        
        if nanL(j) > 2 || ~isempty(intersect(nanB{j},nobs)) || ~isempty(intersect(nanB{j},1))
            
            xi      = setdiff(xi,nanB{j});
            exclude = sort(cat(1,nanB{j},exclude));
            
        end
        
    end
    
    if ~isempty(xi)%After excluding points, xi is a vector of 1 NaN block
        
        x         = find(~isnan(TS(:,i)));
        [fB,fL]   = findBlock(union(x,xi));
        [~,idxB]  = max(fL);
        workTS{i} = TS(fB{idxB},i);
        
        workTS{i}(isnan(workTS{i})) = ...
            interp1(intersect(x,fB{idxB}),TS(intersect(x,fB{idxB}),i),intersect(xi,fB{idxB}),'spline');
        
        interval{i} = fB{idxB};
        workTS{i}   = workTS{i} - repmat(mean(workTS{i}),sum(~isnan(workTS{i})),1);
        workTS{i}   = preWhitening(workTS{i});
        idx(i)      = 1;
        
    elseif length(exclude) < nobs
        
        [fB,fL]     = findBlock(setdiff(1:nobs,exclude));
        [~,idxB]    = max(fL);
        workTS{i}   = TS(fB{idxB},i);
        interval{i} = fB{idxB};
        workTS{i}   = workTS{i} - repmat(mean(workTS{i}),sum(~isnan(workTS{i})),1);
        workTS{i}   = preWhitening(workTS{i});
        idx(i)      = 1;
        
    end
    
end

varUsed = find(idx);
