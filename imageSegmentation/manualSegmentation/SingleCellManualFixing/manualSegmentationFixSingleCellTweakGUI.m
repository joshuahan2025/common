
function [m,boxall,isDone]  = manualSegmentationFixTweakGUI(im,m,sup_masks,displayrange,isDone,boxall,ptsShow)
%MANUALSEGMENTATIONTWEAKGUI allows manual segmentation creation of masks or alteration of existing masksk
% [masks,isCompleted] = manualSegmentationTweakGUI(images,masks)
%
% This function allows the user to modify a set of masks manually to
% improve them. Based on Deepaks seed point selection GUI - thanks Deepak!!
%
%
%
% Instructions:
%
%    -Go to the frame you want to edit or create mask for (you can use mouse
%    scroll wheel to change frames).
%   -Select one of the options: 
%
%               Add = add an area to the mask
%               Subtract = cut an area out of the mask
%               Restart = redraw this frame from scratch
%
%   -Select a drawing option:
%       Freehand = click and drag to select a region.
%       Polygon = click several times to create the vertices of a polygon.
%       Double click on first vertex to close polygon.
%
%
%   -Click GO or hit spacebar to start drawing your mask or mask correction
%
%   -Hit enter or click the "completed" box when you are done fixing a
%   frame
%
%   -When you are done with all the frames you want to fix, just close the
%   GUI
%
%   NOTE: To segment a cell which touches the image border, you must drag a
%   circle around it OUTSIDE the image area, or if using the polygon tool,
%   move a vertex outside of the image area.
%
% *****Keyboard shortcuts:*****
%
%   =For All the radio button options, just press the first letter
%   =Space - Go (start drawing on the mask)
%   =u - undo (only one step)
%   =m - toggle mask display
%   =enter - mark frame as completed
%   - OR + - Decrease/increase contrast by adjusting upper display limit
%   ( OR ) - Decrease/increase contrast by adjusting lower display limit
%

%Hunter Elliott, 10/2012

%%

if nargin < 5
    ptsShow = [];
end


if nargin < 4 || isempty(isDone)
    isDone = false(size(im,3),1);
end

if nargin < 3 || isempty(displayrange)
    
    displayrange = double([min(im(:)) max(im(:))]);
    
end

if nargin < 2 || isempty(m)
    m = false(size(im));
end

global data_get_fgnd_bgnd_seeds_3d_points;

hMainFigure = fsFigure(.75);

% Create UI controls

    % axis
    data_get_fgnd_bgnd_seeds_3d_points.ui.ah_img = axes( 'Position' , [ 0.001 , 0.2 , 0.7 , 0.7 ] , 'Visible' , 'off' );    
   
    % slice navigation controls
    data_get_fgnd_bgnd_seeds_3d_points.ui.pbh_dec = uicontrol(hMainFigure,'Style','pushbutton','String','<<',...
                    'Units' , 'normalized' , 'Position',[0.20 0.1 0.05 0.05],...
                    'Callback',{@pushFirstSlice_Callback});                        
    
    data_get_fgnd_bgnd_seeds_3d_points.ui.pbh_dec = uicontrol(hMainFigure,'Style','pushbutton','String','<',...
                    'Units' , 'normalized' , 'Position',[0.25 0.1 0.05 0.05],...
                    'Callback',{@pushdec_Callback});
                
    data_get_fgnd_bgnd_seeds_3d_points.ui.eth_sno = uicontrol(hMainFigure,'Style','edit',...
                    'String','0',...
                    'Units' , 'normalized' , 'Position',[0.30 0.1 0.1 0.05]);
                
    data_get_fgnd_bgnd_seeds_3d_points.ui.pbh_inc = uicontrol(hMainFigure,'Style','pushbutton','String','>',...
                    'Units' , 'normalized' , 'Position',[0.40 0.1 0.05 0.05],...
                    'Callback',{@pushinc_Callback});        
                
    data_get_fgnd_bgnd_seeds_3d_points.ui.pbh_inc = uicontrol(hMainFigure,'Style','pushbutton','String','>>',...
                    'Units' , 'normalized' , 'Position',[0.45 0.1 0.05 0.05],...
                    'Callback',{@pushLastSlice_Callback});                
                
    % cursor point info controls
    data_get_fgnd_bgnd_seeds_3d_points.ui.eth_xloc = uicontrol(hMainFigure,'Style','edit',...
                    'String','X: INV',...
                    'Units' , 'normalized' , 'Position',[0.20 0.05 0.1 0.05]);                

    data_get_fgnd_bgnd_seeds_3d_points.ui.eth_yloc = uicontrol(hMainFigure,'Style','edit',...
                    'String','Y: INV',...
                    'Units' , 'normalized' , 'Position',[0.30 0.05 0.1 0.05]);     
                
    data_get_fgnd_bgnd_seeds_3d_points.ui.eth_Imval = uicontrol(hMainFigure,'Style','edit',...
                    'String','I: INV',...
                    'Units' , 'normalized' , 'Position',[0.40 0.05 0.1 0.05]);                                                
                
    % selection mode controls
    data_get_fgnd_bgnd_seeds_3d_points.ui.bgh_mode = uibuttongroup('visible','on', 'Units' , 'normalized' ,'Position',[0.71 0.2 0.2 0.15]);
    data_get_fgnd_bgnd_seeds_3d_points.ui_rbh_fgnd = uicontrol('Style','Radio','String','Add',...
                                 'Units' , 'normalized' ,'Position',[0.05 0.75 0.75 0.15],'parent',data_get_fgnd_bgnd_seeds_3d_points.ui.bgh_mode,'HandleVisibility','off');
    data_get_fgnd_bgnd_seeds_3d_points.ui_rbh_bgnd = uicontrol('Style','Radio','String','Subtract',...
                                 'Units' , 'normalized' ,'Position',[0.05 0.50 0.75 0.15],'parent',data_get_fgnd_bgnd_seeds_3d_points.ui.bgh_mode,'HandleVisibility','off');            
   data_get_fgnd_bgnd_seeds_3d_points.ui_rbh_sup = uicontrol('Style','Radio','String','Add from supplementary channel',...
                                 'Units' , 'normalized' ,'Position',[0.05 0.25 0.75 0.15],'parent',data_get_fgnd_bgnd_seeds_3d_points.ui.bgh_mode,'HandleVisibility','off');            
     data_get_fgnd_bgnd_seeds_3d_points.ui_rbh_none = uicontrol('Style','Radio','String','Restart',...
                                 'Units' , 'normalized' ,'Position',[0.05 0.00 0.75 0.15],'parent',data_get_fgnd_bgnd_seeds_3d_points.ui.bgh_mode,'HandleVisibility','off');    
    
    set( data_get_fgnd_bgnd_seeds_3d_points.ui.bgh_mode , 'SelectedObject' , data_get_fgnd_bgnd_seeds_3d_points.ui_rbh_fgnd );            
    
    % selection type controls
    data_get_fgnd_bgnd_seeds_3d_points.ui.sel_mode = uibuttongroup('visible','on', 'Units' , 'normalized' ,'Position',[0.71 0.4 0.2 0.11]);
    data_get_fgnd_bgnd_seeds_3d_points.ui_rbh2_fhan = uicontrol('Style','Radio','String','Freehand',...
                                 'Units' , 'normalized' ,'Position',[0.05 0.75 0.75 0.15],'parent',data_get_fgnd_bgnd_seeds_3d_points.ui.sel_mode,'HandleVisibility','off');
    data_get_fgnd_bgnd_seeds_3d_points.ui_rbh2_poly = uicontrol('Style','Radio','String','Polygon',...
                                 'Units' , 'normalized' ,'Position',[0.05 0.50 0.75 0.15],'parent',data_get_fgnd_bgnd_seeds_3d_points.ui.sel_mode,'HandleVisibility','off');            
    
    set( data_get_fgnd_bgnd_seeds_3d_points.ui.sel_mode , 'SelectedObject' , data_get_fgnd_bgnd_seeds_3d_points.ui_rbh2_fhan );            
    
%     %Single Cell ID
%     data_get_fgnd_bgnd_seeds_3d_points.ui_singlecellID = uicontrol('Style','popupmenu','String',{'1','2','3'},...
%                                  'Units' , 'normalized' ,'Position',[0.91 0.78 0.07 0.1]);                
%     
    
    %Go button
    data_get_fgnd_bgnd_seeds_3d_points.ui_go = uicontrol('Style','pushbutton','String','Go',...
                                 'Units' , 'normalized' ,'Position',[0.71 0.78 0.17 0.1],'parent',hMainFigure,'Callback',{@pushGo_Callback});                
    
    %Slect button
    data_get_fgnd_bgnd_seeds_3d_points.ui_go = uicontrol('Style','pushbutton','String','Select & Track',...
                                 'Units' , 'normalized' ,'Position',[0.71 0.6 0.12 0.07],'parent',hMainFigure,'Callback',{@pushSelectTrack_Callback});                
   
    %Restart button
    data_get_fgnd_bgnd_seeds_3d_points.ui_go = uicontrol('Style','pushbutton','String','Restart Frame',...
                                 'Units' , 'normalized' ,'Position',[0.85 0.6 0.12 0.07],'parent',hMainFigure,'Callback',{@pushRestartFrame_Callback});                
   
    %Tracking checkbox
    data_get_fgnd_bgnd_seeds_3d_points.ui_trackingflag = uicontrol('Style','checkbox','String','Tracking',...
                                 'Units' , 'normalized' ,'Position',[0.71 0.55 0.12 0.04],'parent',hMainFigure,'Callback',{@pushTrackingCheck_Callback});                
   

    %check box
    data_get_fgnd_bgnd_seeds_3d_points.ui_cb = uicontrol('Style','checkbox','String','Completed',...        
                             'Units' , 'normalized' ,'Position',[0.75 0.1 0.05 0.05],'parent',hMainFigure,'Callback',{@chkBox_Callback});         
       
   %check continuous frames box
    data_get_fgnd_bgnd_seeds_3d_points.ui_checkcontinuousframeflag = uicontrol('Style','checkbox','String','Wiil check continuous frames',...        
                             'Units' , 'normalized' ,'Position',[0.55 0.1 0.12 0.05],'parent',hMainFigure,'Callback',{@check_continuous_Box_Callback});         

   
                         
    set(data_get_fgnd_bgnd_seeds_3d_points.ui_cb,'Value',0)
                         
    %[0.20 0.1 0.05 0.05]
% set callbacks
set( hMainFigure , 'WindowScrollWheelFcn' , @FnSliceScroll_Callback );  
%set( hMainFigure , 'WindowButtonDownFcn' , @FnMainFig_MouseButtonDownFunc );  
%set( hMainFigure , 'WindowButtonMotionFcn' , @FnMainFig_MouseMotionFunc );  
set( hMainFigure , 'WindowKeyPressFcn' , @FnKeyPress_Callback );  

% % Now from the input
% boxall = nan(size(m,3),4);
% 
% boxall(:,1)=1;
% boxall(:,3)=size(im,1);
% boxall(:,2)=1;
% boxall(:,4)=size(im,2);

% data_get_fgnd_bgnd_seeds_3d_points                         
data_get_fgnd_bgnd_seeds_3d_points.im = im;
data_get_fgnd_bgnd_seeds_3d_points.m = m;
data_get_fgnd_bgnd_seeds_3d_points.original_m = m;
data_get_fgnd_bgnd_seeds_3d_points.sup_masks = sup_masks;
data_get_fgnd_bgnd_seeds_3d_points.boxall = boxall;
data_get_fgnd_bgnd_seeds_3d_points.prevm = m;
data_get_fgnd_bgnd_seeds_3d_points.showMask = true;
data_get_fgnd_bgnd_seeds_3d_points.isDone = isDone;
data_get_fgnd_bgnd_seeds_3d_points.isWorked = isDone;
data_get_fgnd_bgnd_seeds_3d_points.firstShow = true;%Stupid way to keep axis from resizing after initial
data_get_fgnd_bgnd_seeds_3d_points.sliceno = 1;
data_get_fgnd_bgnd_seeds_3d_points.displayrange = displayrange;
data_get_fgnd_bgnd_seeds_3d_points.ptsShow = ptsShow;
data_get_fgnd_bgnd_seeds_3d_points.ptsHan = [];
data_get_fgnd_bgnd_seeds_3d_points.fgnd_seed_points = [];
data_get_fgnd_bgnd_seeds_3d_points.bgnd_seed_points = [];
data_get_fgnd_bgnd_seeds_3d_points.checking_continuous_frame_flag = 0;


% data_get_fgnd_bgnd_seeds_3d_points.currentSingleCellID = 1;

    current_mask = data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno);
    current_box = data_get_fgnd_bgnd_seeds_3d_points.boxall(data_get_fgnd_bgnd_seeds_3d_points.sliceno,:);
    
    if current_box(1)==1 && current_box(2)==1 ...
            && current_box(3)==size(current_mask,1)...
            && current_box(4)==size(current_mask,2)
        
        [indy,indx] = find(current_mask>0);
        
        current_box = ...
            [max(1,min(indy)) max(1,min(indx))...
            min(size(current_mask,1),max(indy))...
            min(size(current_mask,2),max(indx))];
        data_get_fgnd_bgnd_seeds_3d_points.boxall(data_get_fgnd_bgnd_seeds_3d_points.sliceno,:) =current_box;
    end


imsliceshow(data_get_fgnd_bgnd_seeds_3d_points);
data_get_fgnd_bgnd_seeds_3d_points.firstShow = false;


% wait until the window is closed
errCatch = 0;
try
    waitfor( hMainFigure );
catch
    errCatch = 1;
end
    
if errCatch == 0         

    m = data_get_fgnd_bgnd_seeds_3d_points.m;
    boxall = data_get_fgnd_bgnd_seeds_3d_points.boxall;
%     currentSingleCellID = data_get_fgnd_bgnd_seeds_3d_points.currentSingleCellID;
    isDone = data_get_fgnd_bgnd_seeds_3d_points.isDone;
    
    clear data_get_fgnd_bgnd_seeds_3d_points;
    
else
        
    clear data_get_fgnd_bgnd_seeds_3d_points;
    error( 'Error: Unknown error occured while getting seed points from the user' );
    
end
    
%%
function imsliceshow(data_get_fgnd_bgnd_seeds_3d_points)

    

    %Just show a blank mask so we can be lazy and still use deepaks display function
    %and have consistant image display/contrast etc.
    if data_get_fgnd_bgnd_seeds_3d_points.showMask
        mShow = data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno);
    else
        mShow = false(size(data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno)));
    end
    
    box = data_get_fgnd_bgnd_seeds_3d_points.boxall(data_get_fgnd_bgnd_seeds_3d_points.sliceno,:);

    
    xl = xlim(data_get_fgnd_bgnd_seeds_3d_points.ui.ah_img);
    yl = ylim(data_get_fgnd_bgnd_seeds_3d_points.ui.ah_img);
    
    imHan = imshow(genImageMaskOverlay_loc(data_get_fgnd_bgnd_seeds_3d_points.im(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno),...
                                   mShow,[0 1 0],.17,data_get_fgnd_bgnd_seeds_3d_points.displayrange,box,[1 0 0.5]));
    
    if ~data_get_fgnd_bgnd_seeds_3d_points.firstShow
        xlim(data_get_fgnd_bgnd_seeds_3d_points.ui.ah_img,xl)
        ylim(data_get_fgnd_bgnd_seeds_3d_points.ui.ah_img,yl)    
    end
    
    if ~isempty(data_get_fgnd_bgnd_seeds_3d_points.ptsShow) && (isempty(data_get_fgnd_bgnd_seeds_3d_points.ptsHan) || ~ishandle(data_get_fgnd_bgnd_seeds_3d_points.ptsHan))
        hold on
        data_get_fgnd_bgnd_seeds_3d_points.ptsHan = ...
            plot(data_get_fgnd_bgnd_seeds_3d_points.ptsShow(:,1),data_get_fgnd_bgnd_seeds_3d_points.ptsShow(:,2),'.r');
        hold off
    end
    
%data_get_fgnd_bgnd_seeds_3d_points.displayrange);
    set(data_get_fgnd_bgnd_seeds_3d_points.ui.eth_sno,'String',sprintf('%d / %d' , data_get_fgnd_bgnd_seeds_3d_points.sliceno , size( data_get_fgnd_bgnd_seeds_3d_points.im , 3 ) ));    

    set(data_get_fgnd_bgnd_seeds_3d_points.ui_cb,'Value',data_get_fgnd_bgnd_seeds_3d_points.isDone(data_get_fgnd_bgnd_seeds_3d_points.sliceno))

        

%Old method - show by transparency
%     imHan = imshow(data_get_fgnd_bgnd_seeds_3d_points.im(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno),data_get_fgnd_bgnd_seeds_3d_points.displayrange);
%     set(data_get_fgnd_bgnd_seeds_3d_points.ui.eth_sno,'String',sprintf('%d / %d' , data_get_fgnd_bgnd_seeds_3d_points.sliceno , size( data_get_fgnd_bgnd_seeds_3d_points.im , 3 ) ));
%     set(imHan,'AlphaData',double(data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno))+1);
%     set(imHan,'AlphaDataMapping','scaled')
%     alim(get(imHan,'Parent'),[0 2])
%     hold on;
% 
%         if ~isempty( data_get_fgnd_bgnd_seeds_3d_points.fgnd_seed_points )
%             
%             fgnd_pt_ind = find( data_get_fgnd_bgnd_seeds_3d_points.fgnd_seed_points( : , 3 ) == data_get_fgnd_bgnd_seeds_3d_points.sliceno );
%             plot( data_get_fgnd_bgnd_seeds_3d_points.fgnd_seed_points( fgnd_pt_ind , 1 ) , data_get_fgnd_bgnd_seeds_3d_points.fgnd_seed_points( fgnd_pt_ind , 2 ) , 'g+' );
% 
%         end
%         
%         if ~isempty( data_get_fgnd_bgnd_seeds_3d_points.bgnd_seed_points )
%             
%             bgnd_pt_ind = find( data_get_fgnd_bgnd_seeds_3d_points.bgnd_seed_points( : , 3 ) == data_get_fgnd_bgnd_seeds_3d_points.sliceno );       
%             plot( data_get_fgnd_bgnd_seeds_3d_points.bgnd_seed_points( bgnd_pt_ind , 1 ) , data_get_fgnd_bgnd_seeds_3d_points.bgnd_seed_points( bgnd_pt_ind , 2 ) , 'r+' );
% 
%         end
        
%    hold off;

%% First Slice
function pushFirstSlice_Callback(hSrc,eventdata_get_fgnd_bgnd_seeds_3d_points)

    global data_get_fgnd_bgnd_seeds_3d_points;

    data_get_fgnd_bgnd_seeds_3d_points.sliceno = 1;    
    
%     current_mask = data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno);
%     current_box = data_get_fgnd_bgnd_seeds_3d_points.boxall(data_get_fgnd_bgnd_seeds_3d_points.sliceno,:);
%     
%     if current_box(1)==1 && current_box(2)==1 ...
%             && current_box(3)==size(current_mask,1)...
%             && current_box(4)==size(current_mask,2)
%         
%         [indy,indx] = find(current_mask>0);
%         
%         current_box = ...
%             [max(1,min(indy)) max(1,min(indx))...
%             min(size(new_mask,1),max(indy))...
%             min(size(new_mask,2),max(indx))];
%         data_get_fgnd_bgnd_seeds_3d_points.boxall(data_get_fgnd_bgnd_seeds_3d_points.sliceno,:) =current_box;
%     end
    
    imsliceshow(data_get_fgnd_bgnd_seeds_3d_points);    

%% Last Slice
function pushLastSlice_Callback(hSrc,eventdata_get_fgnd_bgnd_seeds_3d_points)

    global data_get_fgnd_bgnd_seeds_3d_points;

    data_get_fgnd_bgnd_seeds_3d_points.sliceno = size( data_get_fgnd_bgnd_seeds_3d_points.im , 3 );    
    
    imsliceshow(data_get_fgnd_bgnd_seeds_3d_points);    
    
%%
function pushdec_Callback(hSrc,eventdata_get_fgnd_bgnd_seeds_3d_points)

    global data_get_fgnd_bgnd_seeds_3d_points;

    if(data_get_fgnd_bgnd_seeds_3d_points.sliceno>1)
        data_get_fgnd_bgnd_seeds_3d_points.sliceno = data_get_fgnd_bgnd_seeds_3d_points.sliceno-1;
    end    
    
    imsliceshow(data_get_fgnd_bgnd_seeds_3d_points);

%%
function pushinc_Callback(hSrc,eventdata_get_fgnd_bgnd_seeds_3d_points)

    global data_get_fgnd_bgnd_seeds_3d_points;

    if(data_get_fgnd_bgnd_seeds_3d_points.sliceno<size(data_get_fgnd_bgnd_seeds_3d_points.im,3))
        
        current_mask = data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno);
        current_im= data_get_fgnd_bgnd_seeds_3d_points.im(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno);
        current_box = data_get_fgnd_bgnd_seeds_3d_points.boxall(data_get_fgnd_bgnd_seeds_3d_points.sliceno,:); 
        
        %increase frame number
        data_get_fgnd_bgnd_seeds_3d_points.sliceno = data_get_fgnd_bgnd_seeds_3d_points.sliceno+1;

        % if the user want to use tracking
        if data_get_fgnd_bgnd_seeds_3d_points.trackingflag ==1
            next_mask = data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno);
            next_im = data_get_fgnd_bgnd_seeds_3d_points.im(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno);        
        
            [new_box, new_mask] = consequent_frame_segment_tracking...
                (current_mask,current_im, current_box,next_mask,next_im);            
            
            % Update the box and mask using tracking results
            data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno)=new_mask;
            data_get_fgnd_bgnd_seeds_3d_points.boxall(data_get_fgnd_bgnd_seeds_3d_points.sliceno,:) =new_box;
            data_get_fgnd_bgnd_seeds_3d_points.isWorked(data_get_fgnd_bgnd_seeds_3d_points.sliceno)=1;
        end
        
        if(data_get_fgnd_bgnd_seeds_3d_points.isDone(data_get_fgnd_bgnd_seeds_3d_points.sliceno-1)==1 &&...
            data_get_fgnd_bgnd_seeds_3d_points.checking_continuous_frame_flag ==1 )
         data_get_fgnd_bgnd_seeds_3d_points.isDone(data_get_fgnd_bgnd_seeds_3d_points.sliceno)=1;
        end
        
    end
        
    imsliceshow(data_get_fgnd_bgnd_seeds_3d_points);

%%
function FnSliceScroll_Callback( hSrc , evnt )
    
      global data_get_fgnd_bgnd_seeds_3d_points;
      
      if evnt.VerticalScrollCount > 0 
          
          if(data_get_fgnd_bgnd_seeds_3d_points.sliceno<size(data_get_fgnd_bgnd_seeds_3d_points.im,3))
              data_get_fgnd_bgnd_seeds_3d_points.sliceno = data_get_fgnd_bgnd_seeds_3d_points.sliceno+1;
          end
          
      elseif evnt.VerticalScrollCount < 0 
          
          if(data_get_fgnd_bgnd_seeds_3d_points.sliceno>1)
             data_get_fgnd_bgnd_seeds_3d_points.sliceno = data_get_fgnd_bgnd_seeds_3d_points.sliceno-1;
          end
          
      end   
          
      imsliceshow(data_get_fgnd_bgnd_seeds_3d_points);      
      UpdateCursorPointInfo(data_get_fgnd_bgnd_seeds_3d_points);
      
%%
function FnMainFig_MouseButtonDownFunc( hSrc , evnt )

    global data_get_fgnd_bgnd_seeds_3d_points;
    
    cp = get( gca , 'CurrentPoint' );
    
    if IsPointInsideImage( cp(1,1:2) , data_get_fgnd_bgnd_seeds_3d_points ) && strcmp( get(hSrc ,'SelectionType'),'normal' )       
          

       
        switch get( data_get_fgnd_bgnd_seeds_3d_points.ui.bgh_mode , 'SelectedObject' )
           
            case data_get_fgnd_bgnd_seeds_3d_points.ui_rbh_fgnd
                
                data_get_fgnd_bgnd_seeds_3d_points.fgnd_seed_points = [ data_get_fgnd_bgnd_seeds_3d_points.fgnd_seed_points ; cp(1,1:2) data_get_fgnd_bgnd_seeds_3d_points.sliceno ];

            case data_get_fgnd_bgnd_seeds_3d_points.ui_rbh_bgnd
                
                data_get_fgnd_bgnd_seeds_3d_points.bgnd_seed_points = [ data_get_fgnd_bgnd_seeds_3d_points.bgnd_seed_points ; cp(1,1:2) data_get_fgnd_bgnd_seeds_3d_points.sliceno ];                
        end

    end
    
    imsliceshow(data_get_fgnd_bgnd_seeds_3d_points);
    

%% Update cursor point info -- xloc, yloc, int_val
function UpdateCursorPointInfo( data_get_fgnd_bgnd_seeds_3d_points )

%     global data_get_fgnd_bgnd_seeds_3d_points;
    
    cp = get( gca , 'CurrentPoint' );       

    if IsPointInsideImage( cp(1,1:2) , data_get_fgnd_bgnd_seeds_3d_points )
        
        set(data_get_fgnd_bgnd_seeds_3d_points.ui.eth_xloc,'String' ,sprintf('X: %d / %d' , round( cp(1,1) ) , size( data_get_fgnd_bgnd_seeds_3d_points.im , 2 ) ));
        set(data_get_fgnd_bgnd_seeds_3d_points.ui.eth_yloc,'String' ,sprintf('Y: %d / %d' , round( cp(1,2) ) , size( data_get_fgnd_bgnd_seeds_3d_points.im , 1 ) ));        
        set(data_get_fgnd_bgnd_seeds_3d_points.ui.eth_Imval,'String',sprintf('I: %.1f' , data_get_fgnd_bgnd_seeds_3d_points.im( round( cp(1,2) ) , round( cp(1,1) ) , data_get_fgnd_bgnd_seeds_3d_points.sliceno ) ));                
        
    else
        
        set(data_get_fgnd_bgnd_seeds_3d_points.ui.eth_xloc,'String',sprintf('X: INV') );
        set(data_get_fgnd_bgnd_seeds_3d_points.ui.eth_yloc,'String',sprintf('Y: INV') );        
        set(data_get_fgnd_bgnd_seeds_3d_points.ui.eth_Imval,'String',sprintf('I: INV') );        
        
    end

%%    
function FnMainFig_MouseMotionFunc( hSrc , evnt )    
    
    global data_get_fgnd_bgnd_seeds_3d_points;
    
    cp = get( gca , 'CurrentPoint' );       
    
    if IsPointInsideImage( cp(1,1:2) , data_get_fgnd_bgnd_seeds_3d_points )
        
        set( hSrc ,'Pointer','crosshair');        
        
    else
        
        set( hSrc ,'Pointer','arrow');        

    end    
    
    
    imsliceshow(data_get_fgnd_bgnd_seeds_3d_points);    
    UpdateCursorPointInfo( data_get_fgnd_bgnd_seeds_3d_points );

%%    
function [ blnInside ] = IsPointInsideImage( cp , data_get_fgnd_bgnd_seeds_3d_points )

%     global data_get_fgnd_bgnd_seeds_3d_points;

    volsize = size( data_get_fgnd_bgnd_seeds_3d_points.im );
    
    blnInside = all( cp <= volsize([2 1]) ) && all( cp >= [1 1] );
  
function pushGo_Callback(hSrc,eventdata_get_fgnd_bgnd_seeds_3d_points)

    global data_get_fgnd_bgnd_seeds_3d_points;
    
%     data_get_fgnd_bgnd_seeds_3d_points.currentSingleCellID = get( data_get_fgnd_bgnd_seeds_3d_points.ui_singlecellID , 'Value');            
    
    switch get( data_get_fgnd_bgnd_seeds_3d_points.ui.sel_mode , 'SelectedObject' )
        
        case data_get_fgnd_bgnd_seeds_3d_points.ui_rbh2_fhan
            
            fH = imfreehand(data_get_fgnd_bgnd_seeds_3d_points.ui.ah_img);
            
        case data_get_fgnd_bgnd_seeds_3d_points.ui_rbh2_poly
            
            fH = impoly(data_get_fgnd_bgnd_seeds_3d_points.ui.ah_img);            
            
    end
    
    if ~isempty(fH)
        currROI = fH.createMask;    
        
        data_get_fgnd_bgnd_seeds_3d_points.prevm = data_get_fgnd_bgnd_seeds_3d_points.m;

        switch get( data_get_fgnd_bgnd_seeds_3d_points.ui.bgh_mode , 'SelectedObject' )

                case data_get_fgnd_bgnd_seeds_3d_points.ui_rbh_fgnd

                    data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno) = ...
                        data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno) | currROI;
                    data_get_fgnd_bgnd_seeds_3d_points.isWorked(data_get_fgnd_bgnd_seeds_3d_points.sliceno)=1;
                
               case data_get_fgnd_bgnd_seeds_3d_points.ui_rbh_bgnd

                    data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno) = ...
                        data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno) ~= ...
                        (currROI & data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno));

                    data_get_fgnd_bgnd_seeds_3d_points.isWorked(data_get_fgnd_bgnd_seeds_3d_points.sliceno)=1;
                
               case data_get_fgnd_bgnd_seeds_3d_points.ui_rbh_sup

                    data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno) = ...                        
                    data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno) | ...
                        (currROI & data_get_fgnd_bgnd_seeds_3d_points.sup_masks(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno));

                    data_get_fgnd_bgnd_seeds_3d_points.isWorked(data_get_fgnd_bgnd_seeds_3d_points.sliceno)=1;
            
               
                case data_get_fgnd_bgnd_seeds_3d_points.ui_rbh_none
                    data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno) = currROI;
                    data_get_fgnd_bgnd_seeds_3d_points.isWorked(data_get_fgnd_bgnd_seeds_3d_points.sliceno)=1;

        end
        
    end
    
    % if is worked by anyways, redraw the box
    if data_get_fgnd_bgnd_seeds_3d_points.isWorked(data_get_fgnd_bgnd_seeds_3d_points.sliceno)==1
        current_mask = data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno);
        [indy,indx] = find(current_mask>0);
        
        current_box = ...
            [max(1,min(indy)) max(1,min(indx))...
            min(size(current_mask,1),max(indy))...
            min(size(current_mask,2),max(indx))];
        data_get_fgnd_bgnd_seeds_3d_points.boxall(data_get_fgnd_bgnd_seeds_3d_points.sliceno,:) =current_box;
    end
               
    
    imsliceshow(data_get_fgnd_bgnd_seeds_3d_points);    

%%

function pushSelectTrack_Callback(hSrc,eventdata_get_fgnd_bgnd_seeds_3d_points)

    global data_get_fgnd_bgnd_seeds_3d_points;
     switch get( data_get_fgnd_bgnd_seeds_3d_points.ui.sel_mode , 'SelectedObject' )
        
        case data_get_fgnd_bgnd_seeds_3d_points.ui_rbh2_fhan
            
            fH = imfreehand(data_get_fgnd_bgnd_seeds_3d_points.ui.ah_img);
            
        case data_get_fgnd_bgnd_seeds_3d_points.ui_rbh2_poly
            
            fH = impoly(data_get_fgnd_bgnd_seeds_3d_points.ui.ah_img);            
            
     end
    
    
    if ~isempty(fH)
        currROI = fH.createMask;    
        
        [indy,indx] = find(currROI>0);
        
        data_get_fgnd_bgnd_seeds_3d_points.boxall(data_get_fgnd_bgnd_seeds_3d_points.sliceno,:) = ...
                    [max(1,min(indy)) max(1,min(indx))...
                     min(size(currROI,1),max(indy))...
                      min(size(currROI,2),max(indx))];
        box = [max(1,min(indy)) max(1,min(indx))...
                     min(size(currROI,1),max(indy))...
                      min(size(currROI,2),max(indx))];
                  box = round(box);
                  box(box==0)=1;
                  
                  mask = data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno);
                  box_mask = mask*0;
                  box_mask(box(1):box(3),box(2):box(4))=1;
                  mask = mask.*box_mask;
                  mask = keep_largest_area(mask);
                  data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno)=mask;

    end   
     
    data_get_fgnd_bgnd_seeds_3d_points.trackingflag = 1;
    
 
    set(data_get_fgnd_bgnd_seeds_3d_points.ui_trackingflag,'Value',1);
    
    current_mask =  data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno);
    
    % redraw a tighter box
    [indy,indx] = find(current_mask>0);
    
    current_box = ...
        [max(1,min(indy)) max(1,min(indx))...
        min(size(current_mask,1),max(indy))...
        min(size(current_mask,2),max(indx))];
    data_get_fgnd_bgnd_seeds_3d_points.boxall(data_get_fgnd_bgnd_seeds_3d_points.sliceno,:) =current_box;
    
    
    imsliceshow(data_get_fgnd_bgnd_seeds_3d_points);    

%%

function pushRestartFrame_Callback(hSrc,eventdata_get_fgnd_bgnd_seeds_3d_points)    

    global data_get_fgnd_bgnd_seeds_3d_points;

    data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno) ...
        =data_get_fgnd_bgnd_seeds_3d_points.original_m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno);
          
    data_get_fgnd_bgnd_seeds_3d_points.boxall(data_get_fgnd_bgnd_seeds_3d_points.sliceno,:) = ...
                    [1 1 ...
                     size(data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno),1)...
                     size(data_get_fgnd_bgnd_seeds_3d_points.m(:,:,data_get_fgnd_bgnd_seeds_3d_points.sliceno),2)];         
                 
    imsliceshow(data_get_fgnd_bgnd_seeds_3d_points);    

function FnKeyPress_Callback(hSrc,eventdata_get_fgnd_bgnd_seeds_3d_points)    

global data_get_fgnd_bgnd_seeds_3d_points;

switch eventdata_get_fgnd_bgnd_seeds_3d_points.Key
    
        
    case 'space'
        %Call the go button function
        pushGo_Callback(hSrc,eventdata_get_fgnd_bgnd_seeds_3d_points)
        
    case 'a'
        
        set( data_get_fgnd_bgnd_seeds_3d_points.ui.bgh_mode , 'SelectedObject' , data_get_fgnd_bgnd_seeds_3d_points.ui_rbh_fgnd);

    case 's'
        
        set( data_get_fgnd_bgnd_seeds_3d_points.ui.bgh_mode , 'SelectedObject' , data_get_fgnd_bgnd_seeds_3d_points.ui_rbh_bgnd);
        
    case 'r'
        
        set( data_get_fgnd_bgnd_seeds_3d_points.ui.bgh_mode , 'SelectedObject' , data_get_fgnd_bgnd_seeds_3d_points.ui_rbh_none);
        
        
    case 'f'
        
        set( data_get_fgnd_bgnd_seeds_3d_points.ui.sel_mode , 'SelectedObject' , data_get_fgnd_bgnd_seeds_3d_points.ui_rbh2_fhan);            
        
    case 'p'
        
        set( data_get_fgnd_bgnd_seeds_3d_points.ui.sel_mode , 'SelectedObject' , data_get_fgnd_bgnd_seeds_3d_points.ui_rbh2_poly);
        
    case 'equal'
        
        data_get_fgnd_bgnd_seeds_3d_points.displayrange = data_get_fgnd_bgnd_seeds_3d_points.displayrange - [0 100];
        
    case 'hyphen'
        
        data_get_fgnd_bgnd_seeds_3d_points.displayrange = data_get_fgnd_bgnd_seeds_3d_points.displayrange + [0 100];                
        
    case '0'
        
        data_get_fgnd_bgnd_seeds_3d_points.displayrange = data_get_fgnd_bgnd_seeds_3d_points.displayrange - [100 0];
        
    case '9'
        
        data_get_fgnd_bgnd_seeds_3d_points.displayrange = data_get_fgnd_bgnd_seeds_3d_points.displayrange + [100 0];                
        
    case 'm'
        
        data_get_fgnd_bgnd_seeds_3d_points.showMask = ~data_get_fgnd_bgnd_seeds_3d_points.showMask;
        
    case 'return'
        chkBox_Callback(hSrc,eventdata_get_fgnd_bgnd_seeds_3d_points)
        
    case 'u'
        
        tmp = data_get_fgnd_bgnd_seeds_3d_points.m;
        data_get_fgnd_bgnd_seeds_3d_points.m = data_get_fgnd_bgnd_seeds_3d_points.prevm;
        data_get_fgnd_bgnd_seeds_3d_points.prevm = tmp;
        
        
end    

imsliceshow(data_get_fgnd_bgnd_seeds_3d_points);    

function chkBox_Callback(hSrc,eventdata_get_fgnd_bgnd_seeds_3d_points)  
    global data_get_fgnd_bgnd_seeds_3d_points
    data_get_fgnd_bgnd_seeds_3d_points.isDone(data_get_fgnd_bgnd_seeds_3d_points.sliceno) = ~data_get_fgnd_bgnd_seeds_3d_points.isDone(data_get_fgnd_bgnd_seeds_3d_points.sliceno);
    if(data_get_fgnd_bgnd_seeds_3d_points.isDone(data_get_fgnd_bgnd_seeds_3d_points.sliceno)==1)
        data_get_fgnd_bgnd_seeds_3d_points.isWorked(data_get_fgnd_bgnd_seeds_3d_points.sliceno)=1;
    end
    
function check_continuous_Box_Callback(hSrc,eventdata_get_fgnd_bgnd_seeds_3d_points)      
     global data_get_fgnd_bgnd_seeds_3d_points
   
     set(data_get_fgnd_bgnd_seeds_3d_points.ui_trackingflag,'Value',data_get_fgnd_bgnd_seeds_3d_points.checking_continuous_frame_flag);
  
    data_get_fgnd_bgnd_seeds_3d_points.checking_continuous_frame_flag =  ...
      ~data_get_fgnd_bgnd_seeds_3d_points.checking_continuous_frame_flag;
 
    data_get_fgnd_bgnd_seeds_3d_points.checking_continuous_frame_flag =   get(data_get_fgnd_bgnd_seeds_3d_points.ui_checkcontinuousframeflag,'Value');
  

function pushTrackingCheck_Callback(hSrc,eventdata_get_fgnd_bgnd_seeds_3d_points)  
    global data_get_fgnd_bgnd_seeds_3d_points
    
    set(data_get_fgnd_bgnd_seeds_3d_points.ui_trackingflag,'Value',data_get_fgnd_bgnd_seeds_3d_points.trackingflag);
  
    data_get_fgnd_bgnd_seeds_3d_points.trackingflag =  ...
      ~data_get_fgnd_bgnd_seeds_3d_points.trackingflag;
 
    data_get_fgnd_bgnd_seeds_3d_points.trackingflag =   get(data_get_fgnd_bgnd_seeds_3d_points.ui_trackingflag,'Value');
  
    
function imRGB = genImageMaskOverlay_loc( im, mask, maskColor, maskAlpha,displayRange,box,boxColor)

     maxVal = 255;  
    im = double(im - displayRange(1));
    im = im/(displayRange(2)-displayRange(1));
    im = sqrt(im);
%     im = im*maxVal;
%     im = im/(displayRange(2)-displayRange(1));
%     
    imr = im2uint8( mat2gray( im ,[0 1]) );
    img = imr;
    imb = imr;
    mask = mask > 0;
    maxVal = 255;
    box = round(box);
    box(box==0)=1;
    
    imr(mask) = uint8( double( (1 - maskAlpha) * imr(mask) ) + maxVal * maskAlpha * maskColor(1) );
    img(mask) = uint8( double( (1 - maskAlpha) * img(mask) ) + maxVal * maskAlpha * maskColor(2) );
    imb(mask) = uint8( double( (1 - maskAlpha) * imb(mask) ) + maxVal * maskAlpha * maskColor(3) );
    
    mask_box = imr*0;
    mask_box(box(1):box(3),box(2)) = 1;
    mask_box(box(1):box(3),box(4)) = 1;
    mask_box(box(1), box(2):box(4)) = 1;
    mask_box(box(3), box(2):box(4)) = 1;
    mask_box(round((box(1)+box(3))/2),round((box(2)+box(4))/2)) = 1;
    
    try
        mask_box(round((box(1)+box(3))/2)-3:round((box(1)+box(3))/2)+3,...
            round((box(2)+box(4))/2)-3:round((box(2)+box(4))/2)+3) = 1;
    end

    mask_box = imdilate(mask_box,ones(3,3),'same'); 

    [indy_box, indx_box] = find(mask_box);

    imr(sub2ind(size(imr),indy_box, indx_box))= maxVal *boxColor(1);
    img(sub2ind(size(imr),indy_box, indx_box))= maxVal *boxColor(2);
    imb(sub2ind(size(imr),indy_box, indx_box))= maxVal *boxColor(3);
    

    imRGB = cat(3, imr, img, imb );
    
function [new_box, new_mask] = consequent_frame_segment_tracking...
            (current_mask,current_im, current_box,next_mask,next_im)
    new_box = current_box;
    new_mask = next_mask;
    current_im=double(current_im);
    next_im = double(next_im);
    
    if current_box(1)~=1 || current_box(2)~=1 ...
            || current_box(3)~=size(current_mask,1)...
            || current_box(4)~=size(current_mask,2)
        
        dmax = [50 50];
        subpix = 'none';
        d0=[0 0];
        img_width = size(current_im,2);
        img_height = size(current_im,1);
        pad_xy = [img_width/2 img_height/2];
        
        previous_position = current_box;
        
        previous_position(2) = current_box(1);
        previous_position(1) = current_box(2);
        previous_position(4) = (current_box(3)-current_box(1));
        previous_position(3) = (current_box(4)-current_box(2));
        
        tPos = previous_position(1:2)+(previous_position(3:4)+1)/2;
        tDim = previous_position(3:4);
        
        if mod(tDim(1),2)==0
            tDim(1) = tDim(1)-1;
        end
        if mod(tDim(2),2)==0
            tDim(2) = tDim(2)-1;
        end
        
        [displacement, CC_map] = ccbased_track(pad_boundary(current_im),...
            [tPos(1) tPos(2)]+pad_xy,[tDim(1) tDim(2)],pad_boundary(next_im),dmax,subpix,d0);
        
        
        current_position(3:4) = previous_position(3:4);
        current_position(1:2) = previous_position(1:2)+displacement;
        
        if current_position(1)<=0
            current_position(3) = 2*(round((current_position(3) + current_position(1) -2)/2)) + 1;
            current_position(1) = 1;
        end
        
        if current_position(2)<=0
            current_position(4) = 2*(round((current_position(4) + current_position(2) -2)/2)) + 1;
            current_position(2) = 1;
        end
        
        if current_position(1)+ current_position(3) > size(current_im,2)-1
            current_position(3) = 2*(round((size(current_im,2)-2 - current_position(1))/2)) + 1;
        end
        
        if current_position(2)+ current_position(4) > size(current_im,1)-1
            current_position(4) = 2*(round((size(current_im,1)-2 - current_position(2))/2)) + 1;
        end
        
        tracked_pos = current_position(1:2)+(current_position(3:4)+1)/2;
        
        
        tracked_box(1) = round(current_position(2));
        tracked_box(2) = round(current_position(1));
        tracked_box(3) = round(current_position(2)+current_position(4));
        tracked_box(4) = round(current_position(1)+current_position(3));
        
        tracked_mask = next_mask;
        tracked_mask(tracked_box(1):tracked_box(3),tracked_box(2):tracked_box(4))=1;
        tracked_mask = tracked_mask.*next_mask;
        
        [L_tracked_mask, num_tracked_parts] = bwlabel(tracked_mask);
        [L_next_mask, num_next_parts] = bwlabel(next_mask);
        
        sum_current_tracked_overlap = zeros(1, num_tracked_parts);
        
        for iPart = 1 : num_tracked_parts
            sum_current_tracked_overlap(iPart) = ...
                sum(sum((current_mask).*(L_tracked_mask==iPart)));
        end
        
        big_ind = find(sum_current_tracked_overlap==max(sum_current_tracked_overlap));
        
        [indy,indx] = find(L_tracked_mask==big_ind);
        
        big_ind_in_next_mask = L_next_mask(indy(1),indx(1));
        
        new_mask = L_next_mask == big_ind_in_next_mask;
        
        [indy,indx] = find(new_mask>0);
        
        new_box = ...
            [max(1,min(indy)) max(1,min(indx))...
            min(size(new_mask,1),max(indy))...
            min(size(new_mask,2),max(indx))];
        
    end