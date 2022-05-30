function wbi(dataFolder,zPlane,cPlane)
%wbi(dataFolder,zPlane)
%testing ground for blob finding algorithms
%
%

%code excerpt for getting filename numbers
%str  = sprintf('%s#', name{:});
%strnum=regexp(str,'\d*(?=\.)','match');

%Global app states
loadOnTheFlyModeFlag=true;
multiChannelModeFlag=true;
OMEModeFlag=true;
autoRotateModeFlag=true;

%GUI Initialization states
GUIinit.mergeChannelsCheckboxState=false;
GUIinit.rotCWModeCheckboxState=false;
GUIinit.flipLRModeCheckboxState=false;
GUIinit.flipUDModeCheckboxState=false;


%Set app states based on GUI inits
mergeChannelsModeFlag=GUIinit.mergeChannelsCheckboxState;
flipLRModeFlag=GUIinit.flipLRModeCheckboxState;
flipUDModeFlag=GUIinit.flipUDModeCheckboxState;
rotCWModeFlag=GUIinit.rotCWModeCheckboxState;

paletteNames={'hot','jet','gray','autumn','summer'};

if nargin<3
    cPlane=1;
end

if nargin<2
    zPlane=1;
end

if nargin<1
    dataFolder=pwd;
end

%initial frame parameters
fpw=1; %frames per time window
tWin=1;
currentFrameNumber=1;

%load wb stuff

if wbCheckForDataFolder(dataFolder,true,false) && ~loadOnTheFlyModeFlag

    metadata=load([dataFolder '/meta.mat']);
    wbstruct=wbload(dataFolder);
    [TMIPMovie,numZ,numTW,validZs]=wbloadTMIPs(dataFolder,metadata);

    numTotalFrames=size(TMIPMovie{1},3);
    
elseif multiChannelModeFlag && OMEModeFlag
    
    omefiles=dir([dataFolder filesep '*.ome.tif*']);

    if isempty(omefiles)
        disp('wbi> No OME TIFFs found in this directory. Quitting.');
        return
    end

    for i=1:length(omefiles)
        OMEfile{i}=omefiles(i).name;     
    end
    
    
    %try to get fileInfo from meta.mat file, otherwise read from .omes
    
    if exist([dataFolder '/meta.mat'],'file')
        metadata=load([dataFolder '/meta.mat']);
    else
        metadata=[];
    end
    
    if isfield(metadata,'fileInfo')        
         fi=metadata.fileInfo;           
    else
    
        fi=wbAddFileInfo(dataFolder,false);
    end
    
    
    numZ=fi.numZInFile(1);
    numTW=fi.numTInFile(1);
    
    if isfield(fi,'numCInFile')
        numC=fi.numCInFile(1);
    else
        numC=1;
    end
    
    LoadOME(1);  %load first OME File
     
    tifFileNames_sorted{1}=OMEfile{1};
    numTotalFrames=fi.numT;
    
    validZs=1:numZ;
    
    %should remove exclude planes?

        
else  %currently for single Z plane
    
    %LOAD ON THE FLY MODE, saves memory
    
    %TBD: implement .ome.tiff mode
    %if isempty(dir([dataFolder filesep '*.ome.tif']))
    
    
    tifFiles=dir([dataFolder filesep '*.tif']);
    
    if isempty(tifFiles)
    
         disp('wbi> no image files found in this directory.  Quitting.');
         return;
         
    end
    
    tifFileNames_sorted=sort_nat({tifFiles.name});  %natural sorting

    numTotalFrames=length(tifFiles);
    numZ=1;
    numC=1;
    numTW=ceil(numTotalFrames/fpw);
    validZs=1;
    
    %load one .tif file
    t=1;
    TMIPMovie{1}(:,:,t)=imread( tifFileNames_sorted{t});

    
end

%set dimensions
TMIPh=size(TMIPMovie{1},1);
TMIPw=size(TMIPMovie{1},2);
vMIP=[];hMIP=[];
ZPlaneLabels=1:numZ;
CPlaneLabels=1:numC;
tWinLabels=1:numTW;

imageH=TMIPh;
imageW=TMIPw;

%write out ZMovie to workspace
base('TMIPMovie',TMIPMovie);

%check autoRotate
if autoRotateModeFlag
   rotCWModeFlag=TMIPh>TMIPw;
   if TMIPh>TMIPw
        imageH=TMIPw;
        imageW=TMIPh;
   end
end

%find blobs params
med_filt_width=3;

filterWidth=3;  %should be odd
defaultTemplateFilter=Gaussian2D(1+6*filterWidth,filterWidth);
currentTemplateFilter=defaultTemplateFilter;

max_cutoff=1000;
threshold=100;
rMin=5;
post_threshold=200;
refineNeuronNumber=1;

currentRawImage=squeeze(TMIPMovie{zPlane,cPlane}(:,:,tWin));
currentFilteredImage=zeros(size(currentRawImage));
currentTemplatedImage=zeros(size(currentRawImage));

%start with raw image
currentDisplayImage=currentRawImage;
currentDisplayImage=ApplyImageDisplayTransform(currentDisplayImage);

filterTypes={'hipass','LoG'};
currentFilterType=filterTypes{1};

%DEBUG
base('cdi',currentDisplayImage);

clow=0;
cmax=max(currentDisplayImage(:));
chigh=min([cmax 10*median(currentDisplayImage(:))]);

%globals
tblobs=struct('x',[],'y',[],'n',[]);
img=[];X=[];Y=[];
currentPalette='jet';
templateSize=19;
learnedTemplate=zeros(templateSize);
thisX=1;
thisY=1;

setupPlots;

    
%% GUI

%%ALGO PARAMS
tb=.05;  %tab
lm=.01;  %left margin
tm=.96;  %top margin
lf=.03;  %linefeed

nl=0;
annotation('textbox',[lm tm 0.11 0.02],'String','Frames Per Win.','EdgeColor','none');
handles.threshBox=uicontrol('Style','edit','Units','normalized','Position',[lm+tb tm 0.05 0.02],'String',fpw,'HorizontalAlignment','right','ForegroundColor','k','TooltipString','Frames Per Window','Callback',@(s,e) editFramesPerWindow);
nl=nl+1;
handles.rotCWButton = uicontrol('Style','checkbox','Units','normalized','Position',[lm tm-lf*nl 0.05 0.02],'Value',rotCWModeFlag,'String','Rotate','Callback',@(s,e) RotCWButtonCallback);
handles.FlipUDButton = uicontrol('Style','checkbox','Units','normalized','Position',[lm+0.75*tb tm-lf*nl 0.05 0.02],'Value',flipLRModeFlag,'String','U/D Flip','Callback',@(s,e) FlipUDButtonCallback);
handles.FlipLRButton = uicontrol('Style','checkbox','Units','normalized','Position',[lm+1.25*tb tm-lf*nl 0.05 0.02],'Value',flipLRModeFlag,'String','L/R Flip','Callback',@(s,e) FlipLRButtonCallback);

nl=nl+1;

annotation('textbox',[lm tm-lf*nl 0.11 0.02],'String','Max Cutoff','EdgeColor','none');
handles.threshBox=uicontrol('Style','edit','Units','normalized','Position',[lm+tb tm-lf*nl 0.05 0.02],'String',max_cutoff,'HorizontalAlignment','right','ForegroundColor','k','Callback',@(s,e) editMaxCutoff);
nl=nl+1;

annotation('textbox',[lm tm-lf*nl 0.11 0.02],'String','Med Filt Width','EdgeColor','none');
handles.threshBox=uicontrol('Style','edit','Units','normalized','Position',[lm+tb tm-lf*nl 0.05 0.02],'String',med_filt_width,'HorizontalAlignment','right','ForegroundColor','k','Callback',@(s,e) editMedFilterWidth);
nl=nl+1;


annotation('textbox',[lm tm-lf*nl 0.11 0.02],'String','Thresh','EdgeColor','none');
handles.threshBox=uicontrol('Style','edit','Units','normalized','Position',[lm+tb tm-lf*nl 0.05 0.02],'String',threshold,'HorizontalAlignment','right','ForegroundColor','k','Callback',@(s,e) editThreshold);
nl=nl+1;

%%annotation('textbox',[lm tm-lf*4 0.11 0.02],'String','Filter width','EdgeColor','none');
%%handles.filterWidthBox=uicontrol('Style','edit','Units','normalized','Position',[lm+tb tm-4*lf 0.05 0.02],'String',filterWidth,'HorizontalAlignment','right','ForegroundColor','k','Callback',@(s,e) editFilterWidth);

%%annotation('textbox',[lm tm-lf*5 0.11 0.02],'String','Filter Type','EdgeColor','none');
%%handles.filterTypePopup=uicontrol('Style','popup','Units','normalized','Position',[lm+tb tm-5*lf 0.05 0.02],'String',filterTypes,'HorizontalAlignment','right','ForegroundColor','k','Callback',@(s,e) filterTypeCallback);

annotation('textbox',[lm tm-lf*6 0.11 0.02],'String','Post Thresh','EdgeColor','none');
handles.postThreshBox=uicontrol('Style','edit','Units','normalized','Position',[lm+tb tm-6*lf 0.05 0.02],'String',post_threshold,'HorizontalAlignment','right','ForegroundColor','k','Callback',@(s,e) editPostThreshold);

annotation('textbox',[lm tm-lf*7 0.11 0.02],'String','Rmin','EdgeColor','none');
handles.rMinBox=uicontrol('Style','edit','Units','normalized','Position',[lm+tb tm-7*lf 0.05 0.02],'String',rMin,'HorizontalAlignment','right','ForegroundColor','k','Callback',@(s,e) editRmin);

handles.refineBlobsCheckbox=uicontrol('Style','checkbox','Units','normalized','Position',[lm+0.5*tb tm-8*lf 0.05 0.02],'String','Refine','HorizontalAlignment','right','ForegroundColor','k','Value',0,'Callback',@(s,e) RefineBlobsCheckbox);
handles.refineNeuronNumber=uicontrol('Style','edit','Units','normalized','Position',[lm+1.5*tb tm-8*lf 0.025 0.02],'String',num2str(refineNeuronNumber),'HorizontalAlignment','right','ForegroundColor','k','TooltipString','Neuron Number','Callback',@(s,e) editRefineNeuronNumber);


%%VIEW PARAMS
gh=.68; %group height

handles.showExs=uicontrol('Style','checkbox','Units','normalized','Position',[lm gh 0.05 0.02],'String','show xs','HorizontalAlignment','right','ForegroundColor','k','Value',1,'Callback',@(s,e) showExsCallback);

handles.imageSelector1=uicontrol('Style','radio','Units','normalized','Position',[lm gh-lf 0.05 0.02],'String','original','HorizontalAlignment','right','ForegroundColor','k','Value',1,'Callback',@(s,e) imageSelectorCallback(1));
handles.imageSelector2=uicontrol('Style','radio','Units','normalized','Position',[lm gh-2*lf 0.05 0.02],'String','filtered','HorizontalAlignment','right','ForegroundColor','k','Value',0,'Callback',@(s,e) imageSelectorCallback(2));
handles.imageSelector3=uicontrol('Style','radio','Units','normalized','Position',[lm gh-3*lf 0.05 0.02],'String','templated','HorizontalAlignment','right','ForegroundColor','k','Value',0,'Callback',@(s,e) imageSelectorCallback(3));

%%MOVIE NAVIGATION
off1=.2;
gh=.50;

if OMEModeFlag
    
    handles.filePopup=uicontrol('Style','popupmenu','Units','normalized','Position',[.12 .95 .4 0.02],'String',OMEfile,'FontSize',14,'Callback',@(s,e) FileSelectorCallback);

else
       
    handles.frameLabel=annotation('textbox',[.12 .94 .4 0.02],'String',strrep(tifFileNames_sorted{tWin},'_','\_'),'EdgeColor','none','FontSize',14);
    
end

%%CHANNEL PICKER
if numC>1
    cGuiStatus='on';
else
    cGuiStatus='off';
end

annotation('textbox',[lm+.02 gh+2*lf tb 0.02],'String','Channel','EdgeColor','none');
handles.nextCButton = uicontrol('Style','pushbutton','Units','normalized','Position',[lm+tb+.02 gh+lf 0.02 0.02],'String','+1','Enable',cGuiStatus,'Callback',@(s,e) CupButtonCallback);
handles.prevCButton = uicontrol('Style','pushbutton','Units','normalized','Position',[lm gh+lf 0.02 0.02],'String','-1','Enable',cGuiStatus,'Callback',@(s,e) CdownButtonCallback);
handles.CPopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',zPlane,'String',CPlaneLabels,'Position',[lm+.02 gh+0.5*lf tb 0.04],'Enable',cGuiStatus,'Callback',@(s,e) CPopupMenuCallback);


%%Z PICKER
if numZ>1
    zGuiStatus='on';
else
    zGuiStatus='off';
end

annotation('textbox',[lm+.02 gh tb 0.02],'String','Z Plane','EdgeColor','none');
handles.nextZButton = uicontrol('Style','pushbutton','Units','normalized','Position',[lm+tb+.02 gh-lf 0.02 0.02],'String','+1','Enable',zGuiStatus,'Callback',@(s,e) ZupButtonCallback);
handles.prevZButton = uicontrol('Style','pushbutton','Units','normalized','Position',[lm gh-lf 0.02 0.02],'String','-1','Enable',zGuiStatus,'Callback',@(s,e) ZdownButtonCallback);
handles.ZPopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',zPlane,'String',ZPlaneLabels,'Position',[lm+.02 gh-1.5*lf tb 0.04],'Enable',zGuiStatus,'Callback',@(s,e) ZPopupMenuCallback);




annotation('textbox',[lm+.02 gh-2*lf tb 0.02],'String','Time Window','EdgeColor','none');
handles.nextTButton = uicontrol('Style','pushbutton','Units','normalized','Position',[lm+tb+.02 gh-3*lf 0.02 0.02],'String','+1','Callback',@(s,e) TupButtonCallback);
handles.prevTButton = uicontrol('Style','pushbutton','Units','normalized','Position',[lm gh-3*lf 0.02 0.02],'String','-1','Callback',@(s,e) TdownButtonCallback);

handles.nextT100Button = uicontrol('Style','pushbutton','Units','normalized','Position',[lm+tb+.02 gh-3.6*lf 0.02 0.02],'String','+100','Callback',@(s,e) TupButtonCallback(100));
handles.prevT100Button = uicontrol('Style','pushbutton','Units','normalized','Position',[lm gh-3.6*lf 0.02 0.02],'String','-100','Callback',@(s,e) TdownButtonCallback(100));

handles.TPopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',tWin,'String',tWinLabels,'Position',[lm+.02 gh-3.5*lf tb 0.04],'Callback',@(s,e) TPopupMenuCallback);

handles.learnTemplate = uicontrol('Style','pushbutton','Units','normalized','String','Learn Template','Position',[lm+.02 gh-6*lf tb 0.04],'Callback',@(s,e) LearnTemplate);
handles.useTemplate= uicontrol('Style','pushbutton','Units','normalized','String','Use Template','Position',[lm+.02 gh-7.5*lf tb 0.04],'Callback',@(s,e) UseTemplate);
handles.resetTemplate= uicontrol('Style','pushbutton','Units','normalized','String','Reset Template','Position',[lm+.02 gh-9*lf tb 0.04],'Callback',@(s,e) ResetTemplate);

handles.SplitMoviesVertical= uicontrol('Style','pushbutton','Units','normalized','String','V-SPLIT MOVIES','Position',[.72 tm-0.5*lf 1.5*tb 0.04],'Callback',@(s,e) SplitMovies('v'));
handles.SplitMoviesHorizontal= uicontrol('Style','pushbutton','Units','normalized','String','H-SPLIT MOVIES','Position',[.82 tm-0.5*lf 1.5*tb 0.04],'Callback',@(s,e) SplitMovies('h'));


handles.RunFullTrial= uicontrol('Style','pushbutton','Units','normalized','String','RUN FULL TRIAL','Position',[.92 tm-0.5*lf 1.5*tb 0.04],'Callback',@(s,e) RunFullTrial);



%%PALETTE
ypos=.1;
off2=.14;
sw=.05;


handles.imageMaxLevelSlider = uicontrol('Style','slider','Units','normalized','Position',[.2-off2 ypos+.02 sw .05],'String','levels','Min',0,'Max',100,'Value',100*chigh/cmax); %,'Callback',@(s,e) disp('mouseup')
handles.imageMinLevelSlider = uicontrol('Style','slider','Units','normalized','Position',[.2-off2 ypos sw .05],'String','minlevel','Min',0,'Max',100,'Value',100*clow/cmax); %,'Callback',@(s,e) disp('mouseup')

adj=.03;
annotation('textbox',[lm ypos+.01+adj 0.06 0.02],'String','cutoffs','EdgeColor','none');
annotation('textbox',[lm+adj ypos+.02+adj 0.03 0.02],'String','hi','EdgeColor','none');
annotation('textbox',[lm+adj ypos+adj 0.03 0.02],'String','lo','EdgeColor','none');
annotation('textbox',[lm ypos-.02+adj 0.04 0.02],'String','palette','EdgeColor','none');
handles.palettePopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',1,'String',paletteNames,'Position',[lm+adj ypos-.02 sw .05],'Callback',@(s,e) palettePopupMenuCallback);


handles.mergeColors=uicontrol('Style','checkbox','Units','normalized','Position',[lm ypos-.05+adj 0.08 0.02],'String','merge channels','HorizontalAlignment','right','ForegroundColor','k','Value',mergeChannelsModeFlag,'Callback',@(s,e) MergeChannelsCheckboxCallback);





%%DRAW PLOTS
drawPlots;


%%VSLIDER
handles.vSliceSlider=uicontrol('Style','slider','Units','normalized','Position',[handles.axes.Position(1),handles.axes.Position(2)-.01,handles.axes.Position(3),.01],'Min',1,'Max',imageW,'Value',1);

handles.hSliceSlider=uicontrol('Style','slider','Units','normalized','Position',[handles.axes.Position(1)+handles.axes.Position(3),handles.axes.Position(2),.01,handles.axes.Position(4)],'Min',1,'Max',imageH,'Value',1);

%%SLIDER LISTENERS
hListener = addlistener(handles.imageMaxLevelSlider,'Value','PostSet',@(s,e) imageMaxLevelSliderCallback) ;
hListener = addlistener(handles.imageMinLevelSlider,'Value','PostSet',@(s,e) imageMinLevelSliderCallback) ;

hListener = addlistener(handles.vSliceSlider,'Value','PostSet',@(s,e) vSliceSliderCallback) ;
hListener = addlistener(handles.hSliceSlider,'Value','PostSet',@(s,e) hSliceSliderCallback) ;

%% END MAIN

%% GUI CALLBACKS

    function SplitMovies(orientation)
        
%           modalDialog = dialog('Position',[300 300 250 150],'Name','wbi');
%           txt = uicontrol('Parent',modalDialog,...
%                'Style','text',...
%                'Position',[20 80 210 40],...
%                'String','Splitting Movies.');
%            
           %    btn = uicontrol('Parent',d,...
           %    'Position',[85 20 70 25],...
           %    'String','Cancel',...
           %    'Callback','delete(gcf)');
           
           drawnow;
        if strcmp(orientation,'v')
            if rotCWModeFlag
                wbSplitMovies(dataFolder,fi,'h',thisX);
            else
                wbSplitMovies(dataFolder,fi,'v',thisX);
            end
        else  %'h'
            if rotCWModeFlag
               wbSplitMovies(dataFolder,fi,'v',thisY);
            else
               wbSplitMovies(dataFolder,fi,'h',thisY);
            end
            
        end
        
 %       delete(modalDialog);
       
    end

    function RunFullTrial
        
        currentFrameNumber=1;
        tWin=1;
        clear tblobs;
        updateData;
        
        fprintf('%d to run: ',numTW);
        for tw=1:numTW
            fprintf('%d..',tw);
            TupButtonCallback(1); 
        end
        
        options.fpw=fpw;
        options.maxCutoff=max_cutoff;
        options.medFiltWidth=med_filt_width;
        options.thresholdMargin=threshold;
        options.postTemplateThreshold=post_threshold;
        options.minBlobSpacing=rMin;
        options.templateFilter=currentTemplateFilter;
        
        dateRan=datestr(now);
        
        beep;
        save('../wbstruct.mat','tblobs','options','dateRan');
        disp(' ');
        disp('FULL TRIAL RUN COMPLETED.');
    end

    function FlipLRButtonCallback
        
        flipLRModeFlag=get(gcbo,'Value');
        
        thisX=imageW - thisX + 1;
        
        drawPlots;
    end

    function FlipUDButtonCallback
        
        flipUDModeFlag=get(gcbo,'Value');
        
        thisY=imageH - thisY + 1;

        drawPlots;
    end

    function RotCWButtonCallback
        
        rotCWModeFlag=get(gcbo,'Value');
        
        tmp=imageH;
        imageH=imageW;
        imageW=tmp;
        
        tmp=thisY;
        thisY=thisX;
        thisX=tmp;
%         

        %swap slider values
        
%         handles.vSliceSlider.Max=imageW;
%         handles.hSliceSlider.Max=imageH;
        
% handles.vSliceSlider.Max
% handles.hSliceSlider.Max
%         
%         tmp=handles.vSliceSlider.Value
%         handles.vSliceSlider.Value=handles.hSliceSlider.Value;
%         handles.hSliceSlider.Value=tmp;
%         
        drawPlots;
    end

    function FileSelectorCallback
        
        LoadOME(get(gcbo,'Value'));
        drawPlots;
        
    end

    function MergeChannelsCheckboxCallback

       mergeChannelsModeFlag=get(gcbo,'Value');
       drawPlots;
    
    end

    function vSliceSliderCallback
        
        thisX=floor(handles.vSliceSlider.Value);
        handles.vLine.XData=[thisX thisX];
        handles.hMIP.XData=currentDisplayImage(:,thisX);  
        
        UpdateZoomImage;
        
    end

    function hSliceSliderCallback
        
        thisY=imageH-floor(handles.hSliceSlider.Value)+1;
        handles.hLine.YData=[thisY thisY];
        handles.vMIP.YData=currentDisplayImage(thisY,:);  
        
        UpdateZoomImage;
    end

    function UpdateZoomImage
        
        %update Zoom image
        hw=floor(templateSize/2);        
        zoomClip=zeros(2*hw+1,2*hw+1); 

        if (thisY-hw>1)  && (thisX-hw>1) && (thisY+hw<=imageH) && (thisX+hw<=imageW)
            cri=ApplyImageDisplayTransform(currentRawImage);
            zoomClip=cri(thisY-hw:thisY+hw ,thisX-hw:thisX+hw );
        end
        
        handles.zoomImage.CData=zoomClip;
                
    end

    function filterTypeCallback
        currentFilterType=handles.filterTypePopup.String{handles.filterTypePopup.Value};
        drawPlots;
    end

    function showExsCallback
        
        if handles.showExs.Value==1
            set(handles.ex,'Visible','on');
            set(handles.nLabels,'Visible','on');
        else
            set(handles.ex,'Visible','off');
            set(handles.nLabels,'Visible','off');
        end
        
    end

    function imageSelectorCallback(selected)
        
         if selected==1
             handles.imageSelector1.Value=1;
             handles.imageSelector2.Value=0;
             handles.imageSelector3.Value=0;
                          
         elseif selected==2
             handles.imageSelector1.Value=0;
             handles.imageSelector2.Value=1;
             handles.imageSelector3.Value=0;
                
         else
             handles.imageSelector1.Value=0;
             handles.imageSelector2.Value=0;
             handles.imageSelector3.Value=1;
               
         end
         
         
         updateData;
         
         


         
    end

    %%MOVIE NAV
    function CupButtonCallback()
        if cPlane<numC
            cPlane=cPlane+1;
        else
            cPlane=1;
        end
        set(handles.CPopupMenu,'Value',cPlane);
        drawPlots;  
    end

    function CdownButtonCallback()
        if cPlane>1
            cPlane=cPlane-1;
        else
            cPlane=numC;
        end
        set(handles.CPopupMenu,'Value',cPlane);
        drawPlots;    
    end

    function CPopupMenuCallback()
        cPlane=get(gcbo,'Value');
        drawPlots;

    end
    
    function ZupButtonCallback()
        if zPlane<numZ
            zPlane=zPlane+1;
        else
            zPlane=1;
        end
        set(handles.ZPopupMenu,'Value',zPlane);
        drawPlots;  
    end

    function ZdownButtonCallback()
        if zPlane>1
            zPlane=zPlane-1;
        else
            zPlane=numZ;
        end
        set(handles.ZPopupMenu,'Value',zPlane);
        drawPlots;    
    end

    function ZPopupMenuCallback()
        zPlane=get(gcbo,'Value');
        drawPlots;

    end

    function TupButtonCallback(steps)
        if nargin<1 || isempty(steps)
            steps=1;
        end
        
        if tWin<=numTW-steps
            tWin=tWin+steps;
        else
            tWin=1;
        end
        
        currentFrameNumber=fpw*(tWin-1)+1;
        
        set(handles.TPopupMenu,'Value',tWin);
        drawPlots;  
    end

    function TdownButtonCallback(steps)
        if nargin<1 || isempty(steps)
            steps=1;
        end
        
        
        if tWin>steps
            tWin=tWin-steps;
        else
            tWin=numTW;
        end
        
        currentFrameNumber=fpw*(tWin-1)+1;
        
        set(handles.TPopupMenu,'Value',tWin);
        drawPlots;    
    end

    function TPopupMenuCallback()
        tWin=get(gcbo,'Value');
        drawPlots;

    end

    %%ALGO
    function RefineBlobsCheckbox()
        if handles.refineBlobsCheckbox.Value
            RefineBlobs;
        end
    end

    function editRefineNeuronNumber()
        refineNeuronNumber=str2num(get(gcbo,'String'))
        
        if handles.refineBlobsCheckbox.Value
            RefineBlobs;
            handles.vSliceSlider.Value=(tblobs(zPlane,tWin).x(refineNeuronNumber))  -1.5;
            handles.hSliceSlider.Value=TMIPh-(tblobs(zPlane,tWin).y(refineNeuronNumber))+6;
            %drawPlots;
        end
    end

    function editFramesPerWindow()
        fpw=str2num(get(gcbo,'String'));
        numTW=ceil(numTotalFrames/fpw);

        drawPlots;
    end

    function editMaxCutoff()
        max_cutoff=str2num(get(gcbo,'String'));
        drawPlots;
    end 
    
    function editMedFilterWidth()
        med_filt_width=str2num(get(gcbo,'String'));
        drawPlots;
    end
    
    function editThreshold()
        threshold=str2num(get(gcbo,'String'));
        drawPlots;
    end

    function editPostThreshold()
        post_threshold=str2num(get(gcbo,'String'));
        drawPlots;
    end

    function editRmin()
        rMin=str2num(get(gcbo,'String'));
        drawPlots;
    end

    function editFilterWidth()
        filterWidth=str2num(get(gcbo,'String'));
        drawPlots;
    end

    %%PALETTE
    function palettePopupMenuCallback
        
        currentPalette=paletteNames{get(handles.palettePopupMenu,'Value')};
        
        if isfield(handles,'ex')
            if strcmp(currentPalette,'hot')
                set(handles.ex,'Color','g');
            else
                set(handles.ex,'Color','r');
            end
        end
        
        colormap(currentPalette);  
        cm=colormap;
        cm(1,:)=[0 0 0];
        colormap(cm); 
        
    end

    function imageMaxLevelSliderCallback
    
        sliderValue=max([get(handles.imageMaxLevelSlider,'Value') get(handles.imageMinLevelSlider,'Value')]);   
        chigh=max([sliderValue/100*cmax clow+1]);
        updateColorPalettes;

    end
        
    function imageMinLevelSliderCallback
    
        sliderValue=min([get(handles.imageMinLevelSlider,'Value') get(handles.imageMaxLevelSlider,'Value')]);    
        clow=min([sliderValue/100*cmax chigh-1]);
        updateColorPalettes;
        
    end

    %%MOUSE CLICKS
    function MouseDownCallback(hObject,~)

        pos=get(hObject,'CurrentPoint'); %pos is 2x3??

        %update scanner lines
        handles.vSliceSlider.Value=pos(1,1)-1.5;
        handles.hSliceSlider.Value=imageH-pos(1,2)+6;

    end

%% Subfunctions

    function RefineBlobs
        
         showFitFlag=false;
           refineAreaSize=41;
           numGaussians=3;
           GMMoptions = statset('Display','final');
                 tblobs(zPlane,tWin).n
         tic
           for n=1:20 %refineNeuronNumber %:5; %tblobs(tWin).n
               
              x=tblobs(zPlane,tWin).x(n);
              y=tblobs(zPlane,tWin).y(n);

              hw=floor(refineAreaSize/2);        
              zoomClip=zeros(2*hw+1,2*hw+1);   
              if (y-hw>1)  && (x-hw>1) && (y+hw<=imageH) && (x+hw<=imageW)
                  zoomClip=currentRawImage(y-hw:y+hw ,x-hw:x+hw );
              end
              axes(handles.axes);
              rectangle('Position',[x-hw,y-hw,2*hw,2*hw],'EdgeColor',MyColor('yellow'));
              
              %%GMM Estimate
% tic
%               nX=sum(zoomClip(:));
%               X=zeros(nX,2);
% 
%               count=1;
%               for xpix=1:size(zoomClip,1)
%                     for ypix=1:size(zoomClip,2);
%                         pixval=zoomClip(xpix,ypix);
%                         X(count:count+pixval-1,2)=xpix;
%                         X(count:count+pixval-1,1)=ypix;
%                         count=count+pixval;
%                     end
%               end
%               obj = gmdistribution.fit(X,numGaussians,'Options',GMMoptions);
% toc
%               for g=1:numGaussians
%                  ex(x-hw+obj.mu(g,1),y-hw+obj.mu(g,2),4,'b');
%               end
              
              
              
                %Fit 2G gaussian surface
                zi=double(zoomClip-median(zoomClip(:)));
                zi=zi/max(zi(:));
                base('zi');
                 
                [xi,yi] =  meshgrid(1:2*hw+1,1:2*hw+1); % meshgrid(-hw:hw,-hw:hw);
                base('xi')
                base('yi')
%                opts.tilted = true;
%                results = autoGaussianSurf(xi,yi,zi,opts);
                
                offset=0; %median(zi(:))
                amplitude=1;
                centroidX=20;
                centroidY=20;
                angle=0;
                widthX=7; %sqrt(sum(((xi(:)-20).^2).*(zi(:)-min(zi(:))))/(sum(zi(:)-min(zi(:)))));
                widthY=7; %sqrt(sum(((yi(:)-20).^2).*(zi(:)-min(zi(:))))/(sum(zi(:)-min(zi(:)))));

                amplitude2=0.5;
                centroid2X=20;
                centroid2Y=20;
                angle2=0;
                width2X=7;
                width2Y=7;
                
                fop.StartPoint=[offset,amplitude,amplitude2,centroidX,centroidY,centroid2X,centroid2Y,angle,angle2,widthX,widthY,width2X,width2Y];
                fop.Lower=[0 0.1,0.1,18,18,1,1,0,0,6,6,6,6];
                fop.Upper=[50,1.5,1,22,22,41,41,pi,pi,10,10,10,10];
                [results, gof] = Gauss2DRotFit2(zi,fop);
                
                zfit=results(xi,yi);
                
                base('results');
                base('gof');
                
                ex(x-hw+results.c1x-1, y-hw+results.c1y-1,4,'b');
                ex(x-hw+results.c2x-1, y-hw+results.c2y-1,4,'b');
                
                
                if showFitFlag
                    cf=gcf;

                    figure('Position',[100 100 300 300]);
                    subtightplot(3,3,1);
                    imagesc(zi);
                    subtightplot(3,3,2);
                    imagesc(zfit);
                    subtightplot(3,3,3);
                    imagesc(zi-zfit);
                
                    subtightplot(3,3,4);
                    plot(-hw:hw,zi(hw+1,:),'b');
                    ylim([0 1.1*max(zi(hw+1,:))]);
                    xlim([-hw hw]);
                    hold on;
                    plot(-hw:hw,zfit(hw+1,:),'r');
                   
                    subtightplot(3,3,6);
                    resid=zi-zfit;
                    plot(-hw:hw,resid(hw+1,:));
                    ylim([0 1.1*max(zi(hw+1,:))]+min(resid(hw+1,:)) );
                    xlim([-hw hw]);

                    subtightplot(3,3,7);
                    plot(-hw:hw,zi(:,hw+1),'b');
                    ylim([0 1.1*max(zi(:,hw+1))]);
                    xlim([-hw hw]);
                    hold on;
                    plot(-hw:hw,zfit(:,hw+1),'r');

    %                 
%                 subtightplot(3,3,8);
%                 x1=-hw:hw;
%                 z1=zi(:,hw+1)';
%                 z1=z1-min(z1);
%                 opts1.positive=true;
%                 results1 = autoGaussianCurve(x1,z1,opts1);
%                 plot(-hw:hw,z1,'b');
%                 hold on;
%                 plot(-hw:hw,results1.G,'r');
%                 
%                base('curve',zi(:,hw+1));
                
                    subtightplot(3,3,9);
                    resid=zi-zfit;
                    plot(-hw:hw,resid(:,hw+1)');
                    ylim([0 1.1*max(zi(:,hw+1))]+min(resid(:,hw+1)'));
                    xlim([-hw hw]);



                    figure(cf);
                end
           end
           
           toc      
    end
    
    function LearnTemplate
        
        %templateSize should be odd
        hw=floor(templateSize/2);
        
        blobClips=zeros(2*hw+1,2*hw+1,tblobs(zPlane,tWin).n);
        blobClipBaseline=zeros(1,tblobs(zPlane,tWin).n);
        
        for n=1:tblobs(tWin).n
                       
             blobClips(:,:,n)=currentRawImage( tblobs(zPlane,tWin).y(n)-hw:tblobs(zPlane,tWin).y(n)+hw , tblobs(zPlane,tWin).x(n)-hw:tblobs(zPlane,tWin).x(n)+hw );
             
             bc=blobClips(:,:,n);
             blobClipBaseline(n)=min(bc(:));
             
             blobClips(:,:,n)=blobClips(:,:,n)-blobClipBaseline(n);
        end
        
        
        learnedTemplate=mean(blobClips,3);
        
        handles.templateImage.CData=learnedTemplate;      
        
        base('blobClips');
        base('blobClipBaseline');
    end
   
    function PlotTemplate
        
        axes('Position',[lm+.02+1.1*tb gh-6*lf .02 0.04]);
        handles.templateImage=imagesc(learnedTemplate);
        axis off;
        
        axes('Position',[lm+.02+1.1*tb gh-7.5*lf .02 0.04]);
        handles.templateImageInUse=imagesc(currentTemplateFilter);
        axis off;
        
        
    end

    function UseTemplate
        
        if isempty(learnedTemplate)
            
            LearnTemplate;
            handles.templateImageInUse.CData=learnedTemplate;
            
        end
        
        currentTemplateFilter=learnedTemplate;
        
        drawPlots;
        
    end

    function ResetTemplate
              
        currentTemplateFilter=defaultTemplateFilter;
        drawPlots;
        
    end

    function LoadOME(of)

            clear('TMIPMovie');
        
            disp('loading OME file...');
            
            TifLink = Tiff(OMEfile{of}, 'r');

            j=1;
            

            for t=1:1 %fi.numTInFile(of);  
               for z=1:fi.numZInFile(of)  
                  for c=1:numC
                    TifLink.setDirectory(j);            
                    TMIPMovie{z,c}(:,:,t)=double(TifLink.read());
                    j=j+1;
                    
                     %if mod(j,100)==1 disp([num2str(j) '.']); end
                  end      
               end          
            end  
            
            TifLink.close();   
            
            disp('loading done.');
            
    end

    function immat=LoadTMIP
        
        if fpw>10
            disp(['loading ' num2str(fpw) ' frames.']);
        end
        
        if tWin==numTW 
            
            numFrames=numTotalFrames-currentFrameNumber+1;

        else
            
            numFrames=fpw;
            
        end
        
        immat=zeros(TMIPh,TMIPw,numFrames);
        
        if loadOnTheFlyModeFlag && ~OMEModeFlag
                  
            for f=1:numFrames
                immat(:,:,f)=imread(tifFileNames_sorted{currentFrameNumber+f-1});
            end      

        elseif multiChannelModeFlag && OMEModeFlag
            
            for f=1:numFrames
                immat(:,:,f)=TMIPMovie{zPlane,cPlane}(:,:,f);
            end
            
        end
            
    end

    function updateData
               
        %load one .tif file
%         TMIPMovie{1}(:,:,tWin)=imread( tifFileNames_sorted{tWin});  
%         currentRawImage=squeeze(TMIPMovie{zPlane}(:,:,tWin));
%         
        currentRawImage=LoadTMIP;
        
        tblobs(zPlane,tWin)=FindBlobs(currentRawImage,threshold,rMin,tWin,currentTemplateFilter);
               
        if mergeChannelsModeFlag
            
            maxPix=0.5*max([max(max(TMIPMovie{zPlane,1}(:,:,1)))   max(max(TMIPMovie{zPlane,2}(:,:,1)))   ]);
            currentDisplayImage(:,:,1)=TMIPMovie{zPlane,1}(:,:,1)/maxPix;
            currentDisplayImage(:,:,2)=TMIPMovie{zPlane,3}(:,:,1)/maxPix;
            currentDisplayImage(:,:,3)=0; %TMIPMovie{zPlane,2}(:,:,1);
            
             base('currentDisplayImage');           
        else
            
            if handles.imageSelector1.Value==1
                currentDisplayImage=currentRawImage;
            elseif handles.imageSelector2.Value==1
                currentDisplayImage=currentFilteredImage;
            else
                currentDisplayImage=currentTemplatedImage;
            end
        
        end
        
        currentDisplayImage=ApplyImageDisplayTransform(currentDisplayImage);
        
        
        handles.mainPlot.CData=currentDisplayImage;
        
        handles.hMIP.YData=currentDisplayImage(:,round(thisX));  
        handles.vMIP.YData=currentDisplayImage(round(thisY),:);  
        
    end
       
    function imgOut=ApplyImageDisplayTransform(imgIn)
        
        imgOut=imgIn;
        
        if rotCWModeFlag
            imgOut=imgOut';
        end
        
        if flipLRModeFlag           
            imgOut=imgOut(:,end:-1:1,:);
        end
        
        if flipUDModeFlag
            imgOut=imgOut(end:-1:1,:,:);
        end
        

    end

    function tblobs_out=FindBlobs(frame,thresholdMargin,thisRmin,TWlist,templateFilter)
        
        %blob finding
        
        if filterWidth==0
            filt=1;
        else
            if strcmp(currentFilterType,'hipass')
                filt_unshifted=MexiHat2D(21,filterWidth);  %hi-pass filter
            else
                LoG=fspecial('log', 41, filterWidth/sqrt(2));
                filt_unshifted=-LoG/max(abs(LoG(:)));
            end
            
            filt=filt_unshifted-sum(filt_unshifted(:))/(size(filt_unshifted,1))^2;
              
        end


                thisThreshold=median(frame(:))+thresholdMargin;

                [federatedcenters,~,~,~,currentTemplatedImage,currentFilteredImage]=FastPeakFindSK(frame,thisThreshold,filt,thisRmin-1,med_filt_width,3,[],templateFilter,max_cutoff,post_threshold);

                if ~isempty(federatedcenters)
                    xi=federatedcenters.y';
                    yi=federatedcenters.x';
                else
                    xi=[];
                    yi=[];
                end

                tblobs_out.x=xi;  
                tblobs_out.y=yi;
                tblobs_out.n=length(tblobs_out.x);


    end

    function setupPlots
        %setup figure
        figure('Position',[200 200 1600 700]);  
        
        nc=6;
        nr=4;
        %main plot
        
        handles.axes=subplot(nr,nc,[1:5 7:11 13:17 ] );
        handles.axes.ButtonDownFcn=@MouseDownCallback;
        
        handles.axesH=subplot(nr,nc,[6 12 18]);
        handles.axesV=subplot(nr,nc,19:23);
        handles.zoomWindowaxes=subplot(nr,nc,nr*nc);  

    end

    function drawPlots
        
        updateData;
        
        UpdateFrameLabel;
        
        axes(handles.axes);

        hold off;
 
%         if ~singleImageModeFlag 
%             
%             rotate3d on;     
%             [X,Y] = meshgrid(1:TMIPw,1:TMIPh);
%             handles.mainPlot=surf(X,Y,img,'EdgeColor','none');
%             cameratoolbar;
%             view([-180 90]);
%             %set(gca,'DataAspectRatio',[1 1 100]);     
%             
%         else
%             
            
         handles.mainPlot=imagesc(currentDisplayImage,[clow chigh]);  
         
         %make axes clickable
         handles.mainPlot.HitTest='off';

         
%        end
        
        hold on;

        
        %for i=1:tblobs(zPlane,tWin).n

         %   exZ=img( tblobs(zPlane,tWin).y(i),TMIPw-tblobs(zPlane,tWin).x(i)+1 );
            
        %    if singleImageModeFlag
        neuronLabelOffset=4;

         if ~isempty(tblobs(zPlane,tWin).x)
             
             if rotCWModeFlag
                handles.ex=ex(tblobs(zPlane,tWin).y,tblobs(zPlane,tWin).x); 
             else
                handles.ex=ex(tblobs(zPlane,tWin).x,tblobs(zPlane,tWin).y);
             end
             
             for i=1:tblobs(zPlane,tWin).n
                handles.nLabels(i)=text(tblobs(zPlane,tWin).x(i)-neuronLabelOffset,tblobs(zPlane,tWin).y(i)-neuronLabelOffset,num2str(i),'Color','w');
             end
         else
             handles.ex=ex(0,0);
             handles.nLabels(1)=text(0,0,'x','Color','w');
         end
         
         if ~handles.showExs.Value
             set(handles.ex,'Visible','off');
             
         end

         
       %     else
              % ex3d(TMIPw-tblobs(zPlane,tWin).x(i)+1,tblobs(zPlane,tWin).y(i),  1.01*exZ );
       %     end
       % end

       
       
        %scanner lines
        handles.hLine=plot([1 imageW],[thisY thisY],'hitTest','off');
        handles.vLine=plot([thisX thisX],[1 imageH],'hitTest','off');

        
        %HMIP
        hMIP=currentDisplayImage(:,thisX);
        
        axes(handles.axesH);
        %handles.hMIP=plot(hMIP,(length(hMIP):-1:1)');
        handles.hMIP=plot(hMIP,(1:length(hMIP))');
        handles.axesH.YDir='reverse';
        ylim([0 imageH]);
        
        %VMIP
        vMIP=currentDisplayImage(thisY,:);
        axes(handles.axesV);
                
        handles.vMIP=plot(vMIP);
        xlim([0 imageW]);
        
     
        %zoom window
        axes(handles.zoomWindowaxes);
        zoomClip=[];
        handles.zoomImage=imagesc(zoomClip);
        
        UpdateZoomImage;
        
        axis square;  
        
        
        %%palette
        palettePopupMenuCallback;
       
        
        PlotTemplate;
        
        linkaxes([handles.axes handles.axesV],'x');
        linkaxes([handles.axes handles.axesH],'y');

        
    end

    function UpdateFrameLabel
        
        base('tifFileNames_sorted')
        if fpw==1
            handles.frameLabel.String=strrep(tifFileNames_sorted{currentFrameNumber},'_','\_');
        else
             handles.frameLabel.String=[strrep(tifFileNames_sorted{currentFrameNumber},'_','\_')  ' - TO - ' ...
                 strrep(tifFileNames_sorted{currentFrameNumber+fpw-1},'_','\_') ];
        end
        
    end


%{
    %this was for some old 3d thing
    function UpdateAxesExtents
        
        xLim=get(gca,'XLim');
        yLim=get(gca,'YLim');
        for i=2:3
            if i>2
                set(handles.axes(i),'XLim',xLim);
                set(handles.axes(i),'YLim',yLim);
            end
        end

         XSub=max([1 ceil(xLim(1))]):min([floor(xLim(2))  TMIPw ]);
         YSub=max([1 ceil(yLim(1))]):min([floor(yLim(2))  TMIPh ]);
         [Xm,Ym] = meshgrid(XSub,YSub);
%         

 %        disp([num2str(YSub(1)) '-' num2str(YSub(end)) ' ' num2str(XSub(1)) '-' num2str(XSub(end))]);
         
         imgSub=img(YSub,XSub);
 

%          set(handles.mainPlot,'XData',Xm);
%          set(handles.mainPlot,'YData',Ym);
%          set(handles.mainPlot,'ZData',imgSub);
%          
%          %axes(handles.axes(1));
%          %cameratoolbar;
% set(handles.axes(1),'yLim',[ YSub(1) YSub(end) ]);
% set(handles.axes(1),'xLim',[ XSub(1) XSub(end) ]);
%        set(handles.axes(1),'zLim',[min(imgSub(:))-1 max(imgSub(:))+1 ]);
%        set(handles.axes(1),'View', [-180 90]);

       % axes(handles.axes(1));
        %handles.Plot3D=surf(Xm,Ym,imgSub,'EdgeColor','none');
        %cameratoolbar;


    end
%}

    function updateColorPalettes
        
        palettePopupMenuCallback;
        
        if ~loadOnTheFlyModeFlag
            set(get(handles.imageLeftSide,'Parent'),'CLim',[clow chigh]);
            set(get(handles.imageRightSide,'Parent'),'CLim',[clow chigh]);
        else
            set(get(handles.mainPlot,'Parent'),'CLim',[clow chigh]);
            

        end
    end





end %wbBlobTester
