function collectCurves(figureHandles, recolor, showLegend)
%COLLECTCURVES will copy curves from several figures into one figure
%
% SYNOPSIS collectCurves(figureHandles, recolor)
%
% INPUT    figureHandles : vector of figure handles
%          recolor       : (opt) [0/{1}] whether or not to recolor the curves
%          showLegend    : (opt) [0/{1}] whether or not to show legend
%
% REMARKS  To better identify curves, it might be helpful to tag them
%           first, e.g. by using plot(x,y,'Tag','myDescription'). After
%           collection, the functions '(un)hideErrorbars' can be very
%           convenient for clarity.
%          
%
%c: jonas 04/04
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%------------
% test input
%------------
if nargin == 0 | isempty(figureHandles) | ~all(ishandle(figureHandles))
    error('please specify valid figure handles as input for COLLECTCURVES')
end
if nargin < 2 | isempty(recolor)
    recolor = 1;
end
if nargin < 3 | isempty(showLegend)
    showLegend = 1;
end
%-------------

%-----------------
% make new figure
newFH = figure('Name','Collected Curves');
newAxH = axes;

% reshape figureHandles so that we can run the loop correctly
figureHandles = figureHandles(:)';

lineCt = 1;
colorCt = 1;
%----------------------


%---------------------
% loop through figure handles and copy all lines. Add a tag so that you
% will know where the curves came from 
for fh = figureHandles
    
    % to be sure: kill legends
    legH = findall(fh,'Tag','legend');
    if ~isempty(legH)
        figHadLegend = 1;
        delete(legH);
    else
        figHadLegend = 0;
    end
    
    % find lines & reshape. Order backwards, because new line handles are
    % appended to the figure children at the top, and we want to observe
    % the sequence in which the lines were plotted
    lineHandles = findall(fh,'Type','line');
    lineHandles = lineHandles(end:-1:1)';
        
    % loop through the lines, copy to figure and update
    for lh = lineHandles
        
        % copy into new figure
        newH(lineCt) = copyobj(lh,newAxH);
        
        % change tag
        oldTag = get(newH(lineCt),'Tag');
        set(newH(lineCt),'Tag',['fig-' num2str(fh) ' ' oldTag]);
        
        % change color
        if recolor
            if strcmp(oldTag,'errorBar')
                set(newH(lineCt),'Color',extendedColors(colorCt-1));
            else
                set(newH(lineCt),'Color',extendedColors(colorCt));
                colorCt = colorCt+1;
            end
        end
        
        lineCt = lineCt + 1;
    end
    
%     % turn legend back on - does not work for some reason
%     if figHadLegend
%         axH = findall(fh,'Type','axes');
%         legend(axH,'show');
%     end
end
    
%---------------------
% now show the legend. first we need to collect all the tags, then we can
% launch it
if showLegend
    legend(newAxH,get(newH,'Tag'));
end