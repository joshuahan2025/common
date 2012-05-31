function packageGUI_RefreshFcn(handles, type)
% GUI tool function: this function is called by movie explorer when 
% switching between differenct movies. 
% 
% Input: 
%       handles - the "handles" of package GUI control panel
%       type - 'initialize': used when movie is loaded to GUI for the first time
%              'refresh': used when movie had already been loaded to GUI
%
%
% Chuangang Ren 08/2010
% Sebastien Besson (last modified Nov 2011)

% Input check
ip = inputParser;
ip.addRequired('handles',@isstruct);
ip.addRequired('type',@(x) any(strcmp(x,{'initialize','refresh'})));
ip.parse(handles,type)

% Retrieve handles
userData = get(handles.figure1, 'UserData');
nProc = size(userData.dependM, 1);
setupHandles = arrayfun(@(i)handles.(['checkbox_',num2str(i)]),1:nProc);
showHandles = arrayfun(@(i)handles.(['pushbutton_show_',num2str(i)]),1:nProc);
set(setupHandles,'Enable','on');

% Set movie data path
if ~isempty(userData.MD), field='MD'; else field = 'ML'; end
set(handles.edit_path, 'String', ...
    [userData.(field)(userData.id).getPath filesep userData.(field)(userData.id).getFilename])

% Bold the name of set-up processes
setupProc = ~cellfun(@isempty,userData.crtPackage.processes_);
set(setupHandles(setupProc),'FontWeight','bold','Enable','on');
set(setupHandles(~setupProc),'FontWeight','normal');

% Allow visualization of successfully run processes
successProc = false(1,nProc);
successProc(setupProc) = cellfun(@(x) x.success_,userData.crtPackage.processes_(setupProc));
set(showHandles(successProc),'Enable','on');
set(showHandles(~successProc),'Enable','off');

% Run sanityCheck on package 
% if strcmp(type, 'initialize'), full=true; else full=false; end
[status procEx] = userData.crtPackage.sanityCheck(true, 'all');

% Draw pass icons for sane processes
for i=find(status)
    userfcn_drawIcon(handles,'pass',i,'Current step was processed successfully', true);
end

% Clear icons for processes with false status and no exception (empty proc)
for i=find(~status & cellfun(@isempty,procEx))
    userfcn_drawIcon(handles,'clear',i,'', true);
end

% Draw warnings for processes with exceptions
for i = find(~cellfun(@isempty,procEx));
    if strcmp(procEx{i}(1).identifier, 'lccb:set:fatal')
        statusType='error';
    else
        statusType='warn';
    end
    userfcn_drawIcon(handles,statusType,i,...
        sprintf('%s\n',procEx{i}(:).message), true);
end

% Set processes checkbox value
checkedProc = logical(userData.statusM(userData.id).Checked);
set(setupHandles(~checkedProc),'Value',0);
set(setupHandles(checkedProc),'Value',1);
arrayfun(@(i) userfcn_lampSwitch(i,1,handles),find(checkedProc));

% Checkbox enable/disable set up
k= successProc | checkedProc;
tempDependM = userData.dependM;
tempDependM(:,logical(k)) = zeros(nProc, nnz(k));
userfcn_enable(find (any(tempDependM==1,2)), 'off',handles);

if strcmp(type, 'initialize')
    userData.statusM(userData.id).Visited = true;
    set(handles.figure1, 'UserData', userData)
end