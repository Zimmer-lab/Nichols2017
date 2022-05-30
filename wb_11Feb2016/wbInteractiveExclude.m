function thisHandle=wbInteractiveExclude(wbstruct,wbstructFileName,originatingFigureHandles)

if nargin<1
    [wbstruct, wbstructFileName]=wbload([],false);
end

if nargin<3
    originatingFigureHandles=[];
end

handles=[];

paletteNames={'gray','jet','hot','autumn','summer'};


%globals
clickDistance=12;
montageX=[];
montageY=[];
fullMask=[]; 
buttonStartingBackgroundColor=[];
simpleNeuronLookup=[];

clow=500;
chigh=20000;

blobThreads=wbstruct.blobThreads;
blobThreads_sorted=wbstruct.blobThreads_sorted;

wbloadTMIPs;
TMIPMovie=evalin('base','TMIPMovie');

neuronlookup=wbstruct.neuronlookup;
selectedNeuronTag=false(wbstruct.nn,1);

%make simpleNeuron lookup
MakeSimpleNumberLookupTable;

height=size(TMIPMovie{1},1);
width=size(TMIPMovie{1},2);
numZ=length(TMIPMovie);
nn=length(blobThreads.parentlist);
numTW=size(wbstruct.tblobs,2);

currentTW=1;
textLabelsToggle=true;
simpleNumbersToggle=false;
thisHandle=figure('Position',[0 0 width*numZ 1.1111*height],'Name','InteractiveExcluder','MenuBar','none');
set(thisHandle,'KeyPressFcn', @(s,e) KeyPressedFcn);

DrawTWs(currentTW);
DrawStuff(currentTW);
DrawGUI;
UpdateGUI;

%start in Lasso mode
pointerState='';
% RunLassoTool;

%% subfunctions
    
    function KeyPressedFcn

        keyStroke=get(gcbo, 'CurrentKey');
        get(gcbo, 'CurrentCharacter');
        get(gcbo, 'CurrentModifier');

        if strcmp(keyStroke,'leftarrow')
            if (currentTW==1) 
                currentTW=numZ;
            else
                currentTW=currentTW-1;
            end

            DrawTWs(currentTW);
            DrawStuff(currentTW);


        elseif strcmp(keyStroke,'rightarrow')
            if currentTW==numZ
                currentTW=1;l
            else            
                currentTW=currentTW+1;
            end

            DrawTWs(currentTW);
            DrawStuff(currentTW);


        elseif strcmp(keyStroke,'l')
            RunLassoTool;
            
        elseif strcmp(keyStroke,'p')
            PickButtonCallback;
            
        elseif strcmp(keyStroke,'t')
            TextLabelToggleCallback;
            
        elseif strcmp(keyStroke,'s')
            SimpleNumbersToggleCallback;
            
        elseif strcmp(keyStroke,'space')
            ClearSelectionButtonCallback;
            
        elseif strcmp(keyStroke,'backspace')
            ExcludeButtonCallback;
            
        elseif strcmp(keyStroke,'equal')
            IncludeButtonCallback;
            
        elseif strcmp(keyStroke,'g')
            BackToGridPlotCallback;         

        elseif strcmp(keyStroke,'escape')
            pointerState='normal';
            set(thisHandle, 'Pointer', 'arrow');
        end


    end

    function DrawGUI
        %scrollbar
        handles.hSlider = uicontrol('Style','slider','Position',[20 0 width*numZ-40 25],'SliderStep',[1/(numTW+1) 1/(numTW+1)],'Value',1/(numTW+1)); %,'Callback',@(s,e) disp('mouseup')
        hListener = addlistener(handles.hSlider,'Value','PostSet',@(s,e) contSliderCallback) ;

        %lasso
        handles.lassoButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.05 .955 .05 .045],'String','[L]asso','Callback',@(s,e) RunLassoTool);
        
        %pick
        handles.pickButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.1 .955 .05 .045],'String','[P]ick','Callback',@(s,e) PickButtonCallback);

        %save excludes
        handles.excludeButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.25 .955 .05 .045],'String','[del] Exclude','Callback',@(s,e) ExcludeButtonCallback);
        
        %save includes
        handles.includeButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.3 .955 .05 .045],'String','[=] Include','Callback',@(s,e) IncludeButtonCallback);
         
        %clear selection
        handles.clearSelectionButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.15 .955 .05 .045],'String','[spc] Clear','Callback',@(s,e) ClearSelectionButtonCallback);      
        
        %text toggle
        handles.textLabelsButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.8 .955 .075 .045],'String','[T]oggle Labels','Callback',@(s,e) TextLabelToggleCallback);
               
        %simple numbering toggle
        handles.simpleNumbersButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.725 .955 .075 .045],'String','[S]imple Numbering','Callback',@(s,e) SimpleNumbersToggleCallback);
               
        
        %back to GridPlot
        handles.backToGridPlotButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.9 .955 .075 .045],'String','[G]ridPlot','Callback',@(s,e) BackToGridPlotCallback);
               
        buttonStartingBackgroundColor=get(handles.simpleNumbersButton,'BackgroundColor');
        
                
        %palette/brightness
        off2=.14;
        handles.imageMaxLevelSlider = uicontrol('Style','slider','Units','normalized','Position',[.2-off2 .84+.05 .10 .05],'String','levels','Min',0.1,'Max',100,'SliderStep',[.01 .1],'Value',80); %,'Callback',@(s,e) disp('mouseup')
        handles.imageMinLevelSlider = uicontrol('Style','slider','Units','normalized','Position',[.2-off2 .80+.05  .10 .05],'String','minlevel','Min',0.1,'Max',100,'SliderStep',[.01 .1],'Value',30); %,'Callback',@(s,e) disp('mouseup')

        adj=.03;
        annotation('textbox',[0.15-off2 0.81+adj+.05  0.06 0.02],'String','cutoffs','EdgeColor','none','Color','g');
        annotation('textbox',[0.185-off2 0.84+adj+.05  0.03 0.02],'String','hi','EdgeColor','none','Color','g');
        annotation('textbox',[0.185-off2 0.80+adj+.05  0.03 0.02],'String','lo','EdgeColor','none','Color','g');
        annotation('textbox',[0.165-off2 0.76+adj+.05  0.04 0.02],'String','palette','EdgeColor','none','Color','g');
        handles.palettePopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',1,'String',paletteNames,'Position',[.2-off2 .76+.05  .075 .05],'Callback',@(s,e) palettePopupMenuCallback);

        hListener = addlistener(handles.imageMaxLevelSlider,'Value','PostSet',@(s,e) imageMaxLevelSliderCallback) ;
        hListener = addlistener(handles.imageMinLevelSlider,'Value','PostSet',@(s,e) imageMinLevelSliderCallback) ;
        
    end

    function updateColorPalettes
        
        palettePopupMenuCallback;
        set(get(handles.TMIPimage(1),'Parent'),'CLim',[clow chigh]);
  
        
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
   
    function ClearSelectionButtonCallback
        
        selectedNeuronTag=false(wbstruct.nn,1);
        DrawTWs(currentTW);
        DrawStuff(currentTW);
        
        
    end

    function IncludeButtonCallback
        disp('include');
        
        if isfield(wbstruct,'exclusionList') && ~isempty(wbstruct.exclusionList)

            currentExclusionTag=false(size(selectedNeuronTag));
            currentExclusionTag(wbstruct.exclusionList)=true;
            currentExclusionTag(selectedNeuronTag)=false;
            wbstruct.exclusionList=find(currentExclusionTag)';
        
        end
        
        if exist('wbstructFileName','var')
            exclusionList=wbstruct.exclusionList;
            save(wbstructFileName,'exclusionList','-append');
            wbMakeSimpleStruct(wbstructFileName);
            MakeSimpleNumberLookupTable;
            disp('wbInteractiveExclude> exclusions saved to wbstruct.mat');
        else
            disp('wbInteractiveExclude> do not have the wbstructFileName, so cannot save.');
        end
        
        UpdateOriginatingGridPlot;
        
        ClearSelectionButtonCallback;
    end

    function ExcludeButtonCallback

        selectedNeurons=(find(selectedNeuronTag))';
        
        if isfield(wbstruct,'exclusionList') && ~isempty(wbstruct.exclusionList)
              
                wbstruct.exclusionList=[wbstruct.exclusionList selectedNeurons];
                wbstruct.exclusionList=unique(wbstruct.exclusionList); %sort and de-dup built-in function
                
        else
             disp('did not find exclusionList.  creating one.');
             wbstruct.exclusionList=selectedNeurons;
        end     
        
%         traceExclusionTag_unsorted=zeros(1,nn);
%         traceExclusionTag_unsorted(wbstruct{1}.exclusionList)=1;
%         traceExclusionTag_unsorted(options.extraExclusionList)=1;
%         traceLabels=traceLabels_unsorted( sortOrder{1}  );
%         traceExclusionTag=traceExclusionTag_unsorted(sortOrder{1});
        
        if exist('wbstructFileName','var')
            exclusionList=wbstruct.exclusionList;
            save(wbstructFileName,'exclusionList','-append');
            wbMakeSimpleStruct(wbstructFileName);
            MakeSimpleNumberLookupTable;
            disp('wbInteractiveExclude> exclusions saved to wbstruct.mat');
        else
            disp('wbInteractiveExclude> do not have the wbstructFileName, so cannot save.');
        end
        
        
        UpdateOriginatingGridPlot;
        
        
        ClearSelectionButtonCallback;
        
    end

    function UpdateOriginatingGridPlot
        
        %update the wbgridplot figure that originated this wbcheck instance
        currentFigure=gcf;
        if isstruct(originatingFigureHandles)
            wbgridplotOptions.useExistingFigureHandle=0;
            wbgridplotOptions.useExistingFigureHandle=originatingFigureHandles.fig;
            wbgridplotOptions.saveFlag=0;
            wbgridplotOptions.wbstructFileName=wbstructFileName;
            wbGridPlot(wbstruct,wbgridplotOptions);
            drawnow;
            set(0,'CurrentFigure',currentFigure);
        end
        
        
    end

    function PickButtonCallback

          pointerState='pick';
%         if strcmp(pointerState,'pick')
%             pointerState='normal';
%             set(thisHandle, 'Pointer', 'arrow');
%             set(handles.pickButton,'BackgroundColor','default');
%         else
            set(handles.lassoButton,'BackgroundColor','default');
            set(handles.pickButton,'BackgroundColor','g');
%             set(thisHandle, 'Pointer', 'fullcrosshair');
            %moveptr(handle(gca),'init');  %Hack to redraw mouse pointer
            %moveptr(handle(gca),'move',0,0);
            
            %set(handles.pickButton,'BackgroundColor','default');
%         end
    end

    function BackToGridPlotCallback
        
        if isempty(originatingFigureHandles)
            disp('launching wbGridPlot.');
            wbGridPlot;
        else
            disp('going back to wbGridPlot.');
            %need to refresh wbGridPlot first!
            figure(originatingFigureHandles.fig);
        end
    end

    function SimpleNumbersToggleCallback
        
        blinkColor={buttonStartingBackgroundColor,'g'};
        simpleNumbersToggle=~simpleNumbersToggle;
        
        set(handles.simpleNumbersButton,'BackgroundColor',blinkColor{1+simpleNumbersToggle});  %ninja blinker code
        DrawTWs(currentTW);
        DrawStuff(currentTW);
             
    end

    function TextLabelToggleCallback
        textLabelsToggle=~textLabelsToggle;
        DrawTWs(currentTW);
        DrawStuff(currentTW);
    end

    function RunLassoTool
        if ~strcmp(pointerState,'lasso')   
            pointerState='lasso';
            set(handles.pickButton,'BackgroundColor','default');
            set(handles.lassoButton,'BackgroundColor','g');
            DoLasso;
        end
        
    end

    function DoLasso

        handles.freehandROI=imfreehand;

        %update selection set
        if ~isempty(handles.freehandROI)
            fullMask=createMask(handles.freehandROI,handles.imageROI);
            excludeNeuronsUsingMontageMask(fullMask);
        end

        DrawTWs(currentTW);
        DrawStuff(currentTW);

        %exit lasso state
             set(handles.lassoButton,'BackgroundColor','default');
        

             PickButtonCallback;
%             
%         if strcmp(pointerState,'lasso')
%              DoLasso;
%         end

    end

    function MouseDown

        %get(hObject)
        pos=get(get(gcbo,'Parent'),'CurrentPoint'); %pos is 2x3??
    %    disp(['You clicked X:',num2str(pos(1,1))]); 
        %frame=round((pos(1,1))/wbstruct.tv(2));
        rectangle('Position',[pos(1,1)-4 pos(1,2)-6 8 8],'EdgeColor','r');
        
        pointerXPos=pos(1,1);
        pointerYPos=pos(1,2)-2;
        
        for n=1:wbstruct.nn
            if (montageY(n)-pointerYPos)^2 + (montageX(n)-pointerXPos)^2 <= clickDistance
                selectedNeuronTag(n)=1;
            end
        end
        
        DrawTWs(currentTW);
        DrawStuff(currentTW);
        
    end

    function excludeNeuronsUsingMontageMask(bw)
          
        for n=1:wbstruct.nn
            if bw(montageY(n),montageX(n))
                selectedNeuronTag(n)=1;
            end
        end
        
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

    function [montageX,montageY]=ComputeMontageCoordinates(tw)
        montageX=zeros(wbstruct.nn,1);
        montageY=zeros(wbstruct.nn,1);
        for n=1:wbstruct.nn 
            z=wbstruct.nz(n);
            thisXOffset=(z-1)*width;

%             montageX(n)=max([min([thisXOffset+blobThreads_sorted.x(tw,blobThreads.parentlist(neuronlookup(n))); numTW*width]) 1]);
%             montageY(n)=max([min([blobThreads_sorted.y(tw,blobThreads.parentlist(neuronlookup(n))) height]) 1]);

              montageX(n)=max([min([thisXOffset+wbstruct.nx(tw,n); numZ*width]) 1]);
              montageY(n)=max([min([wbstruct.ny(tw,n) height]) 1]);

        end
        
    end

    function DrawTWs(tw)
        hold off;
        
        
        %make invisible image for ROI mask and Picking
        handles.imageROI=imagesc(zeros(numZ*width,height)');
        set(handles.imageROI,'Visible','on');
        hold on;
        
        for z=1:numZ
            
            %plot TMIP movie Z
            xbounds=(z-1)*width + [0 width];
            ybounds=[0 height];
            handles.TMIPimage(z)=imagesc(xbounds,ybounds,squeeze(TMIPMovie{z}(:,:,tw)),[clow chigh]);
            
            set(handles.TMIPimage(z),'HitTest','off');
            hold on; 
            
        end
        xlim([0 width*numZ]);
        colormap(gray);
        axis tight;
        axis off;
        set(gca,'LooseInset',get(gca,'TightInset'))   
        set(gca,'position',[0 0.05 1 .90],'units','normalized');
        handles.twtext=title(['TW' num2str(currentTW)],'FontSize',14,'FontWeight','bold');
        

%       set(handles.imageROI,'ButtonDownFcn',@MouseDown);
       

    end

    function DrawLegend
        
        anc=[.93*numZ*width,.02*height];lf=.02*height;tb=.02*numZ*width;
        line([anc(1) anc(1)+.9*tb],[anc(2) anc(2)],'Color','g');
        line([anc(1) anc(1)+.9*tb],[anc(2)+lf anc(2)+lf],'Color','r');
        line([anc(1) anc(1)+.9*tb],[anc(2)+2*lf anc(2)+2*lf],'Color','b');
        line([anc(1) anc(1)+.9*tb],[anc(2)+3*lf anc(2)+3*lf],'Color','c');

        text(anc(1)+tb,anc(2),'good','Color','g');
        text(anc(1)+tb,anc(2)+lf,'excluded','Color','r');
        text(anc(1)+tb,anc(2)+2*lf,'selected','Color','b');
        text(anc(1)+tb,anc(2)+3*lf,'replaced','Color','c');
        
    end

    function DrawStuff(tw)
        
            [montageX,montageY]=ComputeMontageCoordinates(tw);
         
            goodColor='g';
            excludedColor='r';
            toBeExcludedColor='b';
            replacedColor='c';
            %plot neurons
  
            plot(montageX,montageY,'LineStyle','none','Marker','+','Color',goodColor);
            plot(montageX(wbstruct.exclusionList),montageY(wbstruct.exclusionList),'LineStyle','none','Marker','+','Color',excludedColor);
            plot(montageX(selectedNeuronTag),montageY(selectedNeuronTag),'LineStyle','none','Marker','+','Color',toBeExcludedColor);
            if isfield(wbstruct,'replacements')
                plot(montageX(wbstruct.replacements.neuron),montageY(wbstruct.replacements.neuron),'LineStyle','none','Marker','+','Color',replacedColor);
            end
            
            for n=1:wbstruct.nn
             
                    if selectedNeuronTag(n)
                        thisColor=toBeExcludedColor;
                    elseif ismember(n,wbstruct.exclusionList)
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
                        neuronLabel=num2str(n);
                    end
                     

                    if textLabelsToggle
                        
                        %numerical labels       
                        if  blobThreads_sorted.y(tw,n) < height-20  && (wbstruct.nz(n)<numZ ||  blobThreads_sorted.x(tw,n)<width-30)
                           text(montageX(n),montageY(n),[' ' neuronLabel],'Color',thisColor,'VerticalAlignment','top');
                        else
                           text(montageX(n),montageY(n),[' ' neuronLabel],'Color',thisColor,'VerticalAlignment','bottom','HorizontalAlignment','right');
                        end
                    
                    end
                        
            end   
            
            
            DrawLegend;

            
            set(gca,'ButtonDownFcn', @(s,e) MouseDown)
            set(get(gca,'Children'),'ButtonDownFcn', @(s,e) MouseDown)

    end %DrawStuff

    function UpdateGUI
        set(handles.twtext,'String',['TW' num2str(currentTW)]);
    end

    function contSliderCallback
        
        sliderValue=get(handles.hSlider,'Value');
        newTW=round((sliderValue)*(numTW-1)+1);
        
        if newTW~=currentTW  
            UpdateGUI;
            currentTW=newTW;
            DrawTWs(currentTW);
            DrawStuff(currentTW);
            
        end
        ReleaseFocus(thisHandle);

    end

    function ReleaseFocus(fig)
        set(findobj(fig, 'Type', 'uicontrol'), 'Enable', 'off');
        drawnow;
        set(findobj(fig, 'Type', 'uicontrol'), 'Enable', 'on');
    end
       
end %main
