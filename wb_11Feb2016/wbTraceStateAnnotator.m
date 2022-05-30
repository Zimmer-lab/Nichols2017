function figureHandle=wbTraceStateAnnotator(wbstructOrTraceArray,options)

if nargin<2
    options=[];
end

if nargin<1 || isempty(wbstructOrTraceArray)
    
    [wbstruct wbstructFileName]=wbload([],false);
    WBSTRUCT_MODE=true;
    
else isnumeric(wbstructOrTraceArray)
    
    traces=wbstructOrTraceArray;
    WBSTRUCT_MODE=false;
    
end

if WBSTRUCT_MODE
    
    IDs=wbListIDs(wbstruct,true);


    if ~isfield(options,'startingNeuron');

        if ~isnan(wbgettrace('AVAL',wbstruct))
            options.startingNeuron='AVAL';
        elseif ~isnan(wbgettrace('AVAR',wbstruct))
            options.startingNeuron='AVAR';
        else
            IDs=wbListIDs(wbstruct);
            options.startingNeuron=IDs{1};
        end

    end

    if ~isfield(options,'refNeuron');

        if ~isnan(wbgettrace('AVAL',wbstruct))
            options.refNeuron='AVAL';
        elseif ~isnan(wbgettrace('AVAR',wbstruct))
            options.refNeuron='AVAR';
        else
            IDs=wbListIDs(wbstruct);
            options.refNeuron=IDs{1};
        end
    end

    if ~isfield(options,'thirdNeuron');

        if ~isnan(wbgettrace('AVAL',wbstruct))
            options.thirdNeuron='AVAL';
        elseif ~isnan(wbgettrace('AVAR',wbstruct))
            options.thirdNeuron='AVAR';
        else
            IDs=wbListIDs(wbstruct);
            options.thirdNeuron=IDs{1};
        end    
    end

end

if ~isfield(options,'figureHandle')
    options.figureHandle=[];
end

if ~isfield(options,'dt')
    options.dt=1/30;  %30 fps, only used if WBSTRUCT_MODE=false
end

if ~isfield(options,'pairedRefTraces')
    options.pairedRefTraces=[]; 
end

if ~isfield(options,'stateParamStructFile')
    options.stateParamStructFile=[]; 
end


if ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF_bc'; 
end

n=1;
n_ref=1;
n_third=1;

if WBSTRUCT_MODE
    
    % create wbstruct.simple.stateParams using defaults if it doesn't exist
    wbstruct=wbAddStateParams(wbstructFileName,false);
  
 
    traces=wbstruct.simple.(options.fieldName);
    
    if ~isfield(wbstruct.simple,'derivs')
        wbstruct=wbAddDerivs(wbstructFileName);
    end
    
    derivtraces=wbstruct.simple.derivs.traces;
    
    IDs=wbListIDs(wbstruct,true);
 
    [IDsSorted,IDSortIndex]=AlphaSort(IDs);
    nListValue=IDSortIndex(n);
 
    if isscalar(wbstruct.simple.derivs.alpha)
        regAlpha=wbstruct.simple.derivs.alpha*ones(1,wbstruct.simple.nn);
    else
        regAlpha=wbstruct.simple.derivs.alpha;
    end
    
    transitionTypes='AllRises';
    refNeuronSign=1;
    refNeuronTransitions=[];
    mainNeuronSign=1;
    mainNeuronTransitions=[];
    
else
    
    % for input into wbFourStateTraceAnalysis
    wbstruct.simple.deltaFOverF=traces;
    wbstruct.simple.nn=size(traces,2);
    regAlpha=.0001*ones(1,wbstruct.simple.nn);
    wbstruct.simple.derivs.traces=derivReg(traces,regAlpha);
    derivtraces=wbstruct.simple.derivs.traces;
    wbstruct.simple.stateParams=repmat([0.05 0.3]',1,wbstruct.simple.nn);
    wbstruct.simple.stateParams=[wbstruct.simple.stateParams; zeros(1,size(wbstruct.simple.stateParams,2)); ones(1,size(wbstruct.simple.stateParams,2)); ones(1,size(wbstruct.simple.stateParams,2))];
    wbstruct.tv=mtv(traces(:,1),options.dt);
    for i=1:size(traces,2)
        IDs{i}=num2str(i);
    end
    
    IDSortIndex=1:length(IDs);
    IDsSorted=IDs;
    nListValue=1;
    
    mainNeuronSign=1;
    refNeuronSign=1;
    refNeuronTransitions=[];
    mainNeuronTransitions=[];

end

for i=1:length(IDSortIndex)
    IDReverseSortIndex(IDSortIndex)=i;
end



%init data
threshSigFigs=3;
tv=wbstruct.tv;
viewDerivToggle=false;
viewTransitionsToggle=true;
viewFourColorsToggle=true;

posThresh=wbstruct.simple.stateParams(1,n);
negThresh=wbstruct.simple.stateParams(2,n);
forceNoPlateausFlag=wbstruct.simple.stateParams(3,n);
noFallToPlateauFlag=wbstruct.simple.stateParams(4,n);
fixBadTransitionsFlag=wbstruct.simple.stateParams(5,n);

threshType='rel';
handles=[];
traceColoring=[];
transitionListCellArray=[];

nListValue=IDSortIndex(n);
nListValue_ref=IDSortIndex(n_ref)+1;
nListValue_third=IDSortIndex(n_third)+1;

zoomLevel=1;
zoomCenter=0.5;
xLimMin=tv(1);
xLimMax=tv(end);
fullTime=xLimMax-xLimMin;
xTickSize=[60 15 5 2 1 1 1 1 1 1 1 1 1 1 1 1];
xTickMinorNum=[6 6 3 10 5 4 10*ones(1,10)];
refTransitionLineColor=MyColor('lr');

%init fig

if isempty(options.figureHandle)
    handles.fig=figure('Position',[0 0 1800 800],'Name','wbTraceStateAnnotator');
else
    set(0,'CurrentFigure',options.figureHandle);
    clf;
    handles.fig=options.figureHandle;
end

set(handles.fig,'KeyPressFcn', @(s,e) KeyPressedFcn);
subtightplot(1,1,1,[.01 .01],[.08 .04],[.1 .01]);
whitebg(handles.fig,'black');

DrawPlot;

figureHandle=handles.fig;

%draw GUI

if WBSTRUCT_MODE
    dataFolderList=listfolders([pwd filesep '..']);
    pwdtemp=pwd;
    currentDataFolder=pwdtemp(find(pwdtemp==filesep,1,'last')+1:end);

    handles.datasetPopup=uicontrol('Style','popupmenu','String',dataFolderList,'Units','Normalized','Position',[.1 .97 .15,.02],'Value',find(strcmp(upper(dataFolderList),upper(currentDataFolder))),'Callback',@(s,e) DatasetPopupCallback);
end

handles.timeSlider = uicontrol('Style','slider','Units','normalized','Position',[.10 .01 .89 .03],'Min',0,'Max',1,'SliderStep',[.01 10000],'Value',0.5,'Visible','off'); %,'Callback',@(s,e) disp('mouseup')
hListener0 = addlistener(handles.timeSlider,'Value','PostSet',@(s,e) timeSliderCallback) ;


handles.posThreshSlider = uicontrol('Style','slider','Position',[50 500 20 200],'SliderStep',[.001 .01],'Value',posThresh); %,'Callback',@(s,e) disp('mouseup')
hListener = addlistener(handles.posThreshSlider,'Value','PostSet',@(s,e) posThreshSliderCallback) ;

handles.negThreshSlider = uicontrol('Style','slider','Position',[100 500 20 200],'SliderStep',[.001 .01],'Value',negThresh); %,'Callback',@(s,e) disp('mouseup')
hListener2 = addlistener(handles.negThreshSlider,'Value','PostSet',@(s,e) negThreshSliderCallback) ;

handles.posThreshEditbox= uicontrol('Style','edit','String',num2str(posThresh),'Position',[50 710 40 20],'Callback',@(s,e) posThreshEditboxCallback);
handles.negThreshEditbox= uicontrol('Style','edit','String',num2str(negThresh),'Position',[100 710 40 20],'Callback',@(s,e) negThreshEditboxCallback);

handles.threshGroupLabel= uicontrol('Style','text','String','state classification params','Position',[45 760 100 30]);
handles.posThreshLabel= uicontrol('Style','text','String','+ thresh','Position',[50 730 40 20]);
handles.negThreshLabel= uicontrol('Style','text','String','- thresh','Position',[100 730 40 20]);

handles.posThresh0Label= uicontrol('Style','text','String','0','Position',[70 500 15 15]);
handles.posThresh1Label= uicontrol('Style','text','String','1','Position',[70 685 15 15]);
handles.negThresh0Label= uicontrol('Style','text','String','0','Position',[120 500 15 15]);
handles.negThresh1Label= uicontrol('Style','text','String','1','Position',[120 685 15 15]);

%handles.forceNoPlateausLabel= uicontrol('Style','text','String','ForceNoPlateaus','Position',[60 470 90 15]);
handles.forceNoPlateausCheckbox= uicontrol('Style','checkbox','Position',[40 470 110 20],'String','ForceNoPlateaus','Value',forceNoPlateausFlag,'Callback',@(s,e) ForceNoPlateausCheckboxCallback);
handles.noFallToPlateauCheckbox= uicontrol('Style','checkbox','Position',[40 450 110 20],'String','NoFallToPlateaus','Value',noFallToPlateauFlag,'Callback',@(s,e) NoFallToPlateauCheckboxCallback);
handles.fixBadTransitionsCheckbox= uicontrol('Style','checkbox','Position',[40 430 110 20],'String','FixBadTransitions','Value',fixBadTransitionsFlag,'Callback',@(s,e) FixBadTransitionsCheckboxCallback);

handles.saveIndicator=uicontrol('Style','text','String','SAVED.','Position',[45 400 100 30],'BackgroundColor','green');
handles.saveButton=uicontrol('Style','pushbutton','String','SAVE','Position',[45 360 100 30],'Visible','off','Callback',@(s,e) saveButtonCallback);

handles.derivGroupLabel= uicontrol('Style','text','String','derivative params','Position',[45 325 100 20]);
handles.regAlphaLabel= uicontrol('Style','text','String','alpha','Position',[50 300 40 20]);
handles.regAlphaEditBox= uicontrol('Style','edit','String',num2str(regAlpha(n)),'Position',[50 280 40 20],'Callback',@(s,e) regAlphaEditboxCallback);
handles.recomputeDerivsButton=uicontrol('Style','pushbutton','String','UPDATE 1','Position',[45 240 100 30],'Visible','off','Callback',@(s,e) recomputeDerivsCallback);
handles.recomputeAllDerivsButton=uicontrol('Style','pushbutton','String','UPDATE ALL','Position',[45 205 100 30],'Visible','off','Callback',@(s,e) recomputeAllDerivsCallback);

px=.85;
py=.85;
sf_x=.5;

%top row UI buttons
handles.viewDerivsButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.625 .965 .06 .03],'String','[D]eriv view','Callback',@(s,e) ViewDerivButtonCallback);
handles.viewTransitionsButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.7 .965 .06 .03],'String','[T]ransitions','Callback',@(s,e) ViewTransitionsButtonCallback);
handles.viewFourColorsButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.775 .965 .06 .03],'String','[F]our colors','Callback',@(s,e) ViewFourColorsButtonCallback);

handles.refNeuronTransitionTypePopup=uicontrol('Style','popup','Units','normalized','Position',[px+.085 py-.09 .04 .05],'String',{'rise','fall'},'Value',1,'Callback',@(s,e) RefNeuronTransitionTypeCallback,'Visible','on');
handles.mainNeuronTransitionTypePopup=uicontrol('Style','popup','Units','normalized','Position',[px+.085 py .04 .05],'String',{'rise','fall'},'Value',1,'Callback',@(s,e) MainNeuronTransitionTypeCallback,'Visible','on');
handles.makeDelayHistogramButton=uicontrol('Style','pushbutton','Units','normalized','Position',[px+.086 py-.025 .04 .03],'String','make histo','Callback',@(s,e) MakeDelayHistogramButtonCallback,'Visible','on');


%%%% change neurons

handles.nextButton = uicontrol('Style','pushbutton','Units','normalized','Position',[px+.06 py 0.05*sf_x 0.05],'String','next ->','Callback',@(s,e) nextButtonCallback);
handles.prevButton = uicontrol('Style','pushbutton','Units','normalized','Position',[px-.02 py 0.05*sf_x 0.05],'String','<- prev ','Callback',@(s,e) prevButtonCallback);
handles.IDPopup=uicontrol('Style','popupmenu','Value',n,'String',IDsSorted,'Units','normalized','Position',[px+.005 py 0.11*sf_x 0.05],'FontSize',14,'Callback',@(s,e) IDPopupCallback);

if isempty(options.pairedRefTraces)
    handles.refNeuronLabel= uicontrol('Style','text','String','reference neuron','BackgroundColor','r','Units','normalized','Position',[px+.005 py-.03 0.11*sf_x 0.02]);
    handles.refNeuronPopup= uicontrol('Style','popupmenu','Value',n_ref,'String',['off' IDsSorted],'Units','normalized','Position',[px+.005 py-.09 0.11*sf_x 0.05],'FontSize',12,'Callback',@(s,e) RefNeuronPopupCallback);
    handles.refNeuronCheckbox= uicontrol('Style','checkbox','Value',1,'BackgroundColor','r','Units','normalized','Position',[px-.005 py-.03 0.01 0.02],'Callback',@(s,e) RefNeuronCheckboxCallback);

    handles.thirdNeuronLabel= uicontrol('Style','text','String','third neuron','BackgroundColor','c','Units','normalized','Position',[px+.005 py-.10 0.11*sf_x 0.02]);
    handles.thirdNeuronPopup= uicontrol('Style','popupmenu','Value',n_third,'String',['off' IDsSorted],'Units','normalized','Position',[px+.005 py-.16 0.11*sf_x 0.05],'FontSize',12,'Visible','off','Callback',@(s,e) ThirdNeuronPopupCallback);
    handles.thirdNeuronCheckbox= uicontrol('Style','checkbox','Value',0,'BackgroundColor','c','Units','normalized','Position',[px-.005 py-.10 0.01 0.02],'Callback',@(s,e) ThirdNeuronCheckboxCallback);
    
end


handles.makeFavoriteButton = uicontrol('Style','pushbutton','Position',[50 210 90 30],'String','Mark as Favorite','Callback',@(s,e) MakeFavoriteButtonCallback);
handles.zoomGroupLabel= uicontrol('Style','text','String','zoom','Position',[75 170 40 20]);
handles.zoomInButton = uicontrol('Style','pushbutton','Position',[100 130 40 40],'String','+','Callback',@(s,e) ZoomInButtonCallback);
handles.zoomOutButton = uicontrol('Style','pushbutton','Position',[50 130 40 40],'String','-','Callback',@(s,e) ZoomOutButtonCallback);

buttonStartingBackgroundColor=get(handles.viewDerivsButton,'BackgroundColor');
blinkColor={buttonStartingBackgroundColor,'g'};
set(handles.viewTransitionsButton,'BackgroundColor',blinkColor{1+viewTransitionsToggle});  %ninja blinker code
set(handles.viewFourColorsButton,'BackgroundColor',blinkColor{1+viewFourColorsToggle});  %ninja blinker code
  
        
DrawStateDiagram(.01,.05,.07,.08);

%set initial neuron and initial ref neuron

if WBSTRUCT_MODE
    
    nListValue=find(strcmpi(IDsSorted,options.startingNeuron));
    
    if isempty(nListValue) 
        nListValue=1;
    end
    
    set(handles.IDPopup,'Value',nListValue);
    
    if strcmpi(options.refNeuron,'off')
        nListValue_ref=1;
    else
        nListValue_ref=find(strcmpi(IDsSorted,options.refNeuron))+1;
    end
    
    if isempty(nListValue_ref) 
        nListValue_ref=1;
    end

    set(handles.refNeuronPopup,'Value',nListValue_ref);
   
    if strcmpi(options.thirdNeuron,'off')
        nListValue_third=1;
    else
        nListValue_third=find(strcmpi(IDsSorted,options.thirdNeuron))+1;
    end
    
    if isempty(nListValue_third) 
        nListValue_third=1;
    end
    
    set(handles.thirdNeuronPopup,'Value',nListValue_third);
   
    
    IDPopupCallback;
    RefNeuronPopupCallback;
    ThirdNeuronPopupCallback;
end

%end main
%%%%%%%%%

%% subs

    function DrawStateDiagram(x,y,w,h)
        
        annotation('line',[x x+w/4],[y y],'Color','b','LineWidth',2);
        annotation('line',[x+w/4 x+w/2],[y y+h],'Color','r','LineWidth',2);
        annotation('line',[x+2*w/4 x+3*w/4],[y+h y+h],'Color','g','LineWidth',2);
        annotation('line',[x+3*w/4 x+w],[y+h y],'Color',[1 1 0],'LineWidth',2);
        
        
    end

    function KeyPressedFcn

            keyStroke=get(gcbo, 'CurrentKey');
            get(gcbo, 'CurrentCharacter');
            get(gcbo, 'CurrentModifier');
            
            if strcmp(keyStroke,'return')
                %save params
                
                saveButtonCallback;
                
                nextButtonCallback;
            
            elseif strcmp(keyStroke,'d')
                ViewDerivButtonCallback;
                
            elseif strcmp(keyStroke,'t')
                ViewTransitionsButtonCallback;
               
            elseif strcmp(keyStroke,'f')
                ViewFourColorsButtonCallback;
               
            elseif strcmp(keyStroke,'rightarrow')
                nextButtonCallback;
            
            
            elseif strcmp(keyStroke,'leftarrow')
                prevButtonCallback;
            
            
            elseif strcmp(keyStroke,'downarrow') && isempty(options.pairedRefTraces)
                
                nListValue_ref=min([nListValue_ref+1 length(IDs)+1]);            
                set(handles.refNeuronPopup,'Value',nListValue_ref);
                RefNeuronPopupCallback;
                
            elseif strcmp(keyStroke,'uparrow') && isempty(options.pairedRefTraces)
                
                nListValue_ref=max([1 nListValue_ref-1]);  
                set(handles.refNeuronPopup,'Value',nListValue_ref);
                RefNeuronPopupCallback;
   
            end
            
            
        end

    function LiveUpdatePlot
        
        thisOptions.forceNoPlateausFlag=forceNoPlateausFlag;
        thisOptions.fixBadTransitionsFlag=fixBadTransitionsFlag;
        thisOptions.noFallToPlateauFlag=noFallToPlateauFlag;
        
        %compute transitions for main neuron
        [thisTraceColoring, transitionListCellArray,transitionPreRunLengthArray]=wbFourStateTraceAnalysis(wbstruct,posThresh,negThresh,threshType,n,thisOptions);
        
        %select transitionType
        if get(handles.mainNeuronTransitionTypePopup,'Value')==1
            
            mainTransitionLineColor=MyColor('r');
            transitionTypes='AllRises';
            
        elseif get(handles.mainNeuronTransitionTypePopup,'Value')==2
            
            mainTransitionLineColor=MyColor('y');
            transitionTypes='AllFalls';
            
        else
            
            mainTransitionLineColor=MyColor('gray');
            transitionTypes='AllGood';
            
        end


        mainNeuronTransitions=wbGetTransitions(transitionListCellArray,1,transitionTypes,mainNeuronSign, transitionPreRunLengthArray);

        traceColoring(:,n)=thisTraceColoring;

        
        for co=1:4
            coloredData=zero2nan( double( traceColoring(:,n)==co )  );
            if viewDerivToggle
                set(handles.coloredPlot(co),'YData',coloredData.*derivtraces(:,n));
                ylim(1.1*[min([derivtraces(:,n); derivtraces(:,n_ref)]) max([derivtraces(:,n) ; derivtraces(:,n_ref)])]);

            else
                set(handles.coloredPlot(co),'YData',coloredData.*traces(:,n));
                if n_ref>0
                   ylim(1.1*[min([traces(:,n); traces(:,n_ref)]) max([traces(:,n) ; traces(:,n_ref)])]);
                else
                   ylim(1.1*[min(traces(:,n)) max(traces(:,n) )]);
                end
            end
        end
        
        %transition lines
         
        if isfield(handles,'transitionLinesMainNeuron') && ~isempty(handles.transitionLinesMainNeuron) && ishghandle(handles.transitionLinesMainNeuron(1))
            delete(handles.transitionLinesMainNeuron);
        end       
        yl=get(gca,'YLim');
        handles.transitionLinesMainNeuron=vline(tv(mainNeuronTransitions),mainTransitionLineColor,'-',[yl(1) 0.85*yl(1)]);  
        
        if isfield(handles,'transitionLinesRefNeuron') && ~isempty(handles.transitionLinesRefNeuron) && ishghandle(handles.transitionLinesRefNeuron(1))
            
            delete(handles.transitionLinesRefNeuron);
        end   
        
        handles.transitionLinesRefNeuron=vline(tv(refNeuronTransitions),refTransitionLineColor,'-',[yl(1) 0.9*yl(1)]);  

        
        %compute delays and plot connector lines
        
        if isfield(handles,'transitionConnectorLines') 
            for d=1:length(handles.transitionConnectorLines)
                if ishghandle(handles.transitionConnectorLines(d))
                    delete(handles.transitionConnectorLines(d));
                end
            end
        end   
        
        handles.transitionConnectorLines=[];
        delayDistribution=zeros(size(refNeuronTransitions));
        for k=1:length(refNeuronTransitions)
            delayDistribution(k)=mainNeuronTransitions(nearestTo(refNeuronTransitions(k),mainNeuronTransitions)) - refNeuronTransitions(k);
            handles.transitionConnectorLines(k)=line([tv(refNeuronTransitions(k)) tv(refNeuronTransitions(k)+delayDistribution(k))], [0.9*yl(1)  0.85*yl(1)],'Color','c');  

        end
        
        %draw transition numbers [of reference neuron]
        KillHandle('transitionNumbers',handles);
        handles.transitionNumbers=[];
        
        for k=1:length(refNeuronTransitions)
            handles.transitionNumbers(k)=text(tv(refNeuronTransitions(k)),yl(2)-.035*(yl(2)-yl(1)),num2str(k),'Color',refTransitionLineColor);
        end
        
  
        
        if viewTransitionsToggle && n_ref>0 && get(handles.refNeuronCheckbox,'Value')==1
            
           set(handles.refNeuronTransitionTypePopup,'Visible','on');       
           set(handles.transitionLinesRefNeuron,'Visible','on'); 
           set(handles.transitionConnectorLines,'Visible','on');
           set(handles.transitionNumbers,'Visible','on');

        else
            
           set(handles.refNeuronTransitionTypePopup,'Visible','off');
           set(handles.transitionLinesRefNeuron,'Visible','off');
           set(handles.transitionConnectorLines,'Visible','off');
           set(handles.transitionNumbers,'Visible','off');
        end
                 
        if WBSTRUCT_MODE
            UpdatePhasePlot;
        end

        
    end
               
    function UpdatePlot

        set(handles.IDPopup,'Value',nListValue);
        
        posThresh=wbstruct.simple.stateParams(1,n);
        negThresh=wbstruct.simple.stateParams(2,n);
        forceNoPlateausFlag=wbstruct.simple.stateParams(3,n);
        noFallToPlateauFlag=wbstruct.simple.stateParams(4,n);
        fixBadTransitionsFlag=wbstruct.simple.stateParams(5,n);
        
        set(handles.posThreshSlider,'Value',posThresh);
        set(handles.negThreshSlider,'Value',negThresh);  
        
        set(handles.forceNoPlateausCheckbox,'Value',forceNoPlateausFlag);
        set(handles.noFallToPlateauCheckbox,'Value',noFallToPlateauFlag);
        set(handles.fixBadTransitionsCheckbox,'Value',fixBadTransitionsFlag);
        
        set(handles.regAlphaEditBox,'String',num2str(regAlpha(n)));
        
        LiveUpdatePlot;
        
        if isempty(options.pairedRefTraces)

            UpdatePhasePlot;
            
        else
            
            set(handles.pairedRefTrace,'YData',options.pairedRefTraces(:,n));
            
        end
        
        set(handles.saveIndicator,'BackgroundColor','g');
        set(handles.saveIndicator,'String','SAVED.');
        set(handles.saveButton,'Visible','off');

    end

    function DrawPlot

        hold off;
        
        markerType='none';
        markerSize=12;
        
        if viewFourColorsToggle
             cl=.3;ch=.7;
             stateColors={[0 0 1],[1 0 0],[0 1 0],[1 1 0]};
             stateColors_light={[cl cl ch],[ch cl cl],[cl ch cl],[ch ch cl]};
        else
             stateColors={[0 1 0],[0 1 0],[0 1 0],[0 1 0]};
             stateColors_light={[1 0 0],[1 0 0],[1 0 0],[1 0 0]};
        end

        [thisTraceColoring, transitionListCellArray]=wbFourStateTraceAnalysis(wbstruct,posThresh,negThresh,threshType,n);
        traceColoring(:,n)=thisTraceColoring;

        %handles.plot=plot(tv,traces(:,n));

        %ref neuron underlay      
        if isempty(options.pairedRefTraces)

            [thisTraceColoring, transitionListCellArray]=wbFourStateTraceAnalysis(wbstruct,posThresh,negThresh,threshType,n_ref);
            traceColoring(:,n_ref)=thisTraceColoring;
            for k=1:4
                coloredData=zero2nan( double( traceColoring(:,n_ref)==k )  );
                if viewDerivToggle
                    handles.coloredPlot_ref(k)=plot(tv,coloredData.*derivtraces(:,n_ref),'Color',stateColors_light{k},'LineWidth',1,'Marker',markerType,'MarkerSize',markerSize);
                else
                    handles.coloredPlot_ref(k)=plot(tv,coloredData.*traces(:,n_ref),'Color',stateColors_light{k},'LineWidth',1,'Marker',markerType,'MarkerSize',markerSize);
                end
                set(handles.coloredPlot_ref(k),'Visible','off');
                hold on; 

            end            
            
            %third neuron
            [thisTraceColoring, transitionListCellArray]=wbFourStateTraceAnalysis(wbstruct,posThresh,negThresh,threshType,n_third);
            traceColoring(:,n_third)=thisTraceColoring;
            for k=1:4
                coloredData=zero2nan( double( traceColoring(:,n_third)==k )  );
                if viewDerivToggle
                    handles.coloredPlot_third(k)=plot(tv,coloredData.*derivtraces(:,n_third),'Color',stateColors_light{k},'LineWidth',1,'Marker',markerType,'MarkerSize',markerSize);
                else
                    handles.coloredPlot_third(k)=plot(tv,coloredData.*traces(:,n_third),'Color',stateColors_light{k},'LineWidth',1,'Marker',markerType,'MarkerSize',markerSize);
                end
                set(handles.coloredPlot_third(k),'Visible','off');
                hold on; 

            end
            
            

        else
            
            handles.pairedRefTrace=plot(tv,options.pairedRefTraces(:,n),'Color',MyColor('lr'));
            hold on; 

        end
        
        %main plot
        for k=1:4  %four states to color        
                coloredData=zero2nan( double( traceColoring(:,n)==k )  );
                
                if viewDerivToggle
                    handles.coloredPlot(k)=plot(tv,coloredData.*derivtraces(:,n),'Color',stateColors{k},'LineWidth',1,'Marker',markerType,'MarkerSize',markerSize);
                else
                    handles.coloredPlot(k)=plot(tv,coloredData.*traces(:,n),'Color',stateColors{k},'LineWidth',1,'Marker',markerType,'MarkerSize',markerSize);
                end
                hold on; 
        end
        

      
        xlim([xLimMin xLimMax]);
            
        %phase plot in the corner
        if isempty(options.pairedRefTraces)

            subplotSize=.1;
            xl=get(gca,'XLim');
            yl=get(gca,'YLim');
            ar=daspect; %data aspect ratio
            xscale=ar(1)/2;
            yscale=ar(2);
            subplotOrigin=[.01*(xl(2)-xl(1))+xl(1) yl(2)-1.2*yscale*subplotSize]; %yl(2)-1.2*subplotSize];
            
            for k=1:4
                handles.phasePlot(k)=plot(coloredData.*(subplotOrigin(1)+xscale*subplotSize*normalize(traces(:,n),4)), coloredData.*(subplotOrigin(2)+yscale*subplotSize*normalize(traces(:,n_ref),4)),'Color',stateColors{k},'Marker',markerType,'MarkerSize',markerSize,'Visible','off');  
            end
            
            handles.phasePlotBBox=rectangle('Position',[subplotOrigin(1) subplotOrigin(2) xscale*subplotSize yscale*subplotSize],'EdgeColor',[0.2 0.2 0.2],'Visible','off');
            handles.phasePlotXLabel=text(subplotOrigin(1)+xscale*subplotSize/2,subplotOrigin(2)-.05*yscale*subplotSize,IDs{n},'Visible','off','Color',[0.2 0.2 0.2],...
                'HorizontalAlignment','center');
            %handles.phasePlotYLabel=
        end
        
        
        set(gca,'XTick',ceil(tv(1)):xTickSize(zoomLevel):floor(tv(end)));
        set(gca,'XMinorTick','on');

        xlim([tv(1) tv(end)]);
        xlabel('time (s)');
        ylabel('\DeltaF/F0');
                
    end

    function UpdatePhasePlot
        
        if n_ref>0
            subplotSize=.2;
            xl=get(gca,'XLim');
            yl=get(gca,'YLim');
            xscale=(xl(2)-xl(1))/2;
            yscale=yl(2)-yl(1);
            subplotOrigin=[.01*(xl(2)-xl(1))+xl(1) yl(2)-1.2*yscale*subplotSize]; %yl(2)-1.2*subplotSize];
            for k=1:4
                coloredData=zero2nan( double( traceColoring(:,n)==k )  );
                set(handles.phasePlot(k),'XData',coloredData.*(subplotOrigin(1)+xscale*subplotSize*fastsmooth(normalize(traces(:,n),4),5,3,1)));
                set(handles.phasePlot(k),'YData',coloredData.*(subplotOrigin(2)+yscale*subplotSize*fastsmooth(normalize(traces(:,n_ref),4),5,3,1)));  
            end
            set(handles.phasePlot,'Visible','on');
            
            set(handles.phasePlotBBox,'Position',[subplotOrigin(1) subplotOrigin(2) xscale*subplotSize yscale*subplotSize]);
            set(handles.phasePlotBBox,'Visible','on');
            set(handles.phasePlotXLabel,'Visible','on');
            set(handles.phasePlotXLabel,'String',IDs{n});
            set(handles.phasePlotXLabel,'Position',[subplotOrigin(1)+xscale*subplotSize/2,subplotOrigin(2)-.05*yscale*subplotSize]);
        else
            set(handles.phasePlot,'Visible','off');
            set(handles.phasePlotBBox,'Visible','off');
            set(handles.phasePlotXLabel,'Visible','off');
        end
    end

%% callbacks

    function DatasetPopupCallback
        
        currentDataFolder=dataFolderList{get(gcbo,'Value')};
        cd(['..' filesep currentDataFolder]);
        
        thisOptions.startingNeuron=IDsSorted{get(handles.IDPopup,'Value')};

        if get(handles.refNeuronPopup,'Value')>1
            
            thisOptions.refNeuron=IDsSorted{get(handles.refNeuronPopup,'Value')-1};
        else
            thisOptions.refNeuron='off';
        end
        
        wbTraceStateAnnotator([],thisOptions);
        close(handles.fig);
    end 

    function MakeDelayHistogramButtonCallback
        
        neuron1=IDs{n_ref}; %ref 
        neuron2=IDs{n};       %main
        
        if get(handles.refNeuronTransitionTypePopup,'Value')==1  %ref rise
            
            if get(handles.mainNeuronTransitionTypePopup,'Value')==1 %main rise 
               thisOptions.neuron1Sign=1;
               thisOptions.neuron2Sign=1;
               thisOptions.transitionTypes='AllRises';
                    
            else  %main fall 
               thisOptions.neuron1Sign=1;
               thisOptions.neuron2Sign=-1;
               thisOptions.transitionTypes='SignedAllRises';
               
                                
            end
            
        else %ref fall
               
            if get(handles.mainNeuronTransitionTypePopup,'Value')==1 %main rise 
               thisOptions.neuron1Sign=1;
               thisOptions.neuron2Sign=-1;
               thisOptions.transitionTypes='SignedAllFalls';
                    
            else  %main fall 
               thisOptions.neuron1Sign=1;
               thisOptions.neuron2Sign=1;
               thisOptions.transitionTypes='AllFalls';
               
                                
            end   
                            
        end
        

        thisOptions.plotTraces=false;
        thisOptions.plotRefTrace=false;
        thisOptions.hideOutliers=false;
        
        thisOptions.timeWindowSize=20;
        thisOptions.savePDFFlag=true;
        
        TTASt=wbPlotTTAHisto([],neuron1,neuron2,thisOptions);
        assignin('base','TTAstruct',TTASt);

    end

    function MainNeuronTransitionTypeCallback
        UpdatePlot;
    end

    function RefNeuronTransitionTypeCallback
        RefNeuronPopupCallback;
        UpdatePlot;
    end

    function ViewTransitionsButtonCallback
        
        viewTransitionsToggle=~viewTransitionsToggle;
        
        set(handles.viewTransitionsButton,'BackgroundColor',blinkColor{1+viewTransitionsToggle});  %ninja blinker code
        
        if viewTransitionsToggle
            set(handles.mainNeuronTransitionTypePopup,'Visible','on');
            set(handles.transitionLinesMainNeuron,'Visible','on');  
        else
            set(handles.mainNeuronTransitionTypePopup,'Visible','off');
            set(handles.transitionLinesMainNeuron,'Visible','off'); 

        end
        
        
        if viewTransitionsToggle && n_ref>0 && get(handles.refNeuronCheckbox,'Value')==1
            
           set(handles.refNeuronTransitionTypePopup,'Visible','on');       
           set(handles.transitionLinesRefNeuron,'Visible','on'); 
           set(handles.transitionConnectorLines,'Visible','on');
           set(handles.transitionNumbers,'Visible','on');
           
        else
            
           set(handles.refNeuronTransitionTypePopup,'Visible','off');
           set(handles.transitionLinesRefNeuron,'Visible','off');
           set(handles.transitionConnectorLines,'Visible','off');
           set(handles.transitionNumbers,'Visible','off');
           
        end
        
        UpdatePlot;    

    end

    function ViewDerivButtonCallback
        
        set(handles.viewDerivsButton,'BackgroundColor',blinkColor{2-viewDerivToggle});  %ninja blinker code
        viewDerivToggle=~viewDerivToggle;
        DrawPlot;
        
    end

    function ViewFourColorsButtonCallback
        
        set(handles.viewFourColorsButton,'BackgroundColor',blinkColor{2-viewFourColorsToggle});  %ninja blinker code
        viewFourColorsToggle=~viewFourColorsToggle;
        
        if viewFourColorsToggle
             cl=.3;ch=.7;
             stateColors={[0 0 1],[1 0 0],[0 1 0],[1 1 0]};
             stateColors_light={[cl cl ch],[ch cl cl],[cl ch cl],[ch ch cl]};
             stateColors_light2={[cl cl ch],[ch cl cl],[cl ch cl],[ch ch cl]};
        else
             stateColors={[0 1 0],[0 1 0],[0 1 0],[0 1 0]};
             stateColors_light={[1 0 0],[1 0 0],[1 0 0],[1 0 0]};
             stateColors_light2={[0 1 1],[0 1 1],[0 1 1],[0 1 1]};
        end
            
        for k=1:4
            set(handles.coloredPlot(k),'Color',stateColors{k});
            set(handles.coloredPlot_ref(k),'Color',stateColors_light{k});
            set(handles.coloredPlot_third(k),'Color',stateColors_light2{k});
        end

        %RefNeuronPopupCallback;
    end

    function recomputeDerivsCallback
        
        set(handles.recomputeAllDerivsButton,'Visible','off');

        
        stateParams=wbstruct.simple.stateParams;
        stateParams(:,n)=[get(handles.posThreshSlider,'Value'),  get(handles.negThreshSlider,'Value'),get(handles.forceNoPlateausCheckbox,'Value'),...
            get(handles.noFallToPlateauCheckbox,'Value'),get(handles.fixBadTransitionsCheckbox,'Value')];

        
        wbstruct.simple.derivs.traces(:,n)=derivReg(traces(:,n),regAlpha(n));
        derivtraces=wbstruct.simple.derivs.traces;

        DrawPlot;
        
        if ~WBSTRUCT_MODE            
            if isempty(options.stateParamStructFile)
                options.stateParamStructFile='stateParamStruct.mat';
            end
            save(options.stateParamStructFile,'stateParams','regAlpha');
            
        end
        
        set(handles.recomputeDerivsButton,'Visible','off');
        
    end

    function recomputeAllDerivsCallback
        
        set(handles.recomputeDerivsButton,'Visible','off');
        
        stateParams=wbstruct.simple.stateParams;
        stateParams(:,n)=[get(handles.posThreshSlider,'Value'),  get(handles.negThreshSlider,'Value'),get(handles.forceNoPlateausCheckbox,'Value'),...
            get(handles.noFallToPlateauCheckbox,'Value'),get(handles.fixBadTransitionsCheckbox,'Value')];
        
        regAlpha(:)=regAlpha(n);

        wbstruct.simple.derivs.traces=derivReg(traces,regAlpha);
        derivtraces=wbstruct.simple.derivs.traces;

        DrawPlot;
        
        if ~WBSTRUCT_MODE
                               
            if isempty(options.stateParamStructFile)
                options.stateParamStructFile='stateParamStruct.mat';
            end
            save(options.stateParamStructFile,'stateParams','regAlpha','derivtraces');
            
        end
        
        set(handles.recomputeAllDerivsButton,'Visible','off');
        
    end

    function saveButtonCallback
        
        stateParams=wbstruct.simple.stateParams;
        stateParams(:,n)=[get(handles.posThreshSlider,'Value'),  get(handles.negThreshSlider,'Value')  get(handles.forceNoPlateausCheckbox,'Value')...
             get(handles.noFallToPlateauCheckbox,'Value'),  get(handles.fixBadTransitionsCheckbox,'Value')];

        
        if WBSTRUCT_MODE
            
            wbstruct.simple.derivs.alpha=regAlpha;
            wbstruct.simple.stateParams=stateParams;
            simple=wbstruct.simple;
            save(wbstructFileName,'simple','-append');

        else
            
            %update local data
            wbstruct.simple.derivs.alpha=regAlpha;
            wbstruct.simple.stateParams=stateParams;
            wbstruct.simple.derivs.traces=derivtraces;
            
            if isempty(options.stateParamStructFile)
                options.stateParamStructFile='stateParamStruct.mat';
            end
            
            save(options.stateParamStructFile,'stateParams','regAlpha','derivtraces','traceColoring');
            
        end
            

        set(handles.saveIndicator,'BackgroundColor','g');
        set(handles.saveIndicator,'String','SAVED.');
        set(handles.saveButton,'Visible','off');
                
    end

    function timeSliderCallback
        oldZoomCenter=zoomCenter;
        zoomCenter=get(handles.timeSlider,'Value');
        currentRng=xLimMax-xLimMin;
        
         xLimMin=min([max([xLimMin+(zoomCenter-oldZoomCenter)*(xLimMax-xLimMin) tv(1)]) tv(end)-currentRng]  );
         xLimMax=xLimMin+currentRng;
         
%         
  %      xLimMin=max([tv(1)+(zoomCenter-oldZoomCenter)*(tv(end)-tv(1)) tv(1) ]);
  %      xLimMax=max([tv(end)+(zoomCenter-oldZoomCenter)*(tv(end)-tv(1)) currentRng ]);
        xlim([xLimMin xLimMax]);
        
    end

    function ZoomInButtonCallback
        
        zoomLevel=zoomLevel+1;
        
        if zoomLevel>16
            zoomLevel=16;
        end
       
        set(handles.timeSlider,'Visible','on');
        
        xl=get(gca,'XLim');
        xLimMin=xl(1); xLimMax=xl(2);
        currentCenter=(xLimMax+xLimMin)/2;

        xLimMin=max([tv(1) currentCenter - (currentCenter-xLimMin)/2])  ; 
        xLimMax=min([tv(end) currentCenter + (xLimMax-currentCenter)/2])  ; 
        xlim([xLimMin xLimMax]);
        set(gca,'XTick',ceil(tv(1)):xTickSize(zoomLevel):floor(tv(end)));

        set(handles.zoomGroupLabel,'String',['zoom ' num2str(zoomLevel) 'x']);
    
            
        if zoomLevel>2
            set(handles.coloredPlot,'Marker','.');
        end
        
        set(handles.timeSlider,'SliderStep',[.3*(xLimMax-xLimMin)/(tv(end)-tv(1)) (xLimMax-xLimMin)/(tv(end)-tv(1))]);
        
        UpdatePhasePlot;
        
    end

    function ZoomOutButtonCallback
        
         zoomLevel=max([1 zoomLevel-1]);
         
         if zoomLevel==1
             set(handles.timeSlider,'Visible','off');
             set(handles.timeSlider,'Value',0.5);
             zoomCenter=0.5;
             xLimMin=tv(1);
             xLimMax=tv(end);
            
         else %zoomLevel>1
            
            xl=get(gca,'XLim');
            xLimMin=xl(1); xLimMax=xl(2);
            currentCenter=(xLimMax+xLimMin)/2;
            xLimMin=max([tv(1) currentCenter - (currentCenter-xLimMin)*2])  ; 
            xLimMax=min([tv(end) currentCenter + (xLimMax-currentCenter)*2])  ; 
            
         end;
         xlim([xLimMin xLimMax]);
         set(gca,'XTick',ceil(tv(1)):xTickSize(zoomLevel):floor(tv(end)));
                      
         set(handles.zoomGroupLabel,'String',['zoom ' num2str(zoomLevel) 'x']);

         if zoomLevel<3
            set(handles.coloredPlot,'Marker','none');
         end
         
        set(handles.timeSlider,'SliderStep',[.3*(xLimMax-xLimMin)/(tv(end)-tv(1)) (xLimMax-xLimMin)/(tv(end)-tv(1))]);

        UpdatePhasePlot;
         
    end

    function regAlphaEditboxCallback
        
        set(handles.recomputeDerivsButton,'Visible','on');
        set(handles.recomputeAllDerivsButton,'Visible','on');
        str2num(get(gcbo,'String'))

        regAlpha(n)=str2num(get(gcbo,'String'));        
        
    end

    function posThreshEditboxCallback
        
        set(handles.saveIndicator,'BackgroundColor','r');
        set(handles.saveIndicator,'String','UNSAVED.');
        set(handles.saveButton,'Visible','on');
        
        posThresh=str2num(get(gcbo,'String'));
        LiveUpdatePlot;
        
    end

    function negThreshEditboxCallback
        
        set(handles.saveIndicator,'BackgroundColor','r');
        set(handles.saveIndicator,'String','UNSAVED.');
        set(handles.saveButton,'Visible','on');
        
        negThresh=-abs(str2num(get(gcbo,'String')));
        
        set(handles.negThreshEditbox,'String',num2str(get(handles.negThreshSlider,'Value'),threshSigFigs));

        LiveUpdatePlot;
        
    end

    function posThreshSliderCallback
        
        set(handles.saveIndicator,'BackgroundColor','r');
        set(handles.saveIndicator,'String','UNSAVED.');
        set(handles.saveButton,'Visible','on');
        
        posThresh=get(handles.posThreshSlider,'Value');
        
        set(handles.posThreshEditbox,'String',num2str(get(handles.posThreshSlider,'Value'),threshSigFigs));
        
        LiveUpdatePlot;
    end

    function negThreshSliderCallback
        
        set(handles.saveIndicator,'BackgroundColor','r');
        set(handles.saveIndicator,'String','UNSAVED.');
        set(handles.saveButton,'Visible','on');
       
        negThresh=-abs(get(handles.negThreshSlider,'Value'));
        
        set(handles.negThreshEditbox,'String',num2str(get(handles.negThreshSlider,'Value'),threshSigFigs));
        
        LiveUpdatePlot;
    end

    function ForceNoPlateausCheckboxCallback

        set(handles.saveIndicator,'BackgroundColor','r');
        set(handles.saveIndicator,'String','UNSAVED.');
        set(handles.saveButton,'Visible','on');
        
        forceNoPlateausFlag=get(gcbo,'Value');
        LiveUpdatePlot;
        
    end
    function NoFallToPlateauCheckboxCallback

        set(handles.saveIndicator,'BackgroundColor','r');
        set(handles.saveIndicator,'String','UNSAVED.');
        set(handles.saveButton,'Visible','on');
        
        noFallToPlateauFlag=get(gcbo,'Value');
        LiveUpdatePlot;
        
    end

    function FixBadTransitionsCheckboxCallback

        set(handles.saveIndicator,'BackgroundColor','r');
        set(handles.saveIndicator,'String','UNSAVED.');
        set(handles.saveButton,'Visible','on');
        
        fixBadTransitionsFlag=get(gcbo,'Value');
        LiveUpdatePlot;
        
    end

    function MakeFavoriteButtonCallback

        neuronString=IDsSorted{nListValue};
        neuronClass=neuronString(1:end-1);
%         disp(['neuron:'  neuronString]);
%         disp(['neuronClass:'  neuronClass]);
        if exist(['Quant' filesep 'wbhints.mat'],'file')
            hints=load(['Quant' filesep 'wbhints.mat']);     
        end
        hints.(neuronClass)=neuronString;
        save(['Quant' filesep 'wbhints.mat'],'-struct','hints');
        
    end

    function IDPopupCallback
        
        nListValue=get(handles.IDPopup,'Value');
        n=IDSortIndex(nListValue);
        UpdatePlot;
    end

    function RefNeuronPopupCallback


        nListValue_ref=get(handles.refNeuronPopup,'Value');
        
        if (nListValue_ref > 1)
            n_ref=IDSortIndex(nListValue_ref-1);
        else
            n_ref=0;
        end
        
        

        if n_ref>0
            
            
            posThresh_ref=wbstruct.simple.stateParams(1,n_ref);
            negThresh_ref=wbstruct.simple.stateParams(2,n_ref);
            forceNoPlateausFlag_ref=wbstruct.simple.stateParams(3,n_ref);

        
            thisOptions.forceNoPlateausFlag=forceNoPlateausFlag_ref; 

            %ref neuron underlay
            [thisTraceColoring, transitionListCellArray,transitionPreRunLengthArray]=wbFourStateTraceAnalysis(wbstruct,posThresh_ref,negThresh_ref,threshType,n_ref,thisOptions);
            
            %select transitionType
            if get(handles.refNeuronTransitionTypePopup,'Value')==1

                refTransitionLineColor=MyColor('lr');
                refTransitionTypes='AllRises';

            elseif get(handles.refNeuronTransitionTypePopup,'Value')==2

                refTransitionLineColor=MyColor('ly');
                refTransitionTypes='AllFalls';

            else

                refTransitionLineColor=MyColor('lightgray');
                refTransitionTypes='AllGood';

            end
        
            
            refNeuronTransitions=wbGetTransitions(transitionListCellArray,1,refTransitionTypes,refNeuronSign, transitionPreRunLengthArray);
            traceColoring(:,n_ref)=thisTraceColoring;
            for k=1:4
                if get(handles.refNeuronCheckbox,'Value')
                    set(handles.coloredPlot_ref(k),'Visible','on');
                end
                coloredData=zero2nan( double( traceColoring(:,n_ref)==k )  );
                set(handles.coloredPlot_ref(k),'YData',coloredData.*traces(:,n_ref));
                ylim(1.1*[min([traces(:,n) ; traces(:,n_ref)]) max([traces(:,n) ; traces(:,n_ref)])]);

            end
            
            
        else
            
            set(handles.coloredPlot_ref,'Visible','off');
            set(handles.transitionLinesRefNeuron,'Visible','off');
            set(handles.transitionConnectorLines,'Visible','off'); 
            set(handles.transitionNumbers,'Visible','off');

            ylim(1.1*[min(traces(:,n)) max(traces(:,n))]);

        end
                
        UpdatePlot;
        
    end

    function RefNeuronCheckboxCallback
        
        if get(gcbo,'Value')==1
             set(handles.coloredPlot_ref,'Visible','on');
             set(handles.transitionLinesRefNeuron,'Visible','on');
             set(handles.transitionConnectorLines,'Visible','on'); 
             set(handles.refNeuronTransitionTypePopup,'Visible','on');       

        else
             set(handles.coloredPlot_ref,'Visible','off');
             set(handles.transitionLinesRefNeuron,'Visible','off');
             set(handles.transitionConnectorLines,'Visible','off');       
             set(handles.refNeuronTransitionTypePopup,'Visible','off');

        end
     
    end

    function ThirdNeuronPopupCallback
        
        nListValue_third=get(handles.thirdNeuronPopup,'Value');
        
        if (nListValue_third > 1)
            n_third=IDSortIndex(nListValue_third-1);
        else
            n_third=0;
        end
        
        if n_third>0
            
            
            %third neuron underlay
            [thisTraceColoring, transitionListCellArray,transitionPreRunLengthArray]=wbFourStateTraceAnalysis(wbstruct,posThresh,negThresh,threshType,n_third);
             
            %select transitionType
%             if get(handles.thirdNeuronTransitionTypePopup,'Value')==1
% 
%                 thirdTransitionLineColor=color('lr');
%                 transitionTypes='AllRises';
% 
%             elseif get(handles.refNeuronTransitionTypePopup,'Value')==2
% 
%                 thirdTransitionLineColor=color('ly');
%                 transitionTypes='AllFalls';
% 
%             else
% 
%                 thirdTransitionLineColor=color('lightgray');
%                 transitionTypes='AllGood';
% 
%             end
        
            
%           refNeuronTransitions=wbGetTransitions(transitionListCellArray,1,transitionTypes,refNeuronSign, transitionPreRunLengthArray);
            traceColoring(:,n_third)=thisTraceColoring;
            for k=1:4
                if get(handles.thirdNeuronCheckbox,'Value')
                    set(handles.coloredPlot_third(k),'Visible','on');
                end
                coloredData=zero2nan( double( traceColoring(:,n_third)==k )  );
                set(handles.coloredPlot_third(k),'YData',coloredData.*traces(:,n_third));
                ylim(1.1*[min([traces(:,n) ; traces(:,n_third)]) max([traces(:,n) ; traces(:,n_third)])]);

            end
%             
            
        else
            
            set(handles.coloredPlot_third,'Visible','off');
%             set(handles.transitionLinesRefNeuron,'Visible','off');
%             set(handles.transitionConnectorLines,'Visible','off'); 
%             set(handles.transitionNumbers,'Visible','off');

            ylim(1.1*[min(traces(:,n)) max(traces(:,n))]);

        end
                
        UpdatePlot;
        
    end

    function ThirdNeuronCheckboxCallback
        
        if get(gcbo,'Value')==1
             set(handles.coloredPlot_third,'Visible','on');
             set(handles.thirdNeuronPopup,'Visible','on');
%              set(handles.transitionLinesRefNeuron,'Visible','on');
%              set(handles.transitionConnectorLines,'Visible','on'); 
%             set(handles.thirdNeuronTransitionTypePopup,'Visible','on');       

        else
             set(handles.coloredPlot_third,'Visible','off');
             set(handles.thirdNeuronPopup,'Visible','off');
%              set(handles.transitionLinesRefNeuron,'Visible','off');
%              set(handles.transitionConnectorLines,'Visible','off');       
%             set(handles.thirdNeuronTransitionTypePopup,'Visible','off');

        end
     
    end

    function nextButtonCallback       
        nListValue=nListValue+1;
        if (nListValue>size(traces,2)) nListValue=1; end
        n=IDSortIndex(nListValue);
        UpdatePlot;
        
    end

    function prevButtonCallback
        nListValue=nListValue-1;
        if (nListValue<1) nListValue=size(traces,2); end
        n=IDSortIndex(nListValue);
        UpdatePlot;
    end


end