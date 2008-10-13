function imIntegrator(runInfo,nFms2avg)
% IMINTEGRATOR averages several frames of a movie

% INPUT: runInfo : structure containing fields .imDir and .anDir, which
%                  contain the paths of image and corresponding analysis
%                  directories
%        nFms2avg: number of frames to average at a time
%        
% OUTPUT: a directory anDir/feat/intIm containing a series of 16-bit tiffs
%         generated by taking the average of nFms2avg images. e.g.) if
%         nFms2avg is 5, then for the ith image in imDir, the frames
%         averaged are i-2:i+2. for frames 1-3, the output is the same
%         since we average 1:5.  (same idea at the end of the image stack)
%
% Kathryn Applegate 2008


if nargin<2
    error('imIntegrator: need 2 input arguments')
end

% check runInfo format and directory names between file systems
if ~isfield(runInfo,'imDir') || ~isfield(runInfo,'anDir')
    error('eb1SpotDetector: runInfo should contain fields imDir and anDir');
else
    [runInfo.anDir]=formatPath(runInfo.anDir);
    [runInfo.imDir]=formatPath(runInfo.imDir);
end

% get roi edge pixels and make region outside mask NaN
if ~isfield(runInfo,'roiMask')
    roiMask=1;
    edgePix=[];
else
    polyEdge=bwmorph(runInfo.roiMask,'remove');
    edgePix=find(polyEdge);
    roiMask=double(runInfo.roiMask);
    %roiMask=swapMaskValues(roiMask,0,NaN);
end

% make spot directory if it doesn't exist from batch
intImDir=[runInfo.anDir filesep 'feat' filesep 'intIm'];
if ~isdir(intImDir)
    mkdir(intImDir);
end

% count number of images in image directory
[listOfImages] = searchFiles('.tif',[],runInfo.imDir,0);
nImTot=size(listOfImages,1);

s1=length(num2str(nImTot));
strg1=sprintf('%%.%dd',s1);


for i=1:nImTot
    
    % set start/end frame numbers to integrate over
    if i<ceil(nFms2avg/2) 
        %first few: take first nFms2avg frames
        sF=1;
        eF=nFms2avg;
    elseif i>nImTot-floor(nFms2avg/2)
        %last few: take last nFms2avg frames
        sF=nImTot-nFms2avg+1;
        eF=nImTot;
    else
        %middle frames: take frames before and after i
        sF=i-(nFms2avg-1)/2; 
        eF=i+(nFms2avg-1)/2; 
    end

    % get mean image
    img=0;
    for j=sF:eF
        fileNameIm=[char(listOfImages(j,2)) filesep char(listOfImages(j,1))];
        img=img+double(imread(fileNameIm));
    end
    meanImg=img./nFms2avg;
    
    % normalize, mask out, and save as 16-bit image
    meanImg=uint16(roiMask.*round((2^16-1).*(meanImg-min(meanImg(:)))./(max(meanImg(:))-min(meanImg(:)))));
    indxStr1=sprintf(strg1,i);
    imwrite(meanImg,[intImDir filesep 'meanImg' indxStr1 '.tif']);
    

end

