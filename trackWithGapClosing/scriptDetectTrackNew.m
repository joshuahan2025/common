
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%generate the necessary directories
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%In the movie directory of interest, make 2 directories: "images" and "analysis". 

%put images in directory ".../images"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%detect features
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Go to the directory ".../analysis/"

%define the input variables

%movieParam
movieParam.imageDir = 'U:\Hiro\070817Cy3Control\C3con3\images\'; %directory where images are
movieParam.filenameBase = '070725QdC3CLNB_'; %image file name base
movieParam.firstImageNum = 1; %number of first image in movie
movieParam.lastImageNum = 10; %number of last image in movie
movieParam.digits4Enum = 4; %number of digits used for frame enumeration (1-4).

%detectionParam
detectionParam.psfSigma = 1.7; %point spread function sigma (in pixels)
detectionParam.testAlpha = struct('alphaR',0.05,'alphaA',0.05,'alphaD',1,'alphaF',0); %alpha-values for detection statistical tests
detectionParam.visual = 0; %1 to see image with detected features, 0 otherwise
detectionParam.doMMF = 1; %1 if mixture-model fitting, 0 otherwise
detectionParam.bitDepth = 16; %Camera bit depth

%alphaLocMax
alphaLocMax = 0.05;

%estimateSigma
estimateSigma = 1;

%saveResults
% saveResults.dir = '/mnt/sickkids/Hiro/070817Cy3Control/C3con3/analysis/mmf/'; %directory where to save input and output
% saveResults.filename = 'detectionNew4.mat'; %name of file where input and output are saved
saveResults = 0;

%run the detection function
[movieInfo,emptyFrames,framesFailedMMF,framesFailedLocMax,psfSigma] = ...
    detectSubResFeatures2D_StandAlone(movieParam,detectionParam,...
    alphaLocMax,estimateSigma,saveResults);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Track features - new
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Stay in the directory ".../analysis/"

%define the input variables

%some gap closing parameters
gapCloseParam.timeWindow = 50; %maximum allowed time gap (in frames) between a track end and a track start that allows linking them.
gapCloseParam.mergeSplit = 1; %1 if merging and splitting are considered, 0 if not.

%linking cost matrix parameters
%these are the parameters for linking detected features from one frame to
%the next in order to construct the initial tracks
costMatParam.minSearchRadiusL = 5; %minimum allowed search radius (in pixels). The search radius is calculated on the spot in the code given a feature's motion parameters. If it happens to be smaller than this minimum, it will be increased to the minimum.
costMatParam.maxSearchRadiusL = 2; %maximum allowed search radius (in pixels). Again, if a feature's calculated search radius is larger than this maximum, it will be reduced to this maximum.
costMatParam.brownStdMultL = 3; %just keep this as 3. In In the final code I will probably hardwire this value in the code.
costMatParam.closestDistScaleL = 2; %same here. Keep as 2.
costMatParam.maxStdMultL = 20; %same here. Keep it as 20. I will explain these three parameters when I visit.

%gap closing cost matrix parameters
%these are the parameters for gap closing as well as merging and splitting
%these operations are performed on the initial tracks obtained in the
%previous step
costMatParam.minSearchRadiusCG = 5; %minimum allowed search radius (in pixels).
costMatParam.maxSearchRadiusCG = 2; %maximum allowed search radius (in pixels).
costMatParam.brownStdMultCG = 3*ones(gapCloseParam.timeWindow,1); %keep this as 3.
costMatParam.linStdMultCG = 3*ones(gapCloseParam.timeWindow,1); %keep this as 3.
costMatParam.timeReachConfB = 3; %in the code, the search radius expands with the time gap (since a particle is expected to move further away in a longer gap than in a shorter one). This parameter controls how fast the search radius grows with time. timeReachConfB stands for time to reach confinement for the Brownian part of the motion. So before timeReachConfB, the search radius grows with the square root of time, after that it grows very, very slowly (it's almost fixed). I found a value of 1 works best, but you can play with this a little bit.
costMatParam.timeReachConfL = 5; %same as the previous parameter, but for the linear part of the motion. Again, I found that 5 works best, but you can play around with this parameter.
costMatParam.closestDistScaleCG = 2; %keep this as 2.
costMatParam.maxStdMultCG = 20; %and keep this as 20.
costMatParam.lenForClassify = 10; %keep this as 10.
costMatParam.maxAngle = 10; %maximum angle between the directions of motion of two tracks that allows linking them (and thus closing a gap). Think of it as the equivalent of a searchRadius but for angles.
costMatParam.ampRatioLimitCG = [0.01 100]; %for merging and splitting. Minimum and maximum ratios between the intensity of a feature after merging/before splitting and the sum the intensities of the 2 features that merge/split.

%parameters for using local density to expand search radius
%the search radius is generall calculated from the motion parameters of a
%feature or track. However, if a feature or track is really isolated from
%anything else, I expand its search radius.
useLocalDensity.link = 1; %1 if you want to expand the search radius of isolated features in the linking (initial tracking) step.
useLocalDensity.cg = 1; %1 if you want to expand the search radius of isolated tracks in the gap closing step.
useLocalDensity.nnWindowL = gapCloseParam.timeWindow; %number of frames before the current one where you want to look to see a feature's nearest neighbor in order to decide how isolated it is (in the initial linking step).
useLocalDensity.nnWindowCG = gapCloseParam.timeWindow; %number of frames before/after the current one where you want to look to see a track's nearest neighbor at its end/start (in the gap closing step).

%saveResults
saveResults.dir = '/mnt/sickkids/Nico/QuantumDotsFeb07/movie/analysis/mmf/August31/'; %directory where to save input and output
saveResults.filename = 'tracks3.mat'; %name of file where input and output are saved

%run the tracking function
[tracksFinal,kalmanInfoLink,errFlag] = trackCloseGapsKalman(...
    movieInfo,costMatParam,gapCloseParam,[],useLocalDensity,...
    saveResults,2,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

