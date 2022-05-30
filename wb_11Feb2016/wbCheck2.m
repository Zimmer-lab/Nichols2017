function wbCheck2(neuron,wbstructFileName,passedHandles,diskModeFlag)
%wbCheck(neuron,wbstructfile,passedHandles,diskModeFlag)
%Saul Kato
%20131015
%view source movie for a neuron for wba
%allow annotation of cell id and notes

%% Preliminaries 

imageSequenceModeFlag=false;

neuronIDs=['---';LoadGlobalNeuronIDs];
paletteNames={'jet','hot','gray','autumn','summer'};

if nargin<4
    diskModeFlag=true;
end

if ~diskModeFlag
    disp('diskModeFlag set to false.  Running in RAM mode');
end

if nargin<3 || isempty(passedHandles)
    passedHandles=[];
end


if nargin<1 || isempty(neuron)
    neuron=1;
end

options.globalMovieFlag=1;

handles=[];
folder=pwd;

% load meta
metadata=load([folder filesep 'meta.mat']);

%TMIPMovie=wbloadTMIPs(maindir);
[TMIPMovie,numZ,numTW,validZs]=wbloadTMIPs(folder); %temp fix

% Load movies

if ~diskModeFlag
    ZMovie=wbloadmovies(folder);
else
    for i=1:metadata.fileInfo.numZ
        ZMovie{i}=zeros(metadata.fileInfo.height,metadata.fileInfo.width,metadata.fileInfo.numT);
    end
    
    
    %build hash tables for file lookups

    fileNumLookup=zeros(metadata.fileInfo.numT,1);
    framestarts=[0 cumsum(metadata.fileInfo.numTInFile)];      
    for ff=1:metadata.fileInfo.numFiles      

       fileNumLookup((1+framestarts(ff)):framestarts(ff+1))=ff;
       relFrameLookup((1+framestarts(ff)):framestarts(ff+1))=1:metadata.fileInfo.numTInFile(ff);

    end

    TifLinkRead=OpenTiffs(metadata);
       
    ZMovieOneFrame=GetZMovieFrame(1);
end

ZPlaneLabels=1:numZ;

%load wbstruct and populate wbstructfile
[wbstruct, wbstructFileName]=wbload(folder,true);


%% convenience variables
numN=wbstruct.nn;

for i=1:numN
    neuronNumLabel{i}=['neuron ' num2str(i)];
end

Rmax=wbstruct.options.Rmax;  %7;
Rbackground=wbstruct.options.Rbackground;

numbrightestpixels=wbstruct.options.numPixels; %50;

xbound=size(ZMovie{1},2);  %x and y are reversed in imagedata
ybound=size(ZMovie{1},1);  %ZMovies are taller than wide

numFrames=size(ZMovie{1},3);
% f_parents_one=zeros(numframes,1);
% f_parents_one_mean=mean(wbstruct.f_parents(:,bp));

%% declare globals
if numZ==1
    singleZModeFlag=true;
else
    singleZModeFlag=false;
end
    
replacementNeuron=[];

enableLocalTrackingFlag=false;
if enableLocalTrackingFlag
    damping=.8;
else
    damping=1;
end

parent_zplane=[];
cposx=[];
cposy=[];
ulposx=[];
ulposy=[];
dataedge_x1=[];
dataedge_y1=[];
dataedge_x2=[];
dataedge_y2=[];
background=[];
offsetx=[];
offsety=[];
bp=[];
b=[];
main=[];
ref=[];
centerPixelX=[];
centerPixelY=[];
centroidDeltaX=0;
centroidDeltaY=0;
lastDeltaDeltaX=0;
lastDeltaDeltaY=0;
xCentroidMask=[];
yCentroidMask=[];
ID1=[];
ID2=[];
ID3=[];
clow=3000;
chigh=32000;
notesString='';
deltaFOverF_onetrace=[];
frame=1;
F0=[];
currentZoomLevel=1;
currentZoomLimits=[];
maxZoomLevel=6;
zoomLevelLabels={};
for i=1:maxZoomLevel
    zoomLevelLabels=[zoomLevelLabels [num2str(i) 'x']];
end

playButtonLabels={'PLAY','PAUSE'};
neuronNumbersToggle=true;
simpleNeuronLookup=[];
MakeSimpleNumberLookupTable;
previousTW=1;

handles.allTextLabels=[];
handles.neuronCenterDotsInc=[];
handles.neuronCenterDotsExc=[];

%% get neuron data

currentZPlane=getNewNeuronData;

%% create new figure or use old one
if isfield(handles,'wbcheckHandle') && handles.wbcheckHandle ~= 0
    set(0,'CurrentFigure',handles.wbcheckHandle);
else
    figure('Position',[0 0 1200 1000],'KeyPressFcn', @(s,e) KeyPressedFcn);
    whitebg([0.05 0.05 0.05]);

end

nr=5;  nc=8;
cm=jet(256);cm(1,:)=[0 0 0];colormap(cm);
gap=.025;

%% GUI definition and callback functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

off1=.2;
handles.playButton = uicontrol('Style','togglebutton','Units','normalized','Position',[0.01 0.95 0.04 0.04],'String',playButtonLabels{1},'Callback',@(s,e) playButtonCallback);
handles.neuronPopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',neuron,'String',neuronNumLabel,'Position',[0.64-off1 0.94 0.11 0.04],'Callback',@(s,e) neuronPopupMenuCallback);

annotation('textbox',[0.80-off1 0.98 0.06 0.02],'String','ID 1','EdgeColor','none');
annotation('textbox',[0.87-off1 0.98 0.06 0.02],'String','ID 2','EdgeColor','none');
annotation('textbox',[0.94-off1 0.98 0.06 0.02],'String','ID 3','EdgeColor','none');

%handles.enableLocalTrackingCheckbox = uicontrol('Style','checkbox','Units','normalized','Position',[0.06 0.95 0.12 0.04],'Value',enableLocalTrackingFlag,'String','enable local tracking','Callback',@(s,e) enableLocalTrackingCallBack);

handles.neuronID1PopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',ID1,'String',neuronIDs,'Position',[0.79-off1 0.94 0.07 0.04],'Callback',@(s,e) neuronID1PopupMenuCallback);
handles.neuronID2PopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',ID2,'String',neuronIDs,'Position',[0.86-off1 0.94 0.07 0.04],'Callback',@(s,e) neuronID2PopupMenuCallback);
handles.neuronID3PopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',ID3,'String',neuronIDs,'Position',[0.93-off1 0.94 0.07 0.04],'Callback',@(s,e) neuronID3PopupMenuCallback);

handles.nextButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.75-off1 0.96 0.02 0.02],'String','+1','Callback',@(s,e) nextButtonCallback);
handles.prevButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.62-off1 0.96 0.02 0.02],'String','-1','Callback',@(s,e) prevButtonCallback);

handles.notesBox = uicontrol('Style','edit','Units','normalized','Max',4','Min',1,'Position',[0.76 0.40 0.2 0.12],'String',notesString,'HorizontalAlignment','left','KeyPressFcn',@(s,e) notesBoxImmediateCallback,'Callback',@(s,e) notesBoxCallback);
handles.notesBoxLabel = uicontrol('Style','text','Units','normalized','Position',[0.76 0.52 0.04 0.02],'String','notes');
handles.notesBoxSaveLabel = uicontrol('Style','text','Units','normalized','Position',[0.915 0.52 0.045 0.02],'String','SAVED');

handles.excludeButton =  uicontrol('Style','pushbutton','Units','normalized','Position',[0.85 0.96 0.1 0.022],'String','exclude','Callback',@(s,e) excludeButtonCallback);
handles.launchIEButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.96 0.96 0.02 0.022],'String','I.E.','Callback',@(s,e) launchIEButtonCallback);


%%Add linked ROI button
position.addLinkedROIButton=[.275 .55 .10 .025];
handles.addLinkedROIButton = uicontrol('Style','pushbutton','Units','normalized','Position',position.addLinkedROIButton,'String','add linked ROI','Callback',@(s,e) addLinkedROICallback);


%%Palette
off2=.14;
handles.imageMaxLevelSlider = uicontrol('Style','slider','Units','normalized','Position',[.2-off2 .52 .10 .05],'String','levels','Min',0.1,'Max',100,'SliderStep',[.01 .1],'Value',80); %,'Callback',@(s,e) disp('mouseup')
handles.imageMinLevelSlider = uicontrol('Style','slider','Units','normalized','Position',[.2-off2 .50 .10 .05],'String','minlevel','Min',0.1,'Max',100,'SliderStep',[.01 .1],'Value',30); %,'Callback',@(s,e) disp('mouseup')

adj=.03;
annotation('textbox',[0.15-off2 0.51+adj 0.06 0.02],'String','cutoffs','EdgeColor','none');
annotation('textbox',[0.185-off2 0.52+adj 0.03 0.02],'String','hi','EdgeColor','none');
annotation('textbox',[0.185-off2 0.50+adj 0.03 0.02],'String','lo','EdgeColor','none');
annotation('textbox',[0.165-off2 0.48+adj 0.04 0.02],'String','palette','EdgeColor','none');
handles.palettePopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',1,'String',paletteNames,'Position',[.2-off2 .48 .075 .05],'Callback',@(s,e) palettePopupMenuCallback);

hListener = addlistener(handles.imageMaxLevelSlider,'Value','PostSet',@(s,e) imageMaxLevelSliderCallback) ;
hListener = addlistener(handles.imageMinLevelSlider,'Value','PostSet',@(s,e) imageMinLevelSliderCallback) ;


%%Z plane navigation
lf=.02;
px=.3;py=.08;
annotation('textbox',[px py-lf 0.11 0.02],'String','Z Plane','EdgeColor','none');
handles.nextZButton = uicontrol('Style','pushbutton','Units','normalized','Position',[px+.06 py 0.02 0.02],'String','+1','Callback',@(s,e) ZupButtonCallback);
handles.prevZButton = uicontrol('Style','pushbutton','Units','normalized','Position',[px-.02 py 0.02 0.02],'String','-1','Callback',@(s,e) ZdownButtonCallback);
handles.ZPopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',currentZPlane,'String',ZPlaneLabels,'Position',[px py-.02 0.06 0.04],'Callback',@(s,e) ZPopupMenuCallback);


%%Z plane zoome
lf=.02;
px=.3;py=.03;
annotation('textbox',[px py-lf 0.11 0.02],'String','Zoom level','EdgeColor','none');
handles.zoomInButton = uicontrol('Style','pushbutton','Units','normalized','Position',[px+.06 py 0.02 0.02],'String','+1','Callback',@(s,e) zoomInButtonCallback);
handles.zoomOutButton = uicontrol('Style','pushbutton','Units','normalized','Position',[px-.02 py 0.02 0.02],'String','-1','Callback',@(s,e) zoomOutButtonCallback);
handles.zoomPopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',currentZoomLevel,'String',zoomLevelLabels,'Position',[px py-.02 0.06 0.04],'Callback',@(s,e) zoomPopupMenuCallback);

%% Draw initial figure

    drawPlots;
    updatePlots;
    
    imageMaxLevelSliderCallback;
    imageMinLevelSliderCallback;
   
%end main

%% subfunctions
    function KeyPressedFcn

        keyStroke=get(gcbo, 'CurrentKey');
        get(gcbo, 'CurrentCharacter');
        get(gcbo, 'CurrentModifier');

        if strcmp(keyStroke,'n')
            ToggleNeuronNumbersCallback;
            
        elseif strcmp(keyStroke,'leftarrow')
            
            ZdownButtonCallback;
            
        elseif strcmp(keyStroke,'rightarrow')
            
            ZupButtonCallback;
            
        elseif strcmp(keyStroke,'uparrow')
            
            zoomInButtonCallback;
            
        elseif strcmp(keyStroke,'downarrow')
            
            zoomOutButtonCallback;
            
        end
        
        
%         if strcmp(keyStroke,'leftarrow')
%             if (currentTW==1) 
%                 currentTW=numZ;
%             else
%                 currentTW=currentTW-1;
%             end
% 
%             DrawTWs(currentTW);
%             DrawStuff(currentTW);
% 
% 
%         elseif strcmp(keyStroke,'rightarrow')
%             if currentTW==numZ
%                 currentTW=1;l
%             else            
%                 currentTW=currentTW+1;
%             end
% 
%             DrawTWs(currentTW);
%             DrawStuff(currentTW);
%         elseif strcmp(keyStroke,'l')
%             RunLassoTool;
%             
%         elseif strcmp(keyStroke,'p')
%             PickButtonCallback;
%             
%         elseif strcmp(keyStroke,'t')
%             TextLabelToggleCallback;
%             
%         elseif strcmp(keyStroke,'s')
%             SimpleNumbersToggleCallback;
%             
%         elseif strcmp(keyStroke,'space')
%             ClearSelectionButtonCallback;
%             
%         elseif strcmp(keyStroke,'backspace')
%             ExcludeButtonCallback;
%             
%         elseif strcmp(keyStroke,'equal')
%             IncludeButtonCallback;
%             
%         elseif strcmp(keyStroke,'g')
%             BackToGridPlotCallback;         
% 
%         elseif strcmp(keyStroke,'escape')
%             pointerState='normal';
%             set(thisHandle, 'Pointer', 'arrow');
%         end


    end

    function MakeSimpleNumberLookupTable
        if ~isfield(wbstruct,'simple')
            wbMakeSimpleStruct(wbstructFileName);
        end
        simpleNeuronLookup=zeros(1,wbstruct.nn);
        for i=1:length(wbstruct.simple.nOrig)
            simpleNeuronLookup(wbstruct.simple.nOrig(i))=i;
        end
    end

    function out=TSlice()
        
        %out=1+floor((frame-1)/100);
        out = 1 + min([floor((frame-1)/wbstruct.options.smoothingTWindow) numTW-1]);  %matches wba calculation
    end

    function currentZPlane=getNewNeuronData()

        if neuron>length(wbstruct.neuronlookup)
            b=neuron;
        else
            b=wbstruct.neuronlookup(neuron); %lookup neuron sorted by position
        end
        bp=wbstruct.blobThreads.parentlist(b); %get blob for neuron b(byposition)
        parent_zplane=wbstruct.blobThreads_sorted.z(bp);
        
        F0=mean(wbstruct.f_bonded(:,b)-wbstruct.f_background(:,b));
        
        deltaFOverF_onetrace=NaN(size(wbstruct.deltaFOverF(:,1)));

        
        %populate notes box
        if isfield(wbstruct,'notes')  && isfield(wbstruct.notes,'neuron') && length(wbstruct.notes.neuron)>=neuron
            notesString=wbstruct.notes.neuron{neuron};
        else
            notesString='';
        end
        
        %load IDs
        if size(wbstruct.ID1,2)>=neuron
           
            
            if ~isempty(wbstruct.ID1{neuron})
                ID1=find(ismember(neuronIDs,wbstruct.ID1{neuron}));
            else ID1=1;
            end

            if size(wbstruct.ID2{neuron},2)>=2 && ~isempty(wbstruct.ID2{neuron})
                ID2=find(ismember(neuronIDs,wbstruct.ID2{neuron}));    
            else ID2=1;
            end

            if size(wbstruct.ID3{neuron},2)>=3 && ~isempty(wbstruct.ID3{neuron})
                ID3=find(ismember(neuronIDs,wbstruct.ID3{neuron}));
            else ID3=1;
            end

        else
            ID1=1;
            ID2=1;
            ID3=1;
        end

        currentZPlane=parent_zplane;
    end

    function thisFrame=getNewFrameData

        ulposx=wbstruct.blobThreads_sorted.x(TSlice,bp)-Rmax;
        ulposy=wbstruct.blobThreads_sorted.y(TSlice,bp)-Rmax;

        dataedge_x1=max([1 ulposx]);
        dataedge_y1=max([1 ulposy]);
        dataedge_x2=min([xbound ulposx+2*Rmax]);
        dataedge_y2=min([ybound ulposy+2*Rmax]);

        %background mask computation
        background.mastermask=uint16(circularmask(Rbackground));

        background.maskedge_x1=max([1 2+Rbackground-wbstruct.blobThreads_sorted.x(TSlice,bp)]);
        background.maskedge_y1=max([1 2+Rbackground-wbstruct.blobThreads_sorted.y(TSlice,bp)]);
        background.maskedge_x2=min([xbound-wbstruct.blobThreads_sorted.x(TSlice,bp)+Rbackground+1  2*Rbackground+1]);
        background.maskedge_y2=min([ybound-wbstruct.blobThreads_sorted.y(TSlice,bp)+Rbackground+1 2*Rbackground+1]);   

        background.ulposx=wbstruct.blobThreads_sorted.x(TSlice,bp)-Rbackground;
        background.ulposy=wbstruct.blobThreads_sorted.y(TSlice,bp)-Rbackground;
        background.dataedge_x1=max([1 background.ulposx]);
        background.dataedge_y1=max([1 background.ulposy]);
        background.dataedge_x2=min([xbound background.ulposx+2*Rbackground]);
        background.dataedge_y2=min([ybound background.ulposy+2*Rbackground]); 
% 
        offsetx=-background.maskedge_x1-(2*Rbackground-background.maskedge_x2);
        offsety=-background.maskedge_y1-(2*Rbackground-background.maskedge_y2);

        %blit edge-cropped round mastermask with extracted edge-cropped rectangle from binarized buffer
        background.mask=background.mastermask(background.maskedge_x1:background.maskedge_x2,background.maskedge_y1:background.maskedge_y2)'   .* ...
        uint16(wbstruct.MT(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2,wbstruct.blobThreads_sorted.z(bp),TSlice)==0);

       % [xCentroidMask, yCentroidMask]=centroidmask([dataedge_x2-dataedge_x1+1 , dataedge_y2-dataedge_y1+1]);
       
        centerPixelX=(dataedge_x2-dataedge_x1+1)/2+0.5;
        centerPixelY=(dataedge_y2-dataedge_y1+1)/2+0.5; 
        
        thisFrame=GetZMovieFrame(frame);      
       
        main.cropframe=thisFrame{parent_zplane}(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2);
        main.cropframe_masked=(wbstruct.mask_nooverlap{TSlice,bp}').*main.cropframe;
        allquantpixels=main.cropframe_masked(:);            

        [vals,pixels]=sort(main.cropframe_masked(:),'descend');  %sort pixels by brightness
       
       
       f_parents_one(frame)=mean(vals(1:min([length(vals) numbrightestpixels])));  %take the mean of the brightest pixels      

       main.cropframe_brightest=main.cropframe_masked;
       main.cropframe_brightest(pixels(numbrightestpixels+1:end))=0;

       main.cropframe_background=thisFrame{parent_zplane}(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2);
       main.cropframe_background_circularstamp=main.cropframe_background.*background.mastermask(background.maskedge_x1:background.maskedge_x2,background.maskedge_y1:background.maskedge_y2)';
       main.cropframe_background_masked=main.cropframe_background.*background.mask;
       
       [background.vals, ~]=sort(main.cropframe_background_masked(:),'descend');  %sort pixels by brightness
       f_background_one(frame)=mean(background.vals);  %take the mean of all background pixels      

       ref.cropframe=TMIPMovie{parent_zplane}(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2,TSlice);
       
       %quantify children+parent

      for bb=1:length(wbstruct.blobThreads_sorted.children{bp}) %quantify multi  

           ulposx=wbstruct.blobThreads_sorted.x(TSlice,wbstruct.blobThreads_sorted.children{bp}(bb))-Rmax;
           ulposy=wbstruct.blobThreads_sorted.y(TSlice,wbstruct.blobThreads_sorted.children{bp}(bb))-Rmax;
           dataedge_x1=max([1 ulposx]);
           dataedge_y1=max([1 ulposy]);
           dataedge_x2=min([xbound ulposx+2*Rmax]);
           dataedge_y2=min([ybound ulposy+2*Rmax]);

           cropframechild=thisFrame{wbstruct.blobThreads_sorted.z(wbstruct.blobThreads_sorted.children{bp}(bb))}(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2);
           cropframe_add=(wbstruct.mask_nooverlap{TSlice,wbstruct.blobThreads_sorted.children{bp}(bb)}').*cropframechild;
           allquantpixels=[allquantpixels; cropframe_add(:)]; 

      end

      [vals, ~]=sort(allquantpixels,'descend');  %sort pixels by brightness
      f_bonded_one(frame)=mean(vals(1:min([length(vals) wbstruct.options.numPixelsBonded])));



       deltaFOverF_onetrace(frame)=(f_bonded_one(frame)-f_background_one(frame))/F0-1;


       
    end

    function drawPlots()

           thisFrame=getNewFrameData;  
       
           subtightplot(nr,nc,1,gap);
           handles.cropframe_masked_image=imagesc(main.cropframe_masked,[clow chigh]);
           hold on;
           handles.centroid_ex0=ex(centerPixelX,centerPixelY,[],'g');
           handles.centroid_ex1=ex(centerPixelX,centerPixelY,[],'r');

           axis square; axis off;
           title('mask area');

           subtightplot(nr,nc,2,gap);
           handles.cropframe_brightest_image=imagesc(main.cropframe_brightest,[clow chigh]);
           axis square;  axis off;
           title('brightest pix');

           %plot background region
           subtightplot(nr,nc,nc+1,gap);
           handles.cropframe_background_circularstamp=imagesc(main.cropframe_background_circularstamp,[clow chigh]);
           hold on;  
           rectangle('Curvature', [1 1], 'Position',[1+Rbackground-Rmax+offsetx 1+Rbackground-Rmax+offsety 1+2*Rmax 1+2*Rmax],'FaceColor','none','EdgeColor','r');             
           axis image;axis off;
           title('background area');

           %plot masked background region
           subtightplot(nr,nc,nc+2,gap);
           handles.cropframe_background_masked=imagesc(main.cropframe_background_masked,[clow chigh]);
           axis image;axis off;
           title('masked background');

           %plot reference movie background region
           handles.cropframe_refAxes=subtightplot(nr,nc,nc+3,gap);
           handles.cropframe_ref=imagesc(ref.cropframe,[clow chigh]);
           set(handles.cropframe_ref,'HitTest','off');
                   
           handles.cropframe_refCircle=rectangle('Curvature', [1 1], 'Position',[1+Rbackground-Rmax+offsetx 1+Rbackground-Rmax+offsety 1+2*Rmax 1+2*Rmax],'FaceColor','none','EdgeColor','r');
           set(handles.cropframe_refCircle,'HitTest','off');
           axis image; axis off;
           title('motion ref movie');

       
           %plot parent plane
           cs=3;
           handles.parentPlanePlot=subtightplot(nr,nc,[2*nc+cs 3*nc+cs 4*nc+cs],gap);
           
           hold off;
           cropframe_full=thisFrame{currentZPlane};
           handles.parentZimage=imagesc(cropframe_full,[clow chigh]);
           hold on;

           handles.parentPlaneCircle=rectangle('Curvature',[1 1],'Position',[dataedge_x1 dataedge_y1 dataedge_x2-dataedge_x1  dataedge_y2-dataedge_y1],'EdgeColor',[1 1 0]);
           handles.parentPlaneBackgroundCircle=rectangle('Curvature',[1 1],'Position',[background.dataedge_x1+offsetx background.dataedge_y1+offsety 1+2*Rbackground 1+2*Rbackground],'EdgeColor',[1 0 0]);
           handles.parentPlaneZLabel=textur(['Z' num2str(currentZPlane)]);
           
           title('parent Z');
          
           axis image; axis off; 
           

           %plot flanking planes

           cs=2;
           handles.leftChildPlanePlot=subtightplot(nr,nc,[2*nc+cs 3*nc+cs 4*nc+cs],gap);
           hold off;
           
           
%            if wbstruct.blobThreads_sorted.z(bp)>1
%                cropframe_full=ZMovie{wbstruct.blobThreads_sorted.z(bp)-1}(:,:,frame);
%            else
%                cropframe_full=zeros(size(cropframe_full));
%            end
%            handles.lowerZimage=imagesc(cropframe_full,[clow chigh]);
%            
           %update left flanking Z movie frame
           if currentZPlane>1
               cropframe_full=thisFrame{currentZPlane-1};
           else
               cropframe_full=zeros(size(cropframe_full));
           end
           handles.lowerZimage=imagesc(cropframe_full,[clow chigh]);

%           set(handles.lowerZimage,'CData',cropframe_full);
           set(get(handles.lowerZimage,'Parent'),'CLim',[clow chigh]);

           hold on;
           
           handles.leftchildPlaneCircle=rectangle('Curvature',[1 1],'Position',[dataedge_x1 dataedge_y1 dataedge_x2-dataedge_x1  dataedge_y2-dataedge_y1],'EdgeColor',[1 1 0]);     
           handles.leftchildPlaneBackgroundCircle=rectangle('Curvature',[1 1],'Position',[background.dataedge_x1+offsetx background.dataedge_y1+offsety 1+2*Rbackground 1+2*Rbackground],'EdgeColor',[1 0 0]);
           handles.leftchildPlaneZLabel=textur(['Z' num2str(currentZPlane-1)]);
           title('Z-1');
           axis image; axis off;  

           cs=4;
           handles.rightChildPlanePlot=subtightplot(nr,nc,[2*nc+cs 3*nc+cs 4*nc+cs],gap);
           
           hold off;
           
%            if wbstruct.blobThreads_sorted.z(bp)<numZ
%                cropframe_full=ZMovie{wbstruct.blobThreads_sorted.z(bp)+1}(:,:,frame);
%            else
%                cropframe_full=zeros(size(cropframe_full));
%            end
%            handles.upperZimage=imagesc(cropframe_full,[clow chigh]);
%            


           %update right flanking Z movie frame
           if currentZPlane<numZ
               cropframe_full=thisFrame{currentZPlane+1};
           else
               cropframe_full=zeros(size(cropframe_full));
           end

           %set(handles.upperZimage,'CData',cropframe_full);
           handles.upperZimage=imagesc(cropframe_full,[clow chigh]);
           set(get(handles.upperZimage,'Parent'),'CLim',[clow chigh]);

           hold on;
                
           handles.rightchildPlaneCircle=rectangle('Curvature',[1 1],'Position',[dataedge_x1 dataedge_y1 dataedge_x2-dataedge_x1  dataedge_y2-dataedge_y1],'EdgeColor',[1 1 0]);
           handles.rightchildPlaneBackgroundCircle=rectangle('Curvature',[1 1],'Position',[background.dataedge_x1+offsetx background.dataedge_y1+offsety 1+2*Rbackground 1+2*Rbackground],'EdgeColor',[1 0 0]);
           handles.rightchildPlaneZLabel=textur(['Z' num2str(currentZPlane+1)]);
           title('Z+1');
           axis image; axis off;  


           %plot mask patchwork Z
           cs=5;
           handles.maskAxes=subtightplot(nr,nc,[2*nc+cs,3*nc+cs,4*nc+cs],gap);
           cla;
           handles.mask=imagesc(squeeze(wbstruct.MT(:,:,parent_zplane,TSlice)));
           hold on;
           handles.maskPlaneCircle=rectangle('Curvature',[1 1],'Position',[dataedge_x1 dataedge_y1 dataedge_x2-dataedge_x1  dataedge_y2-dataedge_y1],'EdgeColor',[1 1 0]);
           handles.maskPlaneBackgroundCircle=rectangle('Curvature',[1 1],'Position',[background.dataedge_x1+offsetx background.dataedge_y1+offsety 1+2*Rbackground 1+2*Rbackground],'EdgeColor',[1 0 0]);
           textur(['Z' num2str(parent_zplane)]);
           title('masks');
           axis image; %axis off; 

           %make mask image clickable
           set(handles.maskAxes,'ButtonDownFcn',@ClickMaskCallback);
           set(handles.maskAxes,'HitTest','on');
           set(handles.mask,'HitTest','off');
           
           
           
           %plot colorbar
           cs=1;
           subtightplot(nr,nc,[2*nc+cs,3*nc+cs,4*nc+cs],gap);
           axis image;
           axis off;
           colorbar;


       %plot traces from wbstruct
       handles.axtraces=subtightplot(nr,nc,4:(nc-1),gap);
       hold off;
       p=plot(wbstruct.tv,wbstruct.deltaFOverFNoBackSub(:,neuron),'r');
       set(p,'HitTest','off');
       hold on;
       pp=plot(wbstruct.tv,wbstruct.deltaFOverF(:,neuron),'b');
       set(pp,'HitTest','off');       
       handles.deltaFOverF=plot(wbstruct.tv,deltaFOverF_onetrace,'g');

       %set plot limits
       ylim1=1.5*min(wbstruct.deltaFOverF(:,neuron));
       ylim2=1.5*max(wbstruct.deltaFOverF(:,neuron));
       if isnan(ylim1) ylim1=0; end
       if isnan(ylim2) ylim2=1; end   
       ylim([ylim1 ylim2]);
       xlim([0 wbstruct.tv(end)]);
       
       
       %listen for mouseDown events in all subplots
       set(handles.axtraces, 'ButtonDownFcn',@mouseDownCallback);
       handles.redline=line([wbstruct.tv(frame) wbstruct.tv(frame)],[ylim1 ylim2],'Color','r');
       handles.frametext=textlr([num2str(frame) '/' num2str(numFrames)],0,10,[0.5 0.5 0.5]);
       legend({'\DeltaF/F_{0} no backsub','\DeltaF/F'});
       hold off;

       
       
       %plot background trace and plot overall mean trace
        subtightplot(nr,nc,nc+(4:(nc-1)),gap);
        plot(wbstruct.tv,mean(wbstruct.f_parents,2)/mean(wbstruct.f_parents(:))-1,'r');    
        hold on;
        
        plot(wbstruct.tv,wbstruct.f_background(:,neuron)/mean(wbstruct.f_background(:,neuron))-1,'b');
        
 
        legend({'\DeltaF/F_{0} globalmean','\DeltaF/F_{0} background'});
 
        xlim([wbstruct.tv(1) wbstruct.tv(end)]); 
        hold off;

       %set state of Exclude button
       if isfield(wbstruct,'exclusionList')
           if ismember(neuron,wbstruct.exclusionList)
                set(handles.excludeButton,'String','EXCLUDED.');
                set(handles.excludeButton,'BackgroundColor','g');
           else
            set(handles.excludeButton,'String','exclude');
            set(handles.excludeButton,'BackgroundColor','default');           
           end
       else %not excluded
            set(handles.excludeButton,'String','exclude');
            set(handles.excludeButton,'BackgroundColor','default');
       end
        
       %set state of ID dropdowns
       set(handles.neuronID1PopupMenu,'Value',ID1);
       set(handles.neuronID2PopupMenu,'Value',ID2);
       set(handles.neuronID3PopupMenu,'Value',ID3);
        
       
       %set notes both
       set(handles.notesBox,'String',notesString);
       
       %set palette
       palettePopupMenuCallback;

       UpdateLabels();
       
       drawnow;
       

    end

    function updatePlots()
                
           thisFrame=getNewFrameData;

           base('handles');
           
           set(handles.cropframe_brightest_image,'CData',main.cropframe_brightest); 
           set(handles.cropframe_masked_image,'CData',main.cropframe_masked)  

           set(handles.cropframe_background_circularstamp,'CData',main.cropframe_background_circularstamp);
           set(handles.cropframe_background_masked,'CData',main.cropframe_background_masked);

           set(handles.cropframe_ref,'CData',ref.cropframe);
    
           %%%OK
           
           
           
           %update Z UI
           set(handles.ZPopupMenu,'Value',currentZPlane);
           
           %update zoom UI
           set(handles.zoomPopupMenu,'Value',currentZoomLevel);
           
           %update parent Z movie frame
           
           cropframe_full=thisFrame{currentZPlane};
                      
           set(handles.parentZimage,'CData',cropframe_full);
           set(get(handles.parentZimage,'Parent'),'CLim',[clow chigh]);

           %set axes limits based on currentZoomLevel
           if currentZoomLevel>1
               set(get(handles.parentZimage,'Parent'),'XLim',[-round(xbound/currentZoomLevel)/2 round(xbound/currentZoomLevel)/2]+round(mean(dataedge_x1,dataedge_x2)));
               set(get(handles.parentZimage,'Parent'),'YLim',[-round(ybound/currentZoomLevel)/2 round(ybound/currentZoomLevel)/2]+round(mean(dataedge_y1,dataedge_y2)));
           else
               set(get(handles.parentZimage,'Parent'),'XLim',[0.5 round(xbound/currentZoomLevel)+0.5]);
               set(get(handles.parentZimage,'Parent'),'YLim',[0.5 round(ybound/currentZoomLevel)+0.5]);
           end
             
           if currentZPlane==parent_zplane              
                set(handles.parentPlaneCircle,'Visible','on');
                set(handles.parentPlaneBackgroundCircle,'Visible','on');
           else
                set(handles.parentPlaneCircle,'Visible','off');
                set(handles.parentPlaneBackgroundCircle,'Visible','off');
           end
           
           set(handles.parentPlaneZLabel,'String',['Z' num2str(currentZPlane)]);
           
           set(handles.parentPlaneCircle,'Position',[dataedge_x1 dataedge_y1 dataedge_x2-dataedge_x1  dataedge_y2-dataedge_y1]);
           set(handles.parentPlaneBackgroundCircle,'Position',[background.dataedge_x1+offsetx background.dataedge_y1+offsety 1+2*Rbackground 1+2*Rbackground]); 
       
           %update left flanking Z movie frame
           if currentZPlane>1
               cropframe_full=thisFrame{currentZPlane-1};

           else
               cropframe_full=zeros(size(cropframe_full));
           end
           set(handles.lowerZimage,'CData',cropframe_full);
           set(get(handles.lowerZimage,'Parent'),'CLim',[clow chigh]);

           %set axes limits based on currentZoomLevel
           if currentZoomLevel>1
              set(get(handles.lowerZimage,'Parent'),'XLim',[-round(xbound/currentZoomLevel)/2 round(xbound/currentZoomLevel)/2]+round(mean(dataedge_x1,dataedge_x2)));
              set(get(handles.lowerZimage,'Parent'),'YLim',[-round(ybound/currentZoomLevel)/2 round(ybound/currentZoomLevel)/2]+round(mean(dataedge_y1,dataedge_y2)));
           else
              set(get(handles.lowerZimage,'Parent'),'XLim',[0.5 round(xbound/currentZoomLevel)+0.5]);
              set(get(handles.lowerZimage,'Parent'),'YLim',[0.5 round(ybound/currentZoomLevel)+0.5]);
           end
            
           if currentZPlane==parent_zplane && currentZPlane>1
                
                   set(handles.leftchildPlaneCircle,'Visible','on');
                   set(handles.leftchildPlaneBackgroundCircle,'Visible','on');
      
           else
                   set(handles.leftchildPlaneCircle,'Visible','off');
                   set(handles.leftchildPlaneBackgroundCircle,'Visible','off');

           end
                        
           

                                    
           set(handles.leftchildPlaneCircle,'Position',[dataedge_x1 dataedge_y1 dataedge_x2-dataedge_x1  dataedge_y2-dataedge_y1]);
           set(handles.leftchildPlaneBackgroundCircle,'Position',[background.dataedge_x1+offsetx background.dataedge_y1+offsety 1+2*Rbackground 1+2*Rbackground]);
           
         
           
           set(handles.leftchildPlaneZLabel,'String',['Z' num2str(currentZPlane-1)]);

           %update right flanking Z movie frame
           if currentZPlane<numZ
               cropframe_full=thisFrame{currentZPlane+1};
           else
               cropframe_full=zeros(size(cropframe_full));
           end

           set(handles.upperZimage,'CData',cropframe_full);
           set(get(handles.upperZimage,'Parent'),'CLim',[clow chigh]);

           
           
           

           
           %set axes limits based on currentZoomLevel
           if currentZoomLevel>1
               set(get(handles.upperZimage,'Parent'),'XLim',[-round(xbound/currentZoomLevel)/2 round(xbound/currentZoomLevel)/2]+round(mean(dataedge_x1,dataedge_x2)));
               set(get(handles.upperZimage,'Parent'),'YLim',[-round(ybound/currentZoomLevel)/2 round(ybound/currentZoomLevel)/2]+round(mean(dataedge_y1,dataedge_y2)));
           else
               set(get(handles.upperZimage,'Parent'),'XLim',[0.5 round(xbound/currentZoomLevel)+0.5]);
               set(get(handles.upperZimage,'Parent'),'YLim',[0.5 round(ybound/currentZoomLevel)+0.5]);
           end
           
           
           if currentZPlane==parent_zplane && currentZPlane<numZ
                
                   set(handles.rightchildPlaneCircle,'Visible','on');
                   set(handles.rightchildPlaneBackgroundCircle,'Visible','on');
      
           else
                   set(handles.rightchildPlaneCircle,'Visible','off');
                   set(handles.rightchildPlaneBackgroundCircle,'Visible','off');

           end
           
           set(handles.rightchildPlaneCircle,'Position',[dataedge_x1 dataedge_y1 dataedge_x2-dataedge_x1  dataedge_y2-dataedge_y1]);
           set(handles.rightchildPlaneBackgroundCircle,'Position',[background.dataedge_x1+offsetx background.dataedge_y1+offsety 1+2*Rbackground 1+2*Rbackground]);
           set(handles.rightchildPlaneZLabel,'String',['Z' num2str(currentZPlane+1)]);

                    
           %update mask
           set(handles.mask,'CData',squeeze(wbstruct.MT(:,:,parent_zplane,TSlice)));
           set(handles.maskPlaneCircle,'Position',[dataedge_x1 dataedge_y1 dataedge_x2-dataedge_x1  dataedge_y2-dataedge_y1]);
           set(handles.maskPlaneBackgroundCircle,'Position',[background.dataedge_x1+offsetx background.dataedge_y1+offsety 1+2*Rbackground 1+2*Rbackground]);
       

           
           
           %set axes limits based on currentZoomLevel
           if currentZoomLevel>1
               set(get(handles.mask,'Parent'),'XLim',[-round(xbound/currentZoomLevel)/2 round(xbound/currentZoomLevel)/2]+round(mean(dataedge_x1,dataedge_x2)));
               set(get(handles.mask,'Parent'),'YLim',[-round(ybound/currentZoomLevel)/2 round(ybound/currentZoomLevel)/2]+round(mean(dataedge_y1,dataedge_y2)));
           else
               set(get(handles.mask,'Parent'),'XLim',[0.5 round(xbound/currentZoomLevel)+0.5]);
               set(get(handles.mask,'Parent'),'YLim',[0.5 round(ybound/currentZoomLevel)+0.5]);
           end
       
       %trace plot updates
       
       set(handles.deltaFOverF,'YData',deltaFOverF_onetrace);
       set(handles.redline,'XData',[wbstruct.tv(frame) wbstruct.tv(frame)]);
       set(handles.frametext,'String',[num2str(frame) '/' num2str(numFrames)]);

       if previousTW ~= TSlice()  
          UpdateLabels();
       end
       
       drawnow;

       previousTW=TSlice();  %update previousTW
       
    end

    function UpdateLabels()
               
            
            if ishghandle(handles.allTextLabels)
                delete(handles.allTextLabels);
            end
            handles.allTextLabels=[];
            
            if ishghandle(handles.neuronCenterDotsInc)
                delete(handles.neuronCenterDotsInc);
            end
            handles.neuronCenterDotsInc=[];
            
            if ishghandle(handles.neuronCenterDotsExc)
                delete(handles.neuronCenterDotsExc);
            end
            handles.neuronCenterDotsExc=[];
            
            if isfield(handles,'leftChildPlanePlot')
                axes(handles.leftChildPlanePlot);
                DrawNeuronLabels(currentZPlane-1);
            end
            
            if isfield(handles,'parentPlanePlot')    
                axes(handles.parentPlanePlot);
                DrawNeuronLabels(currentZPlane);         
            end
            
            if isfield(handles,'rightChildPlanePlot')                                       
                axes(handles.rightChildPlanePlot);
                DrawNeuronLabels(currentZPlane+1);          
            end
            

        
    end

    function DrawNeuronLabels(thisZ)
           if thisZ<1 || thisZ > numZ
               return;
           end
           
           simpleNumbersToggle=false;
           goodColor='g';
           excludedColor='r';
           replacedColor='c';
                      
           showOnlyParentPlaneNeurons=true;
                          
           tw=TSlice;

           if showOnlyParentPlaneNeurons
           
               for n=1:wbstruct.nn
                   
                    if ~isfield(handles,'allTextLabels' )
                           handles.allTextLabels=[];
                    end

                    if ismember(n,wbstruct.exclusionList)
                        thisColor=excludedColor;
                    elseif isfield(wbstruct,'replacements') && ismember(n,wbstruct.replacements.neuron)
                        thisColor=replacedColor;
                    else
                        thisColor=goodColor;
                    end

                    if simpleNumbersToggle

                        if ~ismember(n,wbstruct.exclusionList)
                            neuronLabel=num2str(simpleNeuronLookup(n));
                        else
                            neuronLabel='X';
                        end

                    else
                        neuronLabel='X';
                         
                        neuronLabel=num2str(n);

                    end


                    if neuronNumbersToggle && wbstruct.nz(n)==thisZ
                        %numerical labels       
                        if wbstruct.blobThreads_sorted.y(tw,n) < ybound-20  && (wbstruct.nz(n)<numZ ||  wbstruct.blobThreads_sorted.x(tw,n)<xbound-30)
                           thisTextLabel=text(wbstruct.nx(tw,n),wbstruct.ny(tw,n),[' ' neuronLabel],'Color',thisColor,'VerticalAlignment','top');
                           handles.allTextLabels=[handles.allTextLabels thisTextLabel];
                        else
                           thisTextLabel=text(wbstruct.nx(tw,n),wbstruct.ny(tw,n),[' ' neuronLabel],'Color',thisColor,'VerticalAlignment','bottom','HorizontalAlignment','right');
                           handles.allTextLabels=[handles.allTextLabels thisTextLabel];
                        end
  
                    end
               end
               
               
               if ~isfield(handles,'neuronCenterDotsInc')
                   handles.neuronCenterDotsInc=[];
               end
               
               if ~isfield(handles,'neuronCenterDotsExc')
                   handles.neuronCenterDotsExc=[];
               end
               
               %draw neuron center points
               nValid=false(1,wbstruct.nn);
               nValid(wbstruct.nz==thisZ)=true;
               nValid(wbstruct.exclusionList)=false;
               
               nValidExcluded=false(1,wbstruct.nn);
               nValidExcluded(wbstruct.exclusionList)=true;
               nValidExcluded(wbstruct.nz~=thisZ)=false;
               
               thisNeuronCenterDotsInc=plot(wbstruct.nx(tw,nValid),wbstruct.ny(tw,nValid),'Marker','.','Color',goodColor,'LineStyle','none');
               thisNeuronCenterDotsExc=plot(wbstruct.nx(tw,nValidExcluded),wbstruct.ny(tw,nValidExcluded),'Marker','.','Color',excludedColor,'LineStyle','none');
               handles.neuronCenterDotsInc=[handles.neuronCenterDotsInc thisNeuronCenterDotsInc];
               handles.neuronCenterDotsExc=[handles.neuronCenterDotsExc thisNeuronCenterDotsExc];
               
           else %show all neurons

               
               
               for n=1:wbstruct.tblobs(tw,thisZ).n

    %                 if ismember(n,wbstruct.exclusionList)
    %                     thisColor=excludedColor;
    %                 elseif isfield(wbstruct,'replacements') && ismember(n,wbstruct.replacements.neuron)
    %                     thisColor=replacedColor;
    %                 else
    %                     thisColor=goodColor;
    %                 end
    
                    thisColor='g';

                    neuronLabel=num2str(wbstruct.tblobs(tw,thisZ).tparents(n));

                    if neuronNumbersToggle && wbstruct.nz(n)==thisZ
                        %numerical labels       

                        if   wbstruct.tblobs(tw,thisZ).y(n) < ybound-20 
                           text(wbstruct.tblobs(tw,thisZ).x(n),wbstruct.tblobs(tw,thisZ).y(n),[' ' neuronLabel],'Color',thisColor,'VerticalAlignment','top');
                        else
                           text(wbstruct.tblobs(tw,thisZ).x(n),wbstruct.tblobs(tw,thisZ).y(n),[' ' neuronLabel],'Color',thisColor,'VerticalAlignment','bottom','HorizontalAlignment','right');
                        end

                    end
               end
               
               
           end
           
    end

    function updateColorPalettes
        
        palettePopupMenuCallback;
        set(get(handles.parentZimage,'Parent'),'CLim',[clow chigh]);
        set(get(handles.upperZimage,'Parent'),'CLim',[clow chigh]);
        set(get(handles.lowerZimage,'Parent'),'CLim',[clow chigh]);
        set(get(handles.cropframe_brightest_image,'Parent'),'CLim',[clow chigh]);
        set(get(handles.cropframe_masked_image,'Parent'),'CLim',[clow chigh]);
        set(get(handles.cropframe_background_circularstamp,'Parent'),'CLim',[clow chigh]);
        set(get(handles.cropframe_background_masked,'Parent'),'CLim',[clow chigh]);
        set(get(handles.cropframe_ref,'Parent'),'CLim',[clow chigh]);
  
        
    end

    function LinkedROISubwindow
        
        handles.linkedROISubwindow=figure('Position',[400 200 700 700],'name','Linked ROI Picker');
        
        for sp=1:7
            subplot(7,1,sp);
            plot(wbstruct.tv,wbstruct.added.neighbors(end).deltaFOverF(:,sp));
            xlim([wbstruct.tv(1) wbstruct.tv(end)]);
            if sp-4 > 0
                sign='+';
            else
                sign='';
            end
            uicontrol('Style','pushbutton','Units','normalized','Position',[.01 .05+.12*(8-sp),.1,.03],'String',['Pick  Z' sign num2str(sp-4)],'Callback',@(s,e) SubwindowPickButtonCallback(sp));
        end   
        uicontrol('Style','popupmenu','Units','normalized','Position',[.4 .95,.2,.03],'Value',1,'String',['add new neuron' neuronNumLabel],'Callback',@(s,e) SubwindowPickReplacementNeuronCallback);
        annotation('textbox','Units','normalized','Position',[.25 .95,.2,.03],'String','neuron to replace:','EdgeColor','none');

        
        title('Pick a Z plane.');
    end

    function TifLinkReadObject=OpenTiffs(metadata)
        
        for f=1:metadata.fileInfo.numFiles
            TifLinkReadObject(f) = Tiff(metadata.fileInfo.filenames{f}, 'r');    
        end
        
    end

    function CloseTiffs(TifLinkReadObject,metadata)
        
        for f=1:metadata.fileInfo.numFiles
             TifLinkReadObject(f).close();
        end       
        
    end

    function ZMovieOneFrame=GetZMovieFrame(frameNum)

            %load all planes for one time point
            
            ZMovieOneFrame=cell(metadata.fileInfo.numZ,1);  %initialize
          
            if ~diskModeFlag && ~imageSequenceModeFlag
                
                for zz=1:metadata.fileInfo.numZ
                    ZMovieOneFrame{zz}=ZMovie{zz}(:,:,frameNum);
                end
                
            elseif imageSequenceModeFlag
                
                ZMovieOneFrame=imread(tifFileNames_sorted{frameNum});
                
            else  %progressive OME reading
                            
                f=fileNumLookup(frameNum);
                
                numValidZ=validZs(end);
                
                for zz=validZs
                
                    relFrameNum=relFrameLookup(frameNum);
                    
                    thisImage=wbReadOneImageFromTiffObj(TifLinkRead(f),metadata.fileInfo.numZ,metadata.fileInfo.numTInFile(f),1,zz,relFrameNum,1,'xyztc');
                    
                    if strcmp(metadata.wormSideUp,'Right')

                        if strcmp(metadata.noseDirection,'North')
                            ZMovieOneFrame{numValidZ-zz+1}=thisImage(:,end:-1:1);
                        elseif strcmp(metadata.noseDirection,'South')           
                            ZMovieOneFrame{numValidZ-zz+1}=thisImage(end:-1:1,:);
                        elseif strcmp(metadata.noseDirection,'West')
                            %tempImage=thisImage(end:-1:1,:)';
                            ZMovieOneFrame{numValidZ-zz+1}=thisImage';                    
                        else  %East noseDirection              
                            ZMovieOneFrame{numValidZ-zz+1}=thisImage(end:-1:1,end:-1:1)';
                        end


                    else %wormSideUp Left

                        if strcmp(metadata.noseDirection,'North')
                            ZMovieOneFrame{zz}=thisImage;
                        elseif strcmp(metadata.noseDirection,'South')           
                            ZMovieOneFrame{zz}=thisImage(end:-1:1,end:-1:1);
                        elseif strcmp(metadata.noseDirection,'West')
                            ZMovieOneFrame{zz}=thisImage(end:-1:1,:)';
                        else  %East noseDirection
                            tempImage=thisImage(end:-1:1,:)';
                            ZMovieOneFrame{zz}=tempImage(end:-1:1,end:-1:1);
                        end

                    end
                    
                    
                    
                    
                end
                               
            end
    end

%% CALLBACKS

    function ClickMaskCallback(hObject,~)
        
        cursorPoint = get(handles.maskAxes, 'CurrentPoint');
        clickedX=round(cursorPoint(1,1));
        clickedY=round(cursorPoint(1,2));
        
        if wbstruct.MT(clickedY,clickedX,parent_zplane,TSlice)>0 
            %wbstruct.blobThreads_sorted.parent(wbstruct.MT(clickedY,clickedX,parent_zplane,TSlice))
            if wbstruct.blobThreads_sorted.parent(wbstruct.MT(clickedY,clickedX,parent_zplane,TSlice))==-1
                tmp= find(wbstruct.blobThreads.parentlist==wbstruct.MT(clickedY,clickedX,parent_zplane,TSlice));
                pickedNeuron=find(wbstruct.neuronlookup==tmp);
                
            else %not a parent neuron, so get the parent neuron
                
                tmp= find(wbstruct.blobThreads.parentlist==wbstruct.blobThreads_sorted.parent(wbstruct.MT(clickedY,clickedX,parent_zplane,TSlice)));
                if tmp>0
                   pickedNeuron=find(wbstruct.neuronlookup==tmp);
                else
                   pickedNeuron=0;
                end
            end

%disp(['picked Neuron=' num2str(pickedNeuron)]);   
            
            if pickedNeuron>0
                   
                neuron=pickedNeuron;
                set(handles.neuronPopupMenu,'Value',neuron);
                getNewNeuronData;
                currentZPlane=parent_zplane;
                drawPlots;
                updatePlots;

            end
        
        end
    end

    function ToggleNeuronNumbersCallback
        neuronNumbersToggle=~neuronNumbersToggle;
        drawPlots;
    end
    
    function launchIEButtonCallback
        if isfield(passedHandles,'wbInteractiveExclude') && ishghandle(passedHandles.wbInteractiveExclude)
            figure(passedHandles.wbInteractiveExclude);
        else
            passedHandles.wbInteractiveExclude=wbInteractiveExclude(wbstruct,wbstructFileName,handles);
        end
    end

    function SubwindowPickReplacementNeuronCallback

        replacementNeuron=get(gcbo,'Value')-1;  %neuron number
        
    end
    
    function SubwindowPickButtonCallback(sp)
         
        [wbstruct, wbstructFileName]=wbload(folder,false);
        wbstruct.added.neighbors(end).picked=sp;
        
        %%%%%%%%%%%%%%%%%%%%%
        %update wbstruct data   
        if replacementNeuron>0  %this indicates an existing neuron
        
%               if ~isfield(wbstruct,'replacements')
%                   wbstruct.replacements.deltaFOverF=[]; 
%                   wbstruct.replacements.neuron=[];                   
%               end

              %wbstruct.replacements.deltaFOverF=[wbstruct.replacements.deltaFOverF wbstruct.deltaFOverF(:,replacementNeuron)];
              %wbstruct.replacements.neuron=[wbstruct.replacements.neuron replacementNeuron];
              %wbstruct.deltaFOverF(:,replacementNeuron)=wbstruct.added.neighbors(end).deltaFOverF(:,wbstruct.added.neighbors(end).picked);
            
            if ~isfield(wbstruct,'replacements')
                wbstruct.replacements.OLDdeltaFOverF=[];   
                wbstruct.replacements.OLDf0=[];
                wbstruct.replacements.neuron=[];
                wbstruct.replacements.OLDnx=[];
                wbstruct.replacements.OLDny=[];
                wbstruct.replacements.OLDnz=[];
            end
 
            if ~isfield(wbstruct,'f0')
                wbAddID;
                [wbstruct,wbstructFileName]=wbload([],false);
            end
            
            wbstruct.replacements.OLDdeltaFOverF=[wbstruct.replacements.OLDdeltaFOverF wbstruct.deltaFOverF(:,replacementNeuron)];
            
            wbstruct.replacements.OLDf0=[wbstruct.replacements.OLDf0 wbstruct.f0(replacementNeuron)];
            wbstruct.replacements.OLDnx=[wbstruct.replacements.OLDnx wbstruct.nx(:,replacementNeuron)];
            wbstruct.replacements.OLDny=[wbstruct.replacements.OLDny wbstruct.ny(:,replacementNeuron)];
            wbstruct.replacements.OLDnz=[wbstruct.replacements.OLDnz wbstruct.nz(replacementNeuron)];
 
            wbstruct.replacements.neuron=[wbstruct.replacements.neuron replacementNeuron];
 
            %overwrite old neuron data
            wbstruct.deltaFOverF(:,replacementNeuron)=wbstruct.added.neighbors(end).deltaFOverF(:,wbstruct.added.neighbors(end).picked);
            wbstruct.deltaFOverFNoBackSub(:,replacementNeuron)=wbstruct.added.neighbors(end).deltaFOverFNoBackSub(:,wbstruct.added.neighbors(end).picked);
            
            if isfield(wbstruct,'deltaFOverF_bc')
                wbPToptions.processType='bc';
                wbPToptions.saveFlag=false;
                BCoptions.processParams.method='exp';
                BCoptions.processParams.fminfac=0.9;
                BCoptions.processParams.startFrames=1000;
                BCoptions.processParams.endFrames=100;
                BCoptions.processParams.coop=0;
                BCoptions.processParams.looseness=0.1;
                wbstruct.deltaFOverF_bc(:,replacementNeuron)=bleachcorrect(wbstruct.added.neighbors(end).deltaFOverF(:,wbstruct.added.neighbors(end).picked),BCoptions);
            end           
            
            wbstruct.f0(replacementNeuron)=wbstruct.added.neighbors(end).f0(wbstruct.added.neighbors(end).picked);
            wbstruct.nx(:,replacementNeuron)=wbstruct.added.x(:,end);
            wbstruct.ny(:,replacementNeuron)=wbstruct.added.y(:,end);
            wbstruct.nz(replacementNeuron)=wbstruct.added.neighbors(end).z(wbstruct.added.neighbors(end).picked);



        else  %add a new neuron
            
            
            if ~isfield(wbstruct,'replacements')
                wbstruct.replacements.OLDdeltaFOverF=[]; 
                wbstruct.replacements.OLDf0=[];
                wbstruct.replacements.neuron=[];
                wbstruct.replacements.OLDnx=[];
                wbstruct.replacements.OLDny=[];
                wbstruct.replacements.OLDnz=[];
            end
 
            wbstruct.replacements.OLDdeltaFOverF=[wbstruct.replacements.OLDdeltaFOverF NaN(size(wbstruct.deltaFOverF,1),1)];
            wbstruct.replacements.OLDf0=[wbstruct.replacements.OLDf0 NaN];
            wbstruct.replacements.OLDnx=[wbstruct.replacements.OLDnx NaN(size(wbstruct.tblobs,2),1)];
            wbstruct.replacements.OLDny=[wbstruct.replacements.OLDny NaN(size(wbstruct.tblobs,2),1)];
            wbstruct.replacements.OLDnz=[wbstruct.replacements.OLDnz NaN];
 
            wbstruct.replacements.neuron=[wbstruct.replacements.neuron wbstruct.nn+1];
 
            %add new neuron data
            wbstruct.deltaFOverF(:,wbstruct.nn+1)=wbstruct.added.neighbors(end).deltaFOverF(:,wbstruct.added.neighbors(end).picked);
            wbstruct.deltaFOverFNoBackSub(:,wbstruct.nn+1)=wbstruct.added.neighbors(end).deltaFOverFNoBackSub(:,wbstruct.added.neighbors(end).picked);
            wbstruct.f0(wbstruct.nn+1)=wbstruct.added.neighbors(end).f0(wbstruct.added.neighbors(end).picked);
            
            if isfield(wbstruct,'deltaFOverF_bc')
                wbPToptions.processType='bc';
                wbPToptions.saveFlag=false;
                wbstruct.deltaFOverF_bc(:,wbstruct.nn+1)=wbProcessTraces(wbstruct.added.neighbors(end).deltaFOverF(:,wbstruct.added.neighbors(end).picked),wbPToptions);
            end
            
            if size(wbstruct.nx,1)==1
                disp('wbCheck> this wbstruct has an old version of the .nx field.  Automatically updating wbstruct.');
                wbUpdateXYtoTimeSeries;
                [wbstruct,wbstructFileName]=wbload([],false);
            end
                
            wbstruct.nx(:,wbstruct.nn+1)=wbstruct.added.x(:,end);
            wbstruct.ny(:,wbstruct.nn+1)=wbstruct.added.y(:,end);
            wbstruct.nz(wbstruct.nn+1)=wbstruct.added.neighbors(end).z(wbstruct.added.neighbors(end).picked);

            wbstruct.nn=wbstruct.nn+1;
            
            %augment stateParams matrix
            if isfield(wbstruct.simple,'stateParams')
                wbstruct.simple.stateParams=[wbstruct.simple.stateParams, [0 0]'];
            end
            
        end
        
        
        %update .simple
        wbstruct=wbMakeSimpleStruct(wbstruct,false,false);
        
        %update .simple.derivs
        if isfield(wbstruct.simple,'derivs')
            if isfield(wbstruct,'deltaFOverF_bc')
                wbstruct.simple.derivs.traces=[wbstruct.simple.derivs.traces, wbDeriv(wbstruct.deltaFOverF_bc(:,end),'reg',wbstruct.simple.derivs.alpha,wbstruct.simple.derivs.numIter)];
            else
                wbstruct.simple.derivs.traces=[wbstruct.simple.derivs.traces, wbDeriv(wbstruct.deltaFOverF(:,end),'reg',wbstruct.simple.derivs.alpha,wbstruct.simple.derivs.numIter)];
            end
        end
        
        wbSave(wbstruct,wbstructFileName);
        
        close(handles.linkedROISubwindow);
        
        %update wbInteractiveExclude if it has been opened
        if isfield(passedHandles,'wbInteractiveExclude') && ishghandle(passedHandles.wbInteractiveExclude)
            close(passedHandles.wbInteractiveExclude);
            passedHandles.wbInteractiveExclude=wbInteractiveExclude(wbstruct,wbstructFileName,handles);
        end
        
        
        h=PopupBoxMsg('Linked neuron saved.');
        pause(2);
        close(h);
        
    end
        
    function addLinkedROICallback()
        
        %highlight motion ref image in red
        
        axes(handles.cropframe_refAxes);
        xl=get(handles.cropframe_refAxes,'XLim');
        yl=get(handles.cropframe_refAxes,'YLim');
        handles.addLinkedROIActiveRect=rectangle('Position',[1 .5  xl(2)-1 yl(2)-.5],'EdgeColor','r','LineWidth',1.5);       
        handles.addLinkedROITextMsg=annotation('textbox','Position',position.addLinkedROIButton+[.02 .02 0 0],'String','click on new ROI.',...
            'Color','r','EdgeColor','none','FontSize',10);
        
        handles.addLinkedROIArrow=annotation('arrow','Position',position.addLinkedROIButton.*[1 1 0 0]+[.05 .04 0.00 0.04],...
            'Color','r');
        
        %set(handles.cropframe_ref,'HitTest','off');
        set(handles.addLinkedROIActiveRect,'HitTest','off');
        set(handles.cropframe_refAxes,'Visible','on');
        set(handles.cropframe_refAxes, 'ButtonDownFcn',@addLinkedROIMouseDownCallback);

        
    end

    function addLinkedROIMouseDownCallback(hObject,~)
        

        cursorPoint = get(hObject, 'CurrentPoint'); 
        row = round(cursorPoint(1,1));
        col = round(cursorPoint(1,2));
        
        linkXDelta=-(size(ref.cropframe,1)+1)/2+row;
        linkYDelta=-(size(ref.cropframe,1)+1)/2+col;
        
        hold on;

        if isfield(handles,'addLinkedROIMouseDownPixelHighlight') && ishghandle(handles.addLinkedROIMouseDownPixelHighlight)
            set(handles.addLinkedROIMouseDownPixelHighlight,'Position',[row-.5 col-.5 1 1]);
        else
            axes(handles.cropframe_refAxes);
            handles.addLinkedROIMouseDownPixelHighlight=rectangle('Position',[row-.5 col-.5 1 1],'EdgeColor','w');
        end
        
        if ishghandle(handles.addLinkedROITextMsg)
           delete(handles.addLinkedROITextMsg);
        end
        
        if ishghandle(handles.addLinkedROIArrow)
           delete(handles.addLinkedROIArrow);
        end
        
        %confirm/cancel buttons
        set(handles.addLinkedROIButton,'String','confirm');
        set(handles.addLinkedROIButton,'Callback',@(s,e) confirmLinkedROICallback([linkXDelta linkYDelta]));
        
       
    end

    function confirmLinkedROICallback(xyoffset_vec2D)
        
        %do it
        handle.popupBoxMsg=PopupBoxMsg('Quantifying linked neuron');
        
        thisoptions.offset=-xyoffset_vec2D;
        thisoptions.addToWbstruct=true;
        thisoptions.useExistingMask=false;
        
        wbstruct=wbQuantifyROI(folder,neuron,thisoptions);
               
        close(handle.popupBoxMsg);
        
        LinkedROISubwindow;
                
        %return GUI to normal state
        if ishghandle(handles.addLinkedROIActiveRect)
           delete(handles.addLinkedROIActiveRect);
        end

        if ishghandle(handles.addLinkedROIMouseDownPixelHighlight)
            delete(handles.addLinkedROIMouseDownPixelHighlight);
        end
        
        set(handles.cropframe_refAxes,'Visible','off');

        set(handles.addLinkedROIButton,'String','add linked ROI');
       
        
        set(handles.addLinkedROIButton,'Callback',@(s,e) addLinkedROICallback);
        
        

        
    end

    function cancelLinkedROICallback
    end
                
    %%MOVIE ZOOM
    function zoomInButtonCallback()
        if currentZoomLevel<maxZoomLevel
            currentZoomLevel=currentZoomLevel+1;
        else
            currentZoomLevel=1;
        end
        set(handles.ZPopupMenu,'Value',currentZoomLevel);
        updatePlots;  
    end

    function zoomOutButtonCallback()
        if currentZoomLevel>1
            currentZoomLevel=currentZoomLevel-1;
        else
            currentZoomLevel=maxZoomLevel;
        end
        set(handles.ZPopupMenu,'Value',currentZoomLevel);
        updatePlots;    
    end

    function zoomPopupMenuCallback()
        currentZoomLevel=get(gcbo,'Value');
        updatePlots;

    end

    
    %%MOVIE NAV
    function ZupButtonCallback()
        if currentZPlane<numZ
            currentZPlane=currentZPlane+1;
        else
            currentZPlane=1;
        end
        set(handles.ZPopupMenu,'Value',currentZPlane);
        drawPlots;
        updatePlots;
         
    end

    function ZdownButtonCallback()
        if currentZPlane>1
            currentZPlane=currentZPlane-1;
        else
            currentZPlane=numZ;
        end
        set(handles.ZPopupMenu,'Value',currentZPlane);
        drawPlots;
        updatePlots;
    end

    function ZPopupMenuCallback()
        currentZPlane=get(gcbo,'Value');
        drawPlots;
        updatePlots;
    end

    function palettePopupMenuCallback
        
        colormap(paletteNames{get(handles.palettePopupMenu,'Value')});  
        cm=colormap;
        cm(1,:)=[0 0 0];
        colormap(cm);
        
    end

    function imageMaxLevelSliderCallback
    
        sliderValue=max([get(handles.imageMaxLevelSlider,'Value') get(handles.imageMinLevelSlider,'Value')]);
    
        chigh=sliderValue*400;

        updateColorPalettes;

    end
        
    function imageMinLevelSliderCallback
    
        sliderValue=min([get(handles.imageMinLevelSlider,'Value') get(handles.imageMaxLevelSlider,'Value')]);
    
        clow=sliderValue*100;

        updateColorPalettes;
        
    end
        
    function neuronID1PopupMenuCallback

         ID1=get(gcbo,'Value');
         if ID1==1
 %           wbstruct.ID{neuron}{1}=[]; 
            wbstruct.ID1{neuron}=[]; 
         else
            wbstruct.ID{neuron}{1}=neuronIDs{ID1};
 %           wbstruct.ID1{neuron}=neuronIDs{ID1}; 
         end
 %       ID=wbstruct.ID;
         ID1=wbstruct.ID1;
 %        save(wbstructFileName,'-append','ID','ID1');  
         save(wbstructFileName,'-append','ID1');  
    end

    function neuronID2PopupMenuCallback

         ID2=get(gcbo,'Value');
         if ID2==1
 %          wbstruct.ID{neuron}{2}=[]; 
            wbstruct.ID2{neuron}=[]; 
         else
 %          wbstruct.ID{neuron}{2}=neuronIDs{ID2};
            wbstruct.ID2{neuron}=neuronIDs{ID2};
         end
 %        ID=wbstruct.ID;
         ID2=wbstruct.ID2;
 %       save(wbstructFileName,'-append','ID','ID2');   
         save(wbstructFileName,'-append','ID2');            
    end

    function neuronID3PopupMenuCallback

         ID3=get(gcbo,'Value');
         
         if ID3==1
 %            wbstruct.ID{neuron}{3}=[]; 
             wbstruct.ID3{neuron}=[]; 
         else
 %            wbstruct.ID{neuron}{3}=neuronIDs{ID3};
             wbstruct.ID3{neuron}=neuronIDs{ID3};
         end
 %       ID=wbstruct.ID;
         ID3=wbstruct.ID3;
         %save(wbstructFileName,'-append','ID','ID3');
         save(wbstructFileName,'-append','ID3');  
    end

    function mouseDownCallback(hObject,~)

        %get(hObject)
        pos=get(hObject,'CurrentPoint'); %pos is 2x3??
        %disp(['You clicked X:',num2str(pos(1,1))]); 
        previousTW=TSlice();
        frame=round((pos(1,1))/wbstruct.tv(2));
        
        %drawPlots;
        updatePlots;

    end

    function notesBoxImmediateCallback

        set(handles.notesBoxSaveLabel,'BackgroundColor','r');
        set(handles.notesBoxSaveLabel,'String','UNSAVED.');

    end

    function notesBoxCallback

        str=get(gcbo,'String');
        wbstruct.notes.neuron{neuron}=str;
        notes=wbstruct.notes;
        save(wbstructFileName,'-append','notes');

        set(handles.notesBoxSaveLabel,'BackgroundColor','g');
        set(handles.notesBoxSaveLabel,'String','SAVED.');

    end

    function excludeButtonCallback

        if strcmp(get(gcbo,'String'),'exclude')
            if isfield(wbstruct,'exclusionList')
                neuron
                %exclusionList=[wbstruct.exclusionList(1:find(wbstruct.exclusionList<neuron,1,'last')) neuron wbstruct.exclusionList(1+find(wbstruct.exclusionList<neuron,1,'last'):end)]; %ninja insert code
                exclusionList=[wbstruct.exclusionList neuron];
                exclusionList=sort(exclusionList);
            else
                disp('did not find exclusionList.  creating one.');
                exclusionList=neuron;
            end
            
            wbstruct.exclusionList=exclusionList;
            
            set(handles.excludeButton,'String','EXCLUDED.');
            set(handles.excludeButton,'BackgroundColor','r');
            drawnow;
            save(wbstructFileName,'exclusionList','-append');
            
            set(handles.excludeButton,'String','EXCLUDED.');
            set(handles.excludeButton,'BackgroundColor','g');

        else %unexclude
            
            
            wbstruct.exclusionList(wbstruct.exclusionList==neuron)=[];            
            
            set(handles.excludeButton,'String','exclude');
            set(handles.excludeButton,'BackgroundColor','r');
            
            
            drawnow; 
            
            exclusionList=wbstruct.exclusionList;
            save(wbstructFileName,'exclusionList','-append');
            
            set(handles.excludeButton,'String','exclude');
            set(handles.excludeButton,'BackgroundColor','default');
            

        end

        %update the wbgridplot figure that originated this wbcheck instance
        currentFigure=gcf;
        if isstruct(passedHandles)
            wbgridplotOptions.useExistingFigureHandle=0;
            wbgridplotOptions.useExistingFigureHandle=passedHandles.fig;
            wbgridplotOptions.saveFlag=0;
            wbgridplotOptions.wbcheckHandle=currentFigure;
            wbGridPlot(wbstruct,wbgridplotOptions);
            drawnow;
            set(0,'CurrentFigure',currentFigure);
        end

    end

    function playButtonCallback()

        while get(gcbo,'Value')==1
            
            set(handles.playButton,'String',playButtonLabels{2});
            
            if frame<numFrames
                frame=frame+1;
            else
                frame=1;
            end
                
            updatePlots;

        end
        set(handles.playButton,'String',playButtonLabels{1});
        
    end

    function nextButtonCallback()
        if neuron<numN
            neuron=neuron+1;
        else
            neuron=1;
        end
        set(handles.neuronPopupMenu,'Value',neuron);
        getNewNeuronData;
        currentZPlane=parent_zplane;
        drawPlots;
        updatePlots;     
    end

    function prevButtonCallback()
        if neuron>1
            neuron=neuron-1;
        else
            neuron=numN;
        end
        set(handles.neuronPopupMenu,'Value',neuron);
        getNewNeuronData;
        currentZPlane=parent_zplane;
        drawPlots;
        updatePlots;     
    end

    function neuronPopupMenuCallback()
        neuron=get(gcbo,'Value');
        getNewNeuronData;
        currentZPlane=parent_zplane;
        drawPlots;
        updatePlots;

    end

    function enableLocalTrackingCallBack
        enableLocalTrackingFlag=get(gcbo,'Value');
    end

end %main
