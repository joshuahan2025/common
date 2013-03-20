classdef FilamentSegmentationProcess < ImageProcessingProcess
    % A concrete class for steerable filtering
    %
    % Liya Ding, 06. 2012
    
    methods (Access = public)
        
        function obj = FilamentSegmentationProcess(owner,varargin)
            
            if nargin == 0
                super_args = {};
            else
                % Input check
                ip = inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieData'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;
                
                % Define arguments for superclass constructor
                super_args{1} = owner;
                super_args{2} = FilamentSegmentationProcess.getName;
                super_args{3} = @filament_segmentation;
                if isempty(funParams)
                    funParams = FilamentSegmentationProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
                
                if nargin > 4
                    super_args{5} = inImagePaths;
                end
                if nargin > 5
                    super_args{6} = outImagePaths;
                end
                
            end
            
            obj = obj@ImageProcessingProcess(super_args{:});
            
        end
        
        
        function setInImagePath(obj,chanNum,imagePath)
            
            if ~obj.checkChanNum(chanNum)
                error('lccb:set:fatal','Invalid image channel number for image path!\n\n');
            end
            
            if ~iscell(imagePath)
                imagePath = {imagePath};
            end
            nChan = length(chanNum);
            if nChan ~= length(imagePath)
                error('lccb:set:fatal','You must specify a path for every channel!')
            end
            
            for j = 1:nChan
                if ~exist(imagePath{j},'dir')
                    error('lccb:set:fatal',...
                        ['The directory specified for channel ' ...
                        num2str(chanNum(j)) ' is invalid!'])
                else
                    if isempty(imDir(imagePath{j})) && ...
                            isempty(dir([imagePath{j} filesep '*.mat']))
                        error('lccb:set:fatal',...
                            ['The directory specified for channel ' ...
                            num2str(chanNum(j)) ' does not contain any images!!'])
                    else
                        obj.inFilePaths_{1,chanNum(j)} = imagePath{j};
                    end
                end
            end
        end
        
        function fileNames = getOutImageFileNames(obj,iChan)
            if obj.checkChannelOutput(iChan)
                fileNames = cellfun(@(x)(dir([x filesep '*.tif'])),obj.outFilePaths_(1,iChan),'UniformOutput',false);
                fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
                nChan = numel(iChan);
                for j = 1:nChan
                    %Sort the files by the trailing numbers
                    fNums = cellfun(@(x)(str2double(...
                        x(max(regexp(x(1:end-4),'\D'))+1:end-4))),fileNames{j});
                    [~,iX] = sort(fNums);
                    fileNames{j} = fileNames{j}(iX);
                end
                nIm = cellfun(@(x)(length(x)),fileNames);
                if ~all(nIm == obj.owner_.nFrames_)
                    error('Incorrect number of images found in one or more channels!')
                end
            else
                error('Invalid channel numbers! Must be positive integers less than the number of image channels!')
            end
        end
        
        
        function fileNames = getInImageFileNames(obj,iChan)
            if obj.checkChanNum(iChan)
                
                nChan = numel(iChan);
                fileNames = cell(1,nChan);
                for j = 1:nChan
                    %First check for regular image inputs
                    fileNames{j} = imDir(obj.inFilePaths_{1,iChan(j)});
                    if isempty(fileNames{j})
                        %If none found, check for .mat image inputs
                        fileNames{j} = dir([obj.inFilePaths_{1,inFilePaths_iChan(j)} filesep '*.tif']);
                    end
                    fileNames{j} = arrayfun(@(x)(x.name),fileNames{j},'UniformOutput',false);
                    nIm = length(fileNames{j});
                    if nIm ~= obj.owner_.nFrames_
                        error(['Incorrect number of images found in channel ' num2str(iChan(j)) ' !'])
                    end
                end
            else
                error('Invalid channel numbers! Must be positive integers less than the number of image channels!')
            end
            
        end
        
        function setOutImagePath(obj,chanNum,imagePath)
            
            if ~obj.checkChanNum(chanNum)
                error('lccb:set:fatal','Invalid image channel number for image path!\n\n');
            end
            
            if ~iscell(imagePath)
                imagePath = {imagePath};
            end
            nChan = length(chanNum);
            if nChan ~= length(imagePath)
                error('lccb:set:fatal','You must specify a path for every channel!')
            end
            
            for j = 1 : nChan
                if ~exist(imagePath{j},'dir')
                    error('lccb:set:fatal',...
                        ['The directory specified for channel ' ...
                        num2str(chanNum(j)) ' is invalid!'])
                else
                    obj.outFilePaths_{1,chanNum(j)} = imagePath{j};
                end
            end
        end
        
        
        
        function outMatrix = loadChannelOutput(obj,iChan,iFrame,varargin)
            % Input check
            ip =inputParser;
            ip.addRequired('iChan',@obj.checkChanNum);
            ip.addRequired('iFrame',@obj.checkFrameNum);
            ip.addParamValue('output',[],@ischar);
            ip.parse(iChan,iFrame,varargin{:})
            
            % Data loading
            Channel_FilesNames = obj.getInImageFileNames(obj,iChan);
            filename_short_strs = uncommon_str_takeout(Channel_FilesNames);
            load([obj.outFilePaths_{1,iChannel},'/DataOutput/steerable_vote_',filename_short_strs{iFrame},'.mat'], ...
            'current_seg_orientation');
            outMatrix = current_seg_orientation;
            
        end
        
        function h = draw(obj,iChan,varargin)
            
            outputList = obj.getDrawableOutput();
            drawFilamentSegmentationImage = any(strcmpi('FilamentSegmentationImage',varargin));
            
            if drawFilamentSegmentationImage
                % Input check
                ip =inputParser;
                ip.addRequired('iChan',@(x) ismember(x,1:numel(obj.owner_.channels_)));
                ip.addParamValue('output',[],@ischar);
                ip.KeepUnmatched = true;
                ip.parse(iChan,varargin{:})
                
                % Load average corrected image
                s = load(obj.outFilePaths_{2,iChan});
                tmpFields=fieldnames(s);
                data=s.(tmpFields{1});
                
                iOutput= find(cellfun(@(y) isequal(ip.Results.output,y),{outputList.var}));
                if ~isempty(outputList(iOutput).formatData),
                    data=outputList(iOutput).formatData(data);
                end
                
                try
                    assert(~isempty(obj.displayMethod_{iOutput,iChan}));
                catch ME
                    obj.displayMethod_{iOutput,iChan}=...
                        outputList(iOutput).defaultDisplayMethod(iChan);
                end
                
                % Delegate to the corresponding method
                tag = [obj.getName '_channel' num2str(iChan) '_output' num2str(iOutput)];
                drawArgs=reshape([fieldnames(ip.Unmatched) struct2cell(ip.Unmatched)]',...
                    2*numel(fieldnames(ip.Unmatched)),1);
                h=obj.displayMethod_{iOutput,iChan}.draw(data,tag,drawArgs{:});
            else
                h=draw@ImageProcessingProcess(obj,iChan,varargin{1},varargin{2:end});
            end
        end
    end
    
    
    methods (Static)
        function name =getName()
            name = 'Filament Segmentation';
        end
        function h = GUI()
            h= @filamentSegmentationProcessGUI;
        end
        
        function output = getDrawableOutput()
            output = ImageProcessingProcess.getDrawableOutput();
        end
        
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            % Set default channels, use all channels
            funParams.ChannelIndex = 1:numel(owner.channels_);
            
            % The parameter to set pace in local segmentation
            funParams.StPace_Size = 3;
            % The parameter to set patch size in local segmentation, for
            % the estimation of local threshold
            funParams.StPatch_Size  = 21;
            
            % The percentage as the lower bound of local thresholding 
            % local threshold has to be larger or equal to this percentage
            % of the global threshold
            funParams.st_lowerbound_localthresholding  = 90; % default 90%
            
                        
            % Same set of parameters for intensity based segmentation
            funParams.IntPace_Size = 3;
            funParams.IntPatch_Size  = 21;
            funParams.int_lowerbound_localthresholding  = 90; % default 90%
            
            
            % The way to combine segmentation results from steerable
            % filtering responce and from intensity, default is : only use
            % steerable filtering result
            funParams.Combine_Way = 'st_only';
            
            % Flag to set if cell mask is used, if 1, use
            % segmentation(refined) results, if 2, use the user define ROI
            % as in MD_ROI.tif in movieData folder, if 3, no such limit
            funParams.Cell_Mask_ind = 3;
            
            % Flag to do VIF_outgrowth or not. This is an option made for
            % Gelfand lab
            funParams.VIF_Outgrowth_Flag = 1;
            
            % sub-sample number, since often VIF images are taken at a
            % lower sample rate than the other channel, so use this number
            % to save some time.
            funParams.Sub_Sample_Num = 1;
            funParams.F_classifier = cell(1,max(funParams.ChannelIndex));
            
        end
    end
end