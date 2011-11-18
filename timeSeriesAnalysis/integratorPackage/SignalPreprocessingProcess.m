classdef SignalPreprocessingProcess < CorrelationProcess
    % A concrete process for pre-processing time series
    %
    % Sebastien Besson, Oct 2011

    methods (Access = public)
        
        function obj = SignalPreprocessingProcess(owner,varargin)
            
            if nargin == 0
                super_args = {};
            else               
                % Input check
                ip = inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieObject'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;
                
                % Define arguments for superclass constructor
                super_args{1} = owner;       
                super_args{2} = SignalPreprocessingProcess.getName;
                super_args{3} = @preprocessMovieSignal;                
                if isempty(funParams)
                    funParams=SignalPreprocessingProcess.getDefaultParams(owner,outputDir);
                end                
                super_args{4} = funParams;                
            end
            
            obj = obj@CorrelationProcess(super_args{:});
        end
              
%         
%         function varargout = loadChannelOutput(obj,i,j,varargin)
%             % Check input
%             outputList={'','corrFun','bounds','lags'};
%             ip=inputParser;
%             ip.addRequired('obj');
%             ip.addRequired('i',@isscalar);
%             ip.addRequired('j',@isscalar);
%             ip.addParamValue('output',outputList{1},@(x) all(ismember(x,outputList)));
%             ip.parse(obj,i,j,varargin{:});
%             output=ip.Results.output;
%             if ischar(output), output={output}; end
%             
%             s=load(obj.outFilePaths_{i,j},output{:});
%             for j=1:numel(output)
%                 if strcmp(output{j},'')
%                     varargout{j}=s;
%                 else
%                     varargout{j} = s.(output{j});
%                 end
%             end
%         end
%         
%         
%         function output = getDrawableOutput(obj)
%             output(1).name='Correlation';
%             output(1).var={''};
%             output(1).formatData=@formatCorrelationData;
%             output(1).type='correlationGraph';
%             output(1).defaultDisplayMethod = @CorrelationMeshDisplay;
%         end
    end
    
    methods (Static)
        function name =getName()
            name = 'Signal Preprocessing';
        end
        function h =GUI()
            h = @signalPreprocessingProcessGUI;
        end
        function procNames = getCorrelationProcesses()
            procNames = {'WindowSamplingProcess';
                'ProtrusionSamplingProcess'};
        end
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieObject'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            if isa(owner,'MovieList'), funParams.MovieIndex=1:numel(owner.movies_); end
            funParams.OutputDirectory = [outputDir  filesep 'preprocessedSignal'];
            funParams.ProcessName=SignalPreprocessingProcess.getCorrelationProcesses;
            funParams.kSigma=5;
        end
    end
end
