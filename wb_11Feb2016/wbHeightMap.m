function wbHeightMap(dataFolder,zPlane)

paletteNames={'jet','hot','gray','autumn','summer'};
clow=500;
chigh=10000;
threshold=1000;
rMin=5;

if nargin<2
    zPlane=1;
end

if nargin<1
    dataFolder=pwd;
end


%load wb stuff
wbCheckForDataFolder;

metadata=load([dataFolder '/meta.mat']);
wbstruct=wbload(dataFolder);
[TMIPMovie,numZ,numTW,validZs]=wbloadTMIPs(dataFolder,metadata);
TMIPh=size(TMIPMovie{1},1);
TMIPw=size(TMIPMovie{1},2);

ZPlaneLabels=1:numZ;
tWinLabels=1:numTW;


%find blobs

tWin=1;
filterWidth=3;  %should be odd
med_filt_width=2;

prefiltered_image=zeros(size(squeeze(TMIPMovie{zPlane}(:,:,tWin))));

tblobs=FindBlobs(threshold,rMin,zPlane,tWin);



setupPlots;
drawPlots;

    
%% GUI

%%MOVIE NAVIGATION
off1=.2;
lf=.03;

annotation('textbox',[0.64-off1 0.96+lf/2 0.11 0.02],'String','Z Plane','EdgeColor','none');
handles.nextZButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.75-off1 0.96 0.02 0.02],'String','+1','Callback',@(s,e) ZupButtonCallback);
handles.prevZButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.62-off1 0.96 0.02 0.02],'String','-1','Callback',@(s,e) ZdownButtonCallback);
handles.ZPopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',zPlane,'String',ZPlaneLabels,'Position',[0.64-off1 0.94 0.11 0.04],'Callback',@(s,e) ZPopupMenuCallback);

annotation('textbox',[0.64-off1 0.96-lf/2 0.11 0.02],'String','Time Window','EdgeColor','none');
handles.nextTButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.75-off1 0.96-lf 0.02 0.02],'String','+1','Callback',@(s,e) TupButtonCallback);
handles.prevTButton = uicontrol('Style','pushbutton','Units','normalized','Position',[0.62-off1 0.96-lf 0.02 0.02],'String','-1','Callback',@(s,e) TdownButtonCallback);
handles.TPopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',tWin,'String',tWinLabels,'Position',[0.64-off1 0.94-lf 0.11 0.04],'Callback',@(s,e) TPopupMenuCallback);


%%ALGO
tb=.03;

annotation('textbox',[0.22 0.96 0.11 0.02],'String','Thresh','EdgeColor','none');
handles.threshBox=uicontrol('Style','edit','Units','normalized','Position',[0.22+tb 0.96 0.05 0.02],'String',threshold,'HorizontalAlignment','right','ForegroundColor','k','Callback',@(s,e) editThreshold);
annotation('textbox',[0.22 0.96-lf 0.11 0.02],'String','Rmin','EdgeColor','none');
handles.rMinBox=uicontrol('Style','edit','Units','normalized','Position',[0.22+tb 0.96-lf 0.05 0.02],'String',rMin,'HorizontalAlignment','right','ForegroundColor','k','Callback',@(s,e) editRmin);
annotation('textbox',[0.22 0.96-lf*2 0.11 0.02],'String','Filter width','EdgeColor','none');
handles.filterWidthBox=uicontrol('Style','edit','Units','normalized','Position',[0.22+tb 0.96-2*lf 0.05 0.02],'String',filterWidth,'HorizontalAlignment','right','ForegroundColor','k','Callback',@(s,e) editFilterWidth);


%%PALETTE
ypos=.1;
off2=.14;

handles.imageMaxLevelSlider = uicontrol('Style','slider','Units','normalized','Position',[.2-off2 ypos+.02 .10 .05],'String','levels','Min',0.1,'Max',100,'SliderStep',[.01 .1],'Value',80); %,'Callback',@(s,e) disp('mouseup')
handles.imageMinLevelSlider = uicontrol('Style','slider','Units','normalized','Position',[.2-off2 ypos .10 .05],'String','minlevel','Min',0.1,'Max',100,'SliderStep',[.01 .1],'Value',30); %,'Callback',@(s,e) disp('mouseup')

adj=.03;
annotation('textbox',[0.15-off2 ypos+.01+adj 0.06 0.02],'String','cutoffs','EdgeColor','none');
annotation('textbox',[0.185-off2 ypos+.02+adj 0.03 0.02],'String','hi','EdgeColor','none');
annotation('textbox',[0.185-off2 ypos+adj 0.03 0.02],'String','lo','EdgeColor','none');
annotation('textbox',[0.165-off2 ypos-.02+adj 0.04 0.02],'String','palette','EdgeColor','none');
handles.palettePopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',1,'String',paletteNames,'Position',[.2-off2 ypos-.02 .075 .05],'Callback',@(s,e) palettePopupMenuCallback);

hListener = addlistener(handles.imageMaxLevelSlider,'Value','PostSet',@(s,e) imageMaxLevelSliderCallback) ;
hListener = addlistener(handles.imageMinLevelSlider,'Value','PostSet',@(s,e) imageMinLevelSliderCallback) ;



%% GUI CALLBACKS

    %%MOVIE NAV
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

    function TupButtonCallback()
        if tWin<numTW
            tWin=tWin+1;
        else
            tWin=1;
        end
        set(handles.TPopupMenu,'Value',tWin);
        drawPlots;  
    end

    function TdownButtonCallback()
        if tWin>1
            tWin=tWin-1;
        else
            tWin=numTW;
        end
        set(handles.TPopupMenu,'Value',tWin);
        drawPlots;    
    end

    function TPopupMenuCallback()
        tWin=get(gcbo,'Value');
        drawPlots;

    end


    %%ALGO
    function editThreshold()
        threshold=str2num(get(gcbo,'String'))
        class(threshold)
        drawPlots;
    end

    function editRmin()
        rMin=str2num(get(gcbo,'String'))
        drawPlots;
    end

    function editFilterWidth()
        filterWidth=str2num(get(gcbo,'String'))
        drawPlots;
    end

    %%PALETTE
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


%%


%nested functions

    function updateData
        disp('processing..');
        tblobs=FindBlobs(threshold,rMin,zPlane,tWin);
        disp('completed.');
    end

    function tblobs=FindBlobs(thresholdMargin,thisRmin,validZs,TWlist)
        
        %blob finding
        
        if filterWidth==0
            filt=1;
        else
        
            filt_unshifted=MexiHat2D(21,filterWidth);  %hi-pass filter
            filt=filt_unshifted-sum(filt_unshifted(:))/(size(filt_unshifted,1))^2;
        
        end

        for z=validZs

            for tw=TWlist

                frame=squeeze(TMIPMovie{z}(:,:,tw));
                thisThreshold=median(frame(:))+thresholdMargin;

                [federatedcenters,~,~,~,prefiltered_image]=FastPeakFindSK(frame,thisThreshold,filt,thisRmin-1,5,med_filt_width);

                if ~isempty(federatedcenters)
                    xi=federatedcenters.y';
                    yi=federatedcenters.x';
                else
                    xi=[];
                    yi=[];
                end

                tblobs(z,tw).x=xi;  
                tblobs(z,tw).y=yi;
                tblobs(z,tw).Tx=xi+(tw-1)*size(TMIPMovie{z},2);
                tblobs(z,tw).Ty=yi;

                tblobs(z,tw).n=length(tblobs(z,tw).x);

            end

        end

    end

    function setupPlots
        %setup figure
        figure('Position',[200 200 1200 1600]);
        nc=6;
        axis.left3Dplot=subplot(1,nc,1:3);
        set(axis.left3Dplot,'View',[156 34]);
    end

    function drawPlots
        
        updateData;
        nc=6;
        %3D plot
        axis.left3Dplot=subplot(1,nc,1:3);
        hold off;
        rotate3d on;

%        wbstruct.tblobs(1,1)

        [X,Y] = meshgrid(1:TMIPw,1:TMIPh);
        img=double(prefiltered_image(:,end:-1:1));

        currentView=get(gca,'View')
        surf(X,Y,img);
        view(currentView);
        set(gca,'DataAspectRatio',[1 1 100]);
        hold on;

        for i=1:tblobs(zPlane,tWin).n

            exZ=img( tblobs(zPlane,tWin).y(i),TMIPw-tblobs(zPlane,tWin).x(i)+1 );
            ex3d(TMIPw-tblobs(zPlane,tWin).x(i)+1,tblobs(zPlane,tWin).y(i),  1.01*exZ );
        end


        %2D plot


        
        subplot(1,nc,nc-1);
        hold off;
        
        handles.imageLeftSide=imagesc(squeeze(double(TMIPMovie{zPlane}(:,:,tWin))),[clow chigh]);
        hold on;

        for i=1:tblobs(zPlane,tWin).n

            exZ=img( tblobs(zPlane,tWin).y(i),TMIPw-tblobs(zPlane,tWin).x(i)+1 );
            ex(tblobs(zPlane,tWin).x(i),tblobs(zPlane,tWin).y(i) );
        end

        subplot(1,nc,nc);
        hold off;
        
        
        
        handles.imageRightSide=imagesc(prefiltered_image);
        hold on;

        for i=1:tblobs(zPlane,tWin).n

            exZ=img( tblobs(zPlane,tWin).y(i),TMIPw-tblobs(zPlane,tWin).x(i)+1 );
            ex(tblobs(zPlane,tWin).x(i),tblobs(zPlane,tWin).y(i) );
        end
        
    end

    function updateColorPalettes
        
        palettePopupMenuCallback;
        set(get(handles.imageLeftSide,'Parent'),'CLim',[clow chigh]);
        set(get(handles.imageRightSide,'Parent'),'CLim',[clow chigh]);
      
    end

end %wbHeightMap
