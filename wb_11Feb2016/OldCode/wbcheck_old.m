function wbcheck_old(neuron,wbstructfile,passedHandles)
%wbcheck-old(neuron,wbstructfile,passedHandles)
%Saul Kato
%20131015
%view source movie for a neuron

%% Preliminaries 
neuronIDs=loadNeuronIDs;
paletteNames={'jet','hot','gray','autumn','summer'};

if nargin<3
    passedHandles=0;
end

if nargin<1
    neuron=1;
end

options.globalMovieFlag=1;
%
% Load movies
%
handles=[];
maindir=pwd;
zmoviefiles=dir( [maindir '/StabilizedZMovies/*.tif']);

%using new Tif library for loading
if options.globalMovieFlag && evalin('base','exist(''ZMovie'',''var'')==1');
    disp('>using ZMovie already in workspace.');
    ZMovie=evalin('base', 'ZMovie');
else       
    disp('>loading Zmovies...'); 
    tic
    warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning');
    for z=1:length(zmoviefiles)
        fprintf('%d...',z-1); 
        FileTif=[maindir '/StabilizedZMovies/' zmoviefiles(z).name];
        InfoImage=imfinfo(FileTif);
        mImage=InfoImage(1).Width;
        nImage=InfoImage(1).Height;
        NumberImages=length(InfoImage);
        ZMovie{z}=zeros(nImage,mImage,NumberImages,'uint16');
        TifLink = Tiff(FileTif, 'r');
        for i=1:NumberImages   
            TifLink.setDirectory(i);   
            ZMovie{z}(:,:,i)=TifLink.read();
        end
        TifLink.close();
    end
    fprintf('%d.\n',z);
    warning('on','MATLAB:imagesci:tiffmexutils:libtiffWarning');
    if options.globalMovieFlag
        assignin('base','ZMovie',ZMovie);
    end
    toc
end
numZ=length(zmoviefiles);


if nargin<2 || isempty(wbstructfile)
    if exist('Quant/wbstruct.mat','file')
        load('Quant/wbstruct.mat');
        wbstructfile='Quant/wbstruct.mat';
    elseif exist('wbstruct.mat','file')
        load('wbstruct.mat');
        wbstructfile='wbstruct.mat';
    else
        disp('wbstruct.mat could not be found. quitting wbcheck.');
        
        return;
    end
else
    load(wbstructfile);
end


numN=length(wbstruct.neuronlookup);

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

%% get neuron data

getNewNeuronData;

%% create new figure or use old one
if isfield(handles,'wbcheckHandle') && handles.wbcheckHandle ~= 0
    set(0,'CurrentFigure',handles.wbcheckHandle);
else
    figure('Position',[0 0 1200 1000]);
    whitebg([0.05 0.05 0.05]);

end

nr=5;  nc=8;
cm=jet(256);cm(1,:)=[0 0 0];colormap(cm);
gap=.025;
frame=1;

%% GUI definition and callback functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% handles.hSlider = uicontrol('Style','slider','Position',[20 20 figwidth-30 20],'SliderStep',[1/(ds.numFrames+1) 1/(ds.numFrames+1)],'Value',1/(ds.numFrames+1)); %,'Callback',@(s,e) disp('mouseup')
% handles.savePDFButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.01 0.86 0.04 0.03],'String','save screen','Callback',@(s,e) savePDFButtonCallback(m));
% handles.saveframeButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.19 0.76 0.06 0.03],'String','save movieframe','Callback',@(s,e) saveFrameButtonCallback);
% handles.saveEMoviesButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.69 0.76 0.06 0.03],'String','save Eigen movies','Callback',@(s,e) saveEMoviesButtonCallback);
% 
% 
% handles.preloadMovieButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.06 0.93 0.06 0.03],'String','preload movie','Callback',@(s,e) preloadMovieButtonCallback(options));
% handles.autoPreloadMovieCheckbox = uicontrol('Style','checkbox','Units','normalized','Position',[0.12 0.93 0.06 0.03],'Value',ds.autoPreloadMovieFlag,'String','AUTO','Callback',@(s,e) autoPreloadMovieButtonCheckbox(options));
% 
% handles.reanalyzeButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.06 0.90 0.04 0.03],'String','reanalyze','Callback',@(s,e) reanalyzeButtonCallback(m,options));
% 
% annotation('textbox',[0.08 0.85 0.04 0.03],'EdgeColor','none','String','Show:');
% handles.showOriginalAnglesDataCheckbox = uicontrol('Style','checkbox','Units','normalized','Position',[0.08 0.84 0.08 0.03],'Value',0,'String','Original Kymo','Callback',@(s,e) showOriginalAnglesDataCheckbox(m,options));
% handles.showBiasPlotsCheckbox = uicontrol('Style','checkbox','Units','normalized','Position',[0.08 0.82 0.08 0.03],'Value',1,'String','Bias','Callback',@(s,e) showBiasPlotsCheckbox(m,options));
% handles.showVAFPlotsCheckbox = uicontrol('Style','checkbox','Units','normalized','Position',[0.08 0.80 0.08 0.03],'Value',1,'String','VAFs','Callback',@(s,e) showVAFPlotsCheckbox(m,options));
% handles.showSpeedPlotsCheckbox = uicontrol('Style','checkbox','Units','normalized','Position',[0.08 0.78 0.08 0.03],'Value',1,'String','Speed and Omega','Callback',@(s,e) showSpeedPlotsCheckbox(m,options));
% 
% handles.eigenwormsCheckbox = uicontrol('Style','checkbox','Units','normalized','Position',[0.7 0.96 0.08 0.03],'Value',1,'String','recon. worms','Callback',@(s,e) headUpCheckbox(m,options));
% 
% handles.headUpCheckbox = uicontrol('Style','checkbox','Units','normalized','Position',[0.6 0.96 0.08 0.03],'Value',0,'String','head up','Callback',@(s,e) headUpCheckbox(m,options));
% 
% handles.eigenPlotPopup = uicontrol('Style','popup','Units','normalized','Position',[0.905 0.95 0.08 0.03],'String','eigenworms|E1-9 recon.','Callback',@(s,e) eigenPlotPopup(m,options));
% 
% 
% handles.trackDownButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.01 0.91 0.015 0.03],'String','tr-1','Callback',@(s,e) trackDownButtonCallback(m,options));
% handles.trackTextField = uicontrol('Style','edit','Units','normalized','Position',[0.03 0.935 0.02 0.03],'String','1','Callback',@(s,e) trackTextFieldCallback(m,options));
% 
% handles.zoomInButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.01 0.82 0.02 0.04],'String','Z+','Callback',@(s,e) zoomInButtonCallback(m));
% handles.zoomOutButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.01 0.78 0.02 0.04],'String','Z-','Callback',@(s,e) zoomOutButtonCallback(m));

off1=.2;
handles.playButton = uicontrol('Style','togglebutton','Units','normalized','Position',[0.01 0.95 0.04 0.04],'String','PLAY','Callback',@(s,e) playButtonCallback);
handles.neuronPopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',neuron,'String',neuronNumLabel,'Position',[0.64-off1 0.94 0.11 0.04],'Callback',@(s,e) neuronPopupMenuCallback);

annotation('textbox',[0.80-off1 0.98 0.06 0.02],'String','ID 1','EdgeColor','none');
annotation('textbox',[0.87-off1 0.98 0.06 0.02],'String','ID 2','EdgeColor','none');
annotation('textbox',[0.94-off1 0.98 0.06 0.02],'String','ID 3','EdgeColor','none');

handles.enableLocalTrackingCheckbox = uicontrol('Style','checkbox','Units','normalized','Position',[0.06 0.95 0.12 0.04],'Value',enableLocalTrackingFlag,'String','enable local tracking','Callback',@(s,e) enableLocalTrackingCallBack);

handles.neuronID1PopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',ID1,'String',neuronIDs,'Position',[0.79-off1 0.94 0.07 0.04],'Callback',@(s,e) neuronID1PopupMenuCallback);
handles.neuronID2PopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',ID2,'String',neuronIDs,'Position',[0.86-off1 0.94 0.07 0.04],'Callback',@(s,e) neuronID2PopupMenuCallback);
handles.neuronID3PopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',ID3,'String',neuronIDs,'Position',[0.93-off1 0.94 0.07 0.04],'Callback',@(s,e) neuronID3PopupMenuCallback);

handles.nextButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.75-off1 0.96 0.02 0.02],'String','+1','Callback',@(s,e) nextButtonCallback);
handles.prevButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.62-off1 0.96 0.02 0.02],'String','-1','Callback',@(s,e) prevButtonCallback);

handles.notesBox = uicontrol('Style','edit','Units','normalized','Max',4','Min',1,'Position',[0.76 0.80 0.2 0.12],'String',notesString,'HorizontalAlignment','left','KeyPressFcn',@(s,e) notesBoxImmediateCallback,'Callback',@(s,e) notesBoxCallback);
handles.notesBoxLabel = uicontrol('Style','text','Units','normalized','Position',[0.76 0.92 0.04 0.02],'String','notes');
handles.notesBoxSaveLabel = uicontrol('Style','text','Units','normalized','Position',[0.915 0.92 0.045 0.02],'String','SAVED');

handles.excludeButton =  uicontrol('Style','pushbutton','Units','normalized','Position',[0.85 0.96 0.1 0.022],'String','exclude','Callback',@(s,e) excludeButtonCallback);

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

%% Draw initial figure

    drawPlots;
    updatePlots;
    imageMaxLevelSliderCallback;
    imageMinLevelSliderCallback;
    
%end main

%% nested functions

    function getNewNeuronData()

        b=wbstruct.neuronlookup(neuron); %lookup neuron sorted by position
        bp=wbstruct.blobs.parentlist(b); %get blob for neuron b(byposition)

        parent_zplane=wbstruct.blobs_sorted.z(bp);

        cposx=wbstruct.blobs_sorted.x(bp);
        cposy=wbstruct.blobs_sorted.y(bp);
        ulposx=cposx-Rmax;
        ulposy=cposy-Rmax;

        dataedge_x1=max([1 ulposx]);
        dataedge_y1=max([1 ulposy]);
        dataedge_x2=min([xbound ulposx+2*Rmax]);
        dataedge_y2=min([ybound ulposy+2*Rmax]);

        %background mask computation
        background.mastermask=uint16(circularmask(Rbackground));

        background.maskedge_x1=max([1 2+Rbackground-wbstruct.blobs_sorted.x(bp)]);
        background.maskedge_y1=max([1 2+Rbackground-wbstruct.blobs_sorted.y(bp)]);
        background.maskedge_x2=min([xbound-wbstruct.blobs_sorted.x(bp)+Rbackground+1  2*Rbackground+1]);
        background.maskedge_y2=min([ybound-wbstruct.blobs_sorted.y(bp)+Rbackground+1 2*Rbackground+1]);   

        background.ulposx=wbstruct.blobs_sorted.x(bp)-Rbackground;
        background.ulposy=wbstruct.blobs_sorted.y(bp)-Rbackground;
        background.dataedge_x1=max([1 background.ulposx]);
        background.dataedge_y1=max([1 background.ulposy]);

        background.dataedge_x2=min([xbound background.ulposx+2*Rbackground]);
        background.dataedge_y2=min([ybound background.ulposy+2*Rbackground]); 

        offsetx=-background.maskedge_x1-(2*Rbackground-background.maskedge_x2);
        offsety=-(-background.maskedge_y1-(2*Rbackground-background.maskedge_y2));

        %blit edge-cropped round mastermask with extracted edge-cropped rectangle from binarized buffer
        background.mask=background.mastermask(background.maskedge_x1:background.maskedge_x2,background.maskedge_y1:background.maskedge_y2)'   .* ...
        uint16(wbstruct.M(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2,wbstruct.blobs_sorted.z(bp))==0);

        [xCentroidMask, yCentroidMask]=centroidmask([dataedge_x2-dataedge_x1+1 , dataedge_y2-dataedge_y1+1]);

        
        centerPixelX=(dataedge_x2-dataedge_x1+1)/2+0.5;
        centerPixelY=(dataedge_y2-dataedge_y1+1)/2+0.5;

        %populate notes box
        if isfield(wbstruct,'notes')  && isfield(wbstruct.notes,'neuron') && length(wbstruct.notes.neuron)>=neuron
            notesString=wbstruct.notes.neuron{neuron};
        else
            notesString='';
        end

        %load IDs
        if isfield(wbstruct,'ID')  && size(wbstruct.ID,2)>=neuron
           
            
            if ~isempty(wbstruct.ID{neuron})
                ID1=find(ismember(neuronIDs,wbstruct.ID{neuron}{1}));
            else ID1=1;
            end

            if size(wbstruct.ID{neuron},2)>=2 && ~isempty(wbstruct.ID{neuron})
                ID2=find(ismember(neuronIDs,wbstruct.ID{neuron}{2}));    
            else ID2=1;
            end

            if size(wbstruct.ID{neuron},2)>=3 && ~isempty(wbstruct.ID{neuron})
                ID3=find(ismember(neuronIDs,wbstruct.ID{neuron}{3}));
            else ID3=1;
            end

        else
            ID1=1;
            ID2=1;
            ID3=1;
        end

    end

    function getNewFrameData

       %get new movie data and crop it 
       main.cropframe_noshift=ZMovie{parent_zplane}(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,frame);
       main.cropframe_noshift_masked=(wbstruct.mask_nooverlap{bp}').*main.cropframe_noshift;
       [vals,pixels]=sort(main.cropframe_noshift_masked(:),'descend');  %sort pixels by brightness
       %f_parents_one(frame)=mean(vals(1:numbrightestpixels));  %take the mean of the brightest pixels      

       main.cropframe_noshift_brightest=main.cropframe_noshift_masked;
       main.cropframe_noshift_brightest(pixels(numbrightestpixels+1:end))=0;

       main.cropframe_noshift_background=ZMovie{parent_zplane}(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2,frame);
       main.cropframe_noshift_background_circularstamp=main.cropframe_noshift_background.*background.mastermask(background.maskedge_x1:background.maskedge_x2,background.maskedge_y1:background.maskedge_y2)';
       main.cropframe_noshift_background_masked=main.cropframe_noshift_background.*background.mask;
       
       %compute shifted data
       main.cropframe=ZMovie{parent_zplane}(round(centroidDeltaY)+(dataedge_y1:dataedge_y2),round(centroidDeltaX)+(dataedge_x1:dataedge_x2),frame);
       main.cropframe_masked=(wbstruct.mask_nooverlap{bp}').*main.cropframe;
       [vals,pixels]=sort(main.cropframe_masked(:),'descend');  %sort pixels by brightness
       %f_parents_one(frame)=mean(vals(1:numbrightestpixels));  %take the mean of the brightest pixels      

       main.cropframe_brightest=main.cropframe_masked;
       main.cropframe_brightest(pixels(numbrightestpixels+1:end))=0;

       main.cropframe_background=ZMovie{parent_zplane}(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2,frame);
       main.cropframe_background_circularstamp=main.cropframe_background.*background.mastermask(background.maskedge_x1:background.maskedge_x2,background.maskedge_y1:background.maskedge_y2)';
       main.cropframe_background_masked=main.cropframe_background.*background.mask;

       %compute centroid of brightest pix for local tracking testing
       [deltaDeltaX,deltaDeltaY]=computeCentroidShift(main.cropframe');
       
       
%        centroidDeltaX=centroidDeltaX+(1-damping)*deltaDeltaX; %+damping*lastDeltaDeltaX;
%        centroidDeltaY=centroidDeltaY+(1-damping)*deltaDeltaY; %+damping*lastDeltaDeltaY;
%        
%        
          centroidDeltaX=max([-Rbackground/2 min([centroidDeltaX+(1-damping)*deltaDeltaX  Rbackground/2])]); 
          centroidDeltaY=max([-Rbackground/2 min([centroidDeltaY+(1-damping)*deltaDeltaY Rbackground/2])]); 

       
       lastDeltaDeltaX=deltaDeltaX;
       lastDeltaDeltaY=deltaDeltaY;
       
    end

    function drawPlots()

       getNewFrameData;  

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
       
       if enableLocalTrackingFlag
            handles.localTrackingCircleBackgroundArea=rectangle('Curvature', [1 1], 'Position',[centroidDeltaX+1+Rbackground-Rmax+offsetx centroidDeltaY+1+Rbackground-Rmax+offsety 1+2*Rmax 1+2*Rmax],'FaceColor','none','EdgeColor','g');
       end
       
       axis image;axis off;
       title('background area');

       %plot masked background region
       subtightplot(nr,nc,nc+2,gap);
       handles.cropframe_background_masked=imagesc(main.cropframe_background_masked,[clow chigh]);
       axis image;axis off;
       title('masked background');

       %plot parent plane
       cs=3;
       subtightplot(nr,nc,[2*nc+cs 3*nc+cs 4*nc+cs],gap);
       hold off;
       cropframe_full=ZMovie{wbstruct.blobs_sorted.z(bp)}(:,:,frame);
       handles.parentZimage=imagesc(cropframe_full,[clow chigh]);
       hold on;
       rectangle('Curvature',[1 1],'Position',[dataedge_x1 dataedge_y1 dataedge_x2-dataedge_x1  dataedge_y2-dataedge_y1],'EdgeColor',[1 1 0]);
       rectangle('Curvature',[1 1],'Position',[background.dataedge_x1+offsetx background.dataedge_y1+offsety 1+2*Rbackground 1+2*Rbackground],'EdgeColor',[1 0 0]);

       if enableLocalTrackingFlag
           handles.localTrackingCircle=rectangle('Curvature',[1 1],'Position',[centroidDeltaX+dataedge_x1 centroidDeltaY+dataedge_y1 dataedge_x2-dataedge_x1  dataedge_y2-dataedge_y1],'EdgeColor',[0 1 0]);
       end
       
       textur(['Z' num2str(parent_zplane)]);
       title('parent Z');
       axis image; axis off;  

       %plot flanking planes

       cs=2;
       subtightplot(nr,nc,[2*nc+cs 3*nc+cs 4*nc+cs],gap);
       hold off;
       if wbstruct.blobs_sorted.z(bp)>1
           cropframe_full=ZMovie{wbstruct.blobs_sorted.z(bp)-1}(:,:,frame);
       else
           cropframe_full=zeros(size(cropframe_full));
       end
       handles.lowerZimage=imagesc(cropframe_full,[clow chigh]);
       hold on;
       rectangle('Curvature',[1 1],'Position',[dataedge_x1 dataedge_y1 dataedge_x2-dataedge_x1  dataedge_y2-dataedge_y1],'EdgeColor',[1 1 0]);     
       rectangle('Curvature',[1 1],'Position',[background.dataedge_x1+offsetx background.dataedge_y1+offsety 1+2*Rbackground 1+2*Rbackground],'EdgeColor',[1 0 0]);
       textur(['Z' num2str(parent_zplane-1)]);
       title('Z-1');
       axis image; axis off;  

       cs=4;
       subtightplot(nr,nc,[2*nc+cs 3*nc+cs 4*nc+cs],gap);
       hold off;

       if wbstruct.blobs_sorted.z(bp)<numZ
           cropframe_full=ZMovie{wbstruct.blobs_sorted.z(bp)+1}(:,:,frame);
       else
           cropframe_full=zeros(size(cropframe_full));
       end
       handles.upperZimage=imagesc(cropframe_full,[clow chigh]);
       hold on;
       rectangle('Curvature',[1 1],'Position',[dataedge_x1 dataedge_y1 dataedge_x2-dataedge_x1  dataedge_y2-dataedge_y1],'EdgeColor',[1 1 0]);
       rectangle('Curvature',[1 1],'Position',[background.dataedge_x1+offsetx background.dataedge_y1+offsety 1+2*Rbackground 1+2*Rbackground],'EdgeColor',[1 0 0]);
       textur(['Z' num2str(parent_zplane+1)]);
       title('Z+1');
       axis image; axis off;  


       %plot mask patchwork Z
       cs=5;
       subtightplot(nr,nc,[2*nc+cs,3*nc+cs,4*nc+cs],gap);
       cla;
       imagesc(squeeze(wbstruct.M(:,:,parent_zplane)));
       hold on;
       rectangle('Curvature',[1 1],'Position',[dataedge_x1 dataedge_y1 dataedge_x2-dataedge_x1  dataedge_y2-dataedge_y1],'EdgeColor',[1 1 0]);
       rectangle('Curvature',[1 1],'Position',[background.dataedge_x1+offsetx background.dataedge_y1+offsety 1+2*Rbackground 1+2*Rbackground],'EdgeColor',[1 0 0]);
       textur(['Z' num2str(parent_zplane)]);
       title('masks');
       axis image; axis off; 


       %plot colorbar
       cs=1;
       subtightplot(nr,nc,[2*nc+cs,3*nc+cs,4*nc+cs],gap);
       axis image;
       axis off;
       colorbar;

       %plot traces from wbstruct
       handles.axtraces=subtightplot(nr,nc,3:(nc-2),gap);
       p=plot(wbstruct.tv,wbstruct.deltaFOverFNoBackSub(:,neuron),'r');
       set(p,'HitTest','off');
       hold on;
       pp=plot(wbstruct.tv,wbstruct.deltaFOverF(:,neuron),'b');
       set(pp,'HitTest','off');
       %plot(wbstruct.tv,f_parents_one/f_parents_one_mean-1,'g');
       ylim1=1.5*min(wbstruct.deltaFOverF(:,neuron));
       ylim2=1.5*max(wbstruct.deltaFOverF(:,neuron));
       ylim([ylim1 ylim2]);
       xlim([0 wbstruct.tv(end)]);
       %listen for mouseDown events in all subplots
       set(handles.axtraces, 'ButtonDownFcn',@mouseDownCallback);
       handles.redline=line([wbstruct.tv(frame) wbstruct.tv(frame)],[ylim1 ylim2],'Color','r');
       handles.frametext=textlr([num2str(frame) '/' num2str(numFrames)],0,10,[0.5 0.5 0.5]);
       legend({'\DeltaF/F_{0} no backsub','\DeltaF/F'});
       hold off;

       %plot background trace and plot overall mean trace
        subtightplot(nr,nc,nc+(3:(nc-2)),gap);
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
                set(handles.excludeButton,'BackgroundColor','r');
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
        
       palettePopupMenuCallback;


       drawnow;

    end

    function updatePlots()
    
       getNewFrameData;

       set(handles.cropframe_brightest_image,'CData',main.cropframe_brightest); 
       set(handles.cropframe_masked_image,'CData',main.cropframe_masked)  
       
       set(handles.cropframe_background_circularstamp,'CData',main.cropframe_background_circularstamp);
       set(handles.cropframe_background_masked,'CData',main.cropframe_background_masked);

       set(handles.centroid_ex1,'XData',centerPixelX+centroidDeltaX);
       set(handles.centroid_ex1,'YData',centerPixelY+centroidDeltaY);

       %update parent Z movie frame
       cropframe_full=ZMovie{wbstruct.blobs_sorted.z(bp)}(:,:,frame);
       set(handles.parentZimage,'CData',cropframe_full);
       set(get(handles.parentZimage,'Parent'),'CLim',[clow chigh]);

       if enableLocalTrackingFlag
        set(handles.localTrackingCircle,'Position',[centroidDeltaX+dataedge_x1 centroidDeltaY+dataedge_y1 dataedge_x2-dataedge_x1  dataedge_y2-dataedge_y1]);
        set(handles.localTrackingCircleBackgroundArea,'Position',[centroidDeltaX+1+Rbackground-Rmax+offsetx centroidDeltaY+1+Rbackground-Rmax+offsety 1+2*Rmax 1+2*Rmax]);

       end
       
       
       %update left flanking Z movie frame
       if wbstruct.blobs_sorted.z(bp)>1
           cropframe_full=ZMovie{wbstruct.blobs_sorted.z(bp)-1}(:,:,frame);
       else
           cropframe_full=zeros(size(cropframe_full));
       end
       set(handles.lowerZimage,'CData',cropframe_full);
       set(get(handles.lowerZimage,'Parent'),'CLim',[clow chigh]);


       %update right flanking Z movie frame
       if wbstruct.blobs_sorted.z(bp)<wbstruct.numZ

           cropframe_full=ZMovie{wbstruct.blobs_sorted.z(bp)+1}(:,:,frame);
       else
           cropframe_full=zeros(size(cropframe_full));
       end
       set(handles.upperZimage,'CData',cropframe_full);
       set(get(handles.upperZimage,'Parent'),'CLim',[clow chigh]);


       %trace plot updates
       set(handles.redline,'XData',[wbstruct.tv(frame) wbstruct.tv(frame)]);
       set(handles.frametext,'String',[num2str(frame) '/' num2str(numFrames)]);

       drawnow;

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
        
    end

    function nIDs=loadNeuronIDs()
    
    nIDs={'---',...
    'ADAL','ADAR',...
    'ADEL','ADER',...
    'ADFL','ADFR',...
    'ADLL','ADLR',...
    'AFDL','AFDR',...
    'AIAL','AIAR',...
    'AIBL','AIBR',...
    'AIML','AIMR',...
    'AINL','AINR',...
    'AIYL','AIYR',...
    'AIZL','AIZR',...
    'ALA','ALA',...
    'ALML','ALMR',...
    'ALNL','ALNR',...
    'AQR',...
    'AS01',...
    'AS02',...
    'AS03',...
    'AS04',...
    'AS05',...
    'AS06',...
    'AS07',...
    'AS08',...
    'AS09',...
    'AS10',...
    'AS11',...
    'ASEL','ASER',...
    'ASGL','ASGR',...
    'ASHL','ASHR',...
    'ASIL','ASIR',...
    'ASJL','ASJR',...
    'ASKL','ASKR',...
    'AUAL','AUAR',...
    'AVAL','AVAR',...
    'AVBL','AVBR',...
    'AVDL','AVDR',...
    'AVEL','AVER',...
    'AVFL','AVFR',...
    'AVG',...
    'AVHL','AVHR',...
    'AVJL','AVJR',...
    'AVKL','AVKR',...
    'AVL',...
    'AVM',...
    'AWAL','AWAR',...
    'AWBL','AWBR',...
    'AWCL','AWCR',...
    'BAGL','BAGR',...
    'BDUL','BDUR',...
    'CANL','CANR',...
    'CEPDL','CEPDR',...
    'CEPVL','CEPVR',...
    'DA01',...
    'DA02',...
    'DA03',...
    'DA04',...
    'DA05',...
    'DA06',...
    'DA07',...
    'DA08',...
    'DA09',...
    'DB01',...
    'DB02',...
    'DB03',...
    'DB04',...
    'DB05',...
    'DB06',...
    'DB07',...
    'DD01',...
    'DD02',...
    'DD03',...
    'DD04',...
    'DD05',...
    'DD06',...
    'DVA',...
    'DVB',...
    'DVC',...
    'FLPL','FLPR',...
    'HSNL','HSNR',...
    'IL1DL','IL1DR',...
    'IL1L','IL1R',...
    'IL1VL','IL1VR',...
    'IL2DL','IL1DR',...
    'IL2L','IL2R',...
    'IL2VL','IL2VR',...
    'LUAL','LUAR',...
    'OLLL','OLLR',...
    'OLQDL','OLQDR',...
    'OLQVL','OLQVR',...
    'PDA',...
    'PDB',...
    'PDEL','PDER',...
    'PHAL','PHAR',...
    'PHBL','PHBR',...
    'PHCL','PHCR',...
    'PLML','PLMR',...
    'PLNL','PLNR',...
    'PQR',...
    'PVCL','PVCR',...
    'PVDL','PVDR',...
    'PVM',...
    'PVNL','PVNR',...
    'PVPL','PVPR',...
    'PVQL','PVQR',...
    'PVR',...
    'PVT',...
    'PVWL','PVWR',...
    'RIAL','RIAR',...
    'RIBL','RIBR',...
    'RICL','RICR',...
    'RID',...
    'RIFL','RIFR',...
    'RIGL','RIGR'...
    'RIH',...
    'RIML','RIMR',...
    'RIPL','RIPR',...
    'RIR',...
    'RIS',...
    'RIVL','RIVR',...
    'RMDDL','RMDDR',...
    'RMDL','RMDR',...
    'RMDVL','RMDVR',...
    'RMED',...
    'RMEL','RMER',...
    'RMEV',...
    'RMFL','RMFR',...
    'RMGL','RMGR',...
    'RMHL','RMHR',...
    'SAADL','SAADR',...
    'SAAVL','SAAVR',...
    'SABD',...
    'SABVL','SABVR'...
    'SDQL','SDQR',...
    'SIADL','SIADR'....
    'SIAVL','SIAVR',...
    'SIBDL','SIBDR',...
    'SIBVL','SIBVR',...
    'SMBDL','SMBDR',...
    'SMBVL','SMBVR',...
    'SMDDL','SMDDR',...
    'SMDVL','SMDVR',...
    'URADL','URADR',...
    'URAVL','URAVR',...
    'URBL','URBR',...
    'URXL','URXR',...
    'URYDL','URYDR',...
    'URYVL','URYVR',...
    'VA01',...
    'VA02',...
    'VA03',...
    'VA04',...
    'VA05',...
    'VA06',...
    'VA07',...
    'VA08',...
    'VA09',...
    'VA10',...
    'VA11',...
    'VA12',...
    'VB01',...
    'VB02',...
    'VB03',...
    'VB04',...
    'VB05',...
    'VB06',...
    'VB07',...
    'VB08',...
    'VB09',...
    'VB10',...
    'VB11',...
    'VC01',...
    'VC02',...
    'VC03',...
    'VC04',...
    'VC05',...
    'VC06',...
    'VD01',...
    'VD02',...
    'VD03',...
    'VD04',...
    'VD05',...
    'VD06',...
    'VD07',...
    'VD08',...
    'VD09',...
    'VD10',...
    'VD11',...
    'VD12',...
    'VD13',...
    'I1L','I1R'...
    'I2L','I2R'...
    'I3',...
    'I4',...
    'I5',...
    'I6',...
    'M1',...
    'M2L','M2R',...
    'M3L','M3R',...
    'M4',...
    'M5',...
    'MI',...
    'MCL','MCR',...
    'NSML','NSMR',...
    };
    
    
    end

    function [deltaX,deltaY]=computeCentroidShift(imageData)
        
        fullArea=sum(imageData(:));
                
        deltaX=-sum(sum(double(imageData).*xCentroidMask))/fullArea;
        
        deltaY=-sum(sum(double(imageData).*yCentroidMask))/fullArea;
        
        
    end

%% CALLBACKS

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
         wbstruct.ID{neuron}{1}=neuronIDs{ID1};
         save(wbstructfile,'wbstruct');    
    end

    function neuronID2PopupMenuCallback

         ID2=get(gcbo,'Value');
         wbstruct.ID{neuron}{2}=neuronIDs{ID2};
         save(wbstructfile,'wbstruct');    
    end

    function neuronID3PopupMenuCallback

         ID3=get(gcbo,'Value');
         wbstruct.ID{neuron}{3}=neuronIDs{ID3};
         save(wbstructfile,'wbstruct');    
    end

    function mouseDownCallback(hObject,~)

        %get(hObject)
        pos=get(hObject,'CurrentPoint'); %pos is 2x3??
        %disp(['You clicked X:',num2str(pos(1,1))]); 
        frame=round((pos(1,1))/wbstruct.tv(2));
        updatePlots;
    end

    function notesBoxImmediateCallback

        set(handles.notesBoxSaveLabel,'BackgroundColor','r');
        set(handles.notesBoxSaveLabel,'String','UNSAVED.');

    end

    function notesBoxCallback

        str=get(gcbo,'String');
        wbstruct.notes.neuron{neuron}=str;
        save(wbstructfile,'wbstruct');

        set(handles.notesBoxSaveLabel,'BackgroundColor','g');
        set(handles.notesBoxSaveLabel,'String','SAVED.');

    end

    function excludeButtonCallback

        if strcmp(get(gcbo,'String'),'exclude')
            if isfield(wbstruct,'exclusionList')
                wbstruct.exclusionList=[wbstruct.exclusionList(1:find(wbstruct.exclusionList<neuron,1,'last')) neuron wbstruct.exclusionList(1+find(wbstruct.exclusionList<neuron,1,'last'):end)]; %ninja insert code
            else
                wbstruct.exclusionList=neuron;
            end

            set(handles.excludeButton,'String','EXCLUDED.');
            set(handles.excludeButton,'BackgroundColor','r');

            save(wbstructfile,'wbstruct');

            %'FontWeight'
        else %unexclude
            set(handles.excludeButton,'String','exclude');
            set(handles.excludeButton,'BackgroundColor','default');
            wbstruct.exclusionList(wbstruct.exclusionList==neuron)=[];

            save(wbstructfile,'wbstruct');

        end

        currentFigure=gcf;
        wbgridplotOptions.useExistingFigureHandle=passedHandles.fig;
        wbgridplotOptions.saveFlag=0;
        wbgridplotOptions.wbcheckHandle=currentFigure;
        wbgridplot(wbstruct,wbgridplotOptions);
        set(0,'CurrentFigure',currentFigure);

    end

    function playButtonCallback()

        while get(gcbo,'Value')==1
            if frame<numFrames
                frame=frame+1;
            else
                frame=1;
            end
            updatePlots;
        end
    end

    function nextButtonCallback()
        if neuron<numN
            neuron=neuron+1;
        else
            neuron=1;
        end
        set(handles.neuronPopupMenu,'Value',neuron);
        getNewNeuronData;
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
        drawPlots;
        updatePlots;     
    end

    function neuronPopupMenuCallback()
        neuron=get(gcbo,'Value');
        getNewNeuronData;
        drawPlots;
        updatePlots;

    end

    function enableLocalTrackingCallBack
        enableLocalTrackingFlag=get(gcbo,'Value');
    end

end %main