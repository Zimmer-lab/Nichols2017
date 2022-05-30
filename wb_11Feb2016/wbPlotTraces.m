function wbPlotTraces(wbstruct,options)


%% preliminaries

if nargin<1
    wbstruct=[];
end

if nargin<2
    options=[];
end

if ~isfield(options,'range')
    options.range=[];  
end

if ~isfield(options,'scrollBar')
    options.scrollBar=false;
end

if ~isfield(options,'maxRowsPerPage')
    options.maxRowsPerPage=10;
end

if ~isfield(options,'secondaryPlotOptions')
    options.secondaryPlotOptions=[];
end

if ~isfield(options,'secondaryPlotFlag')
    options.secondaryPlotFlag='true';  
end

if ~isfield(options,'secondaryPlotType')
    options.secondaryPlotType='autocorr'; %pca  
end

if ~isfield(options,'normalizeFlag')
    options.normalizeFlag=false; 
end

if ~isfield(options,'extraExclusionList')
    options.extraExclusionList=[]; 
end

if ~isfield(options,'lowRes')
    options.lowRes=true;
end

if ~isfield(options,'showIDs')
    options.showIDs=true;
end

if ~isfield(options,'displayTarget')
    options.displayTarget='presentation';
end

if ~isfield(options,'invertColor')
    options.invertColor=true;
end

if ~isfield(options,'hideExclusions')
    options.hideExclusions=false;
end

if ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF';
end

if ~isfield(options,'fieldName2')
    options.fieldName2='deltaFOverFNoBackSub';  %leave as [] to skip plotting second trace overlay
end

if ~isfield(options,'showSmoothedFlag')
    options.showSmoothedFlag='false';  %leave as [] to skip plotting second trace overlay
end

if ~isfield(options,'postProcessFunction')
    options.postProcessFunction=[];
end

%parse custom sort order
if ~isfield(options,'customSortOrder')  %overrides sortMethod
    options.customSortOrder=[];
end

if  ~isfield(options,'customSortOrderName')
    options.customSortOrderName='custom';
end

%get sort types
sortTypes=[wbSortTraces('get') options.customSortOrderName];  %get sortTypes from wbSortTraces function

%seondary plot types
secondaryPlotTypes={'none','PC','autocorrelation','derivOld','derivRegularized','powerspectrum'};
secondaryPlotParam1Labels={'null','pc#','windowSize','smoothingWindow','null','null'};
secondaryPlotParam1DefaultValues=[0 , 1 , 0, 3, 0.0001,0];
secondaryPlotParam2Labels={'null','null','epoch','null','underlay','epoch'};
secondaryPlotParam2Values={{'null'},{'null'},{'full','pre','post','dual'},{'null'},{'hide','show'},{'full','pre','post','dual'} };
secondaryPlotisColorableFlags=[false,true,false,true,true,false];
secondaryPlotXUnits={'s','s','s','s','s','loghz'};
secondaryPlotXLabels={'time (s)','time (s)','time (s)','time (s)','time (s)','period (s)'};
secondaryPlotLegends={{},{},{'post','pre'},{},{'raw','reg.'},{'post','pre'}};

%% get traces and ranging and create labels
traces=[];traceLabelTag=[];numTraces=[];traceLabels=[];traceColoring=[];
traces_unsorted=[];exclusionList=[];
tracesall_unsorted=[];traceLabels_unsorted=[];traceLabelTag_unsorted=[];
traceColoring_unsorted=[];reducedSortOrder=[];
transitionListCellArray={};
transitionKeyFrame=1000;


posThresh=.05; %0.01;
negThresh=-0.3; %04;
threshTypeList={'abs','rel'};
threshType=threshTypeList{2};

PrepWBstruct;

disp('wbstruct loaded.');

%initialize GUI settings
dataFolderList=listfolders([pwd filesep '..']);
pwdtemp=pwd;
currentDataFolder=pwdtemp(find(pwdtemp==filesep,1,'last')+1:end);

showSmoothedFlag=false;
hideUnlabeledFlag=true;
hideExclusionsFlag=true;
colorStateFlag=true;
normalizeFlag=false;
drawTransitionLinesFlag=true;

traceVisibleTag=[];
updateTraceVisibleTags;
sortOrder=[];
sortVal=[];

secondaryPlotParam1=0;
secondaryPlotParam2='';
secondaryPlotData=[];

stateColors={[0 0 1],[1 0 0],[0 1 0],[1 1 0]};

sortMethod='position';
secondaryPlotType='none'; 
secondaryPlotFlag=false;
secondaryPlotisColorableFlag=false;
secondaryPlotXUnit='s';
secondaryPlotXLabel='time (s)';
secondaryPlotLegend={};

colorByList=['self',wbListIDs(wbstruct)]; %,'pca1','pca2','pca3','pca4','pca5'];
colorBy='self';
neuronList=wbListIDs(wbstruct);
transitionKeyNeuron=neuronList{1};
transitionNumber=10;
keyFrame=1000;

transitionTypeNames={'lo2rise','rise2hi','rise2fall','hi2fall','fall2lo','fall2rise','any2rise','any2fall','l2r+h2f','any'};

transitionTypesSet={1,2,3,4,5,6,[1 6 8],[3 4],[1 3],1:8};
transitionTypes=1;



%% setup figures and UI

currentXLim=[tv(1) tv(end)];
handles.figs_main(1)=figure('Position',[10 0 1200 1000],'Name','wbPlotTraces');
handles.fig_aux=figure('Position',[0 1100 800 200],'MenuBar','none','Name','wbPlotTraces Control Panel');

sf_x=0.5;
ts=.02;lf=.1;tb=.1*sf_x;
handles.dataFolderName=uicontrol('Style','popupmenu','Units','normalized','Position',[0.1 0.93 0.6*sf_x 0.05],'String',dataFolderList,'Value',find(strcmp(upper(dataFolderList),upper(currentDataFolder))),'ForegroundColor','b','Callback', @(s,e) dataFolderNameMenuCallback);
handles.sortedbyText=annotation('textbox',[0.1 0.87-ts 0.6*sf_x 0.05],'String','sorted by','EdgeColor','none','Color','k'); 
handles.sortMethodMenu = uicontrol('Style','popupmenu','Units','normalized','Value',1,'String',sortTypes,'Position',[0.1 0.8-ts 0.6*sf_x 0.03],'Callback',@(s,e) sortMethodMenuCallback);
handles.normalizeCheckbox = uicontrol('Style','checkbox','Units','normalized','Value',normalizeFlag,'String','normalize (rms)','Position',[0.1 0.6-ts 0.6*sf_x 0.1],'Callback',@(s,e) normalizeCheckboxCallback);
%handles.showSmoothedCheckbox = uicontrol('Style','checkbox','Units','normalized','Value',normalizeFlag,'String','show smoothed','Position',[0.1+3*tb 0.6-ts 0.6*sf_x 0.1],'Callback',@(s,e) showSmoothedCheckboxCallback);

%handles.hideExclusionsCheckbox = uicontrol('Style','checkbox','Units','normalized','Value',hideExclusionsFlag,'String','hide exclusions','Position',[0.1 0.6-ts-lf 0.6 0.1],'Callback',@(s,e) hideExclusionsCheckboxCallback);
handles.hideUnlabeledCheckbox = uicontrol('Style','checkbox','Units','normalized','Value',hideUnlabeledFlag,'String','hide unlabeled','Position',[0.1 0.6-ts-2*lf 0.3*sf_x 0.1],'Callback',@(s,e) hideUnlabeledCheckboxCallback);
handles.colorStateCheckbox = uicontrol('Style','checkbox','Units','normalized','Value',colorStateFlag,'String','color states by','Position',[0.1 0.6-ts-3*lf 0.3*sf_x 0.1],'Callback',@(s,e) colorStateCheckboxCallback);


%handles.posThreshEditbox = uicontrol('Style','edit','Units','normalized','String',num2str(posThresh),'Position',[0.1+2*tb 0.6-ts-3*lf 0.1*sf_x 0.1],'Callback',@(s,e) posThreshEditCallback);
%handles.negThreshEditbox = uicontrol('Style','edit','Units','normalized','String',num2str(negThresh),'Position',[0.1+3*tb 0.6-ts-3*lf 0.1*sf_x 0.1],'Callback',@(s,e) negThreshEditCallback);
%handles.threshTypeMenu = uicontrol('Style','popupmenu','Units','normalized','Value',2,'String',threshTypeList,'Position',[0.1+4*tb 0.6-ts-3*lf 0.18*sf_x 0.1],'Callback',@(s,e) threshTypeMenuCallback);
handles.colorByMenu = uicontrol('Style','popupmenu','Units','normalized','Value',1,'String',colorByList,'Position',[0.1+2.5*tb 0.6-ts-3*lf 0.2*sf_x 0.1],'Callback',@(s,e) colorByMenuCallback);

%annotation('textbox',[0.1+1.75*tb 0.6-ts-3.5*lf 0.6*sf_x 0.05],'String','+Thresh..-Thresh...threshType..........color by','EdgeColor','none');


%%activation ordering params
handles.transitionNumberEditbox = uicontrol('Style','edit','Units','normalized','String',num2str(transitionNumber),'Position',[0.1+12*tb 0.6-ts-3*lf 0.1*sf_x 0.1],'Callback',@(s,e) transitionNumberEditCallback);
handles.transitionKeyNeuronMenu = uicontrol('Style','popupmenu','Units','normalized','Value',1,'String',neuronList,'Position',[0.1+13*tb 0.6-ts-3*lf 0.2*sf_x 0.1],'Callback',@(s,e) transitionKeyNeuronMenuCallback);
handles.transitionTypesMenu = uicontrol('Style','popupmenu','Units','normalized','Value',1,'String',transitionTypeNames,'Position',[0.1+15*tb 0.6-ts-3*lf 0.2*sf_x 0.1],'Callback',@(s,e) transitionTypesMenuCallback);
annotation('textbox',[0.1+12*tb 0.6-ts-3.5*lf 0.6*sf_x 0.05],'String','Trans# ... Key Neuron ...  threshTypes','EdgeColor','none');


%%secondary plot
handles.secondaryPlotText=annotation('textbox',[0.1+7*tb 0.87-ts 0.6*sf_x 0.05],'String','secondary plot','EdgeColor','none','Color','k'); 
handles.secondaryPlotMenu = uicontrol('Style','popupmenu','Units','normalized','Value',1,'String',secondaryPlotTypes,'Position',[0.1+7*tb 0.8-ts 0.4*sf_x 0.03],'Callback',@(s,e) SecondaryPlotMenuCallback);
handles.secondaryPlotParam1 = uicontrol('Style','edit','Units','normalized','Value',1,'String',num2str(secondaryPlotParam1),'Position',[0.1+7*tb 0.8-ts-2*lf 0.2*sf_x 0.1],'Visible','off','Callback',@(s,e) SecondaryPlotParam1Callback);
handles.secondaryPlotParam1Label = uicontrol('Style','text','Units','normalized','Value',1,'String',secondaryPlotParam1Labels{1},'Position',[0.1+9*tb 0.8-ts-2*lf 0.2*sf_x 0.1],'Visible','off');

handles.secondaryPlotParam2 = uicontrol('Style','popupmenu','Units','normalized','Value',1,'String',secondaryPlotParam2Values{1},'Position',[0.1+7*tb 0.8-ts-3*lf 0.2*sf_x 0.1],'Visible','off','Callback',@(s,e) SecondaryPlotParam2Callback);
handles.secondaryPlotParam2Label = uicontrol('Style','text','Units','normalized','Value',1,'String',secondaryPlotParam2Labels{1},'Position',[0.1+9*tb 0.8-ts-3*lf 0.2*sf_x 0.1],'Visible','off');


%%Zoom
px=.15;py=.1;
uicontrol('Style','text','Units','normalized','Position',[px+.01 py 0.11*sf_x 0.1],'String','zoom');
handles.zoomInButton = uicontrol('Style','pushbutton','Units','normalized','Position',[px+.06 py 0.05*sf_x 0.1],'String','+','Callback',@(s,e) ZoomInCallback);
handles.zoomOutButton = uicontrol('Style','pushbutton','Units','normalized','Position',[px-.02 py 0.05*sf_x 0.1],'String','-','Callback',@(s,e) ZoomOutCallback);
%handles.zoomPopupMenu = uicontrol('Style','popupmenu','Units','normalized','Value',currentZPlane,'String',ZoomLabels,'Position',[px py-.02 0.06 0.04],'Callback',@(s,e) ZPopupMenuCallback);


%create traces main window
figure(handles.figs_main(1));



sortMethodMenuCallback; %includes DrawPlots;



%% CALLBACKS AND SUBFUNCTIONS

    function transitionNumberEditCallback
        
        newVal=get(gcbo,'String');
        
        if ~isempty (str2num(newVal)) %numerical field
            transitionNumber=str2num(newVal);
        else %non-numerical field
            transitionNumber=str2num(newVal);
            
        end
        sortMethodMenuCallback;
    end

    function transitionKeyNeuronMenuCallback
        
        transitionKeyNeuron=neuronList{get(handles.transitionKeyNeuronMenu,'Value')};
        sortMethodMenuCallback;
        
    end

    function transitionTypesMenuCallback
        
        transitionTypes=transitionTypesSet{get(handles.transitionTypesMenu,'Value')};
        sortMethodMenuCallback;
        
    end

    function PrepWBstruct
        
        %load wbstruct
        if isempty(wbstruct)
            [wbstruct, wbstructfilename]=wbload([],false);
        end

        %add extra exclusionList or empty list if nec.
        if options.extraExclusionList
            exclusionList=[wbstruct.exclusionList wbstruct.extraExclusionList];
        elseif isfield(wbstruct,'exclusionList');
            exclusionList=wbstruct.exclusionList;
        else
            exclusionList=[];
        end
        

        tracesall_unsorted=wbstruct.(options.fieldName);
        
        traces_unsorted=wbGetTraces(wbstruct);
        numTraces=size(traces_unsorted,2);

        if ~isfield(wbstruct,'simple')
            wbMakeSimpleStruct;
            [wbstruct, wbstructfilename]=wbload([],false);
        end
        
        wbstruct=wbAddStateParams(wbstructfilename);
        
        %generate simple.deriv  based tracecoloring
        %[traceColoring_unsorted, transitionListCellArray]=wbFourStateTraceAnalysis(wbstruct,posThresh,negThresh,threshType);
        [traceColoring_unsorted, transitionListCellArray]=wbFourStateTraceAnalysis(wbstruct,'useSaved');
        
        traceColoring=traceColoring_unsorted;
        %need to add range
                
        %post processing function
        if ~isempty(options.postProcessFunction)
            disp('post processing function.');
            tracesall_unsorted=options.postProcessFunction(tracesall_unsorted);
            
        end
        
        %range clip
        if ~isempty(options.range)
            traces_unsorted=traces_unsorted(options.range,:);
            tv=wbstruct.tv(options.range);
        else
            tv=wbstruct.tv;
        end

        traces=traces_unsorted;
        

        
        %add numerical labels
        for nn=1:wbstruct.simple.nn
            traceLabels_unsorted{nn}=num2str(nn);
        end

        
        %initialize tags
        traceLabelTag_unsorted=false(1,wbstruct.simple.nn);
%        traceExclusionTag_unsorted=false(1,wbstruct.simple.nn);
%        traceExclusionTag_unsorted(exclusionList)=true;
%        traceExclusionTag=traceExclusionTag_unsorted;

        %write in known IDs
        if options.showIDs
            
%             if isfield(wbstruct,'ID')
%                 for k=1:length(wbstruct.ID)
% 
%                     if ~isempty(wbstruct.ID{k})
%                         traceLabels_unsorted{k}=wbstruct.ID{k}{1};
%                         traceLabelTag_unsorted(k)=true;
%                     else
%                         traceLabelTag_unsorted(k)=false;
%                     end
%                 end
%             end

            for nn=1:wbstruct.simple.nn;

                    if ~isempty(wbstruct.simple.ID{nn})
                        traceLabels_unsorted{nn}=wbstruct.simple.ID{nn}{1};
                        traceLabelTag_unsorted(nn)=true;
                                
                    end
            end

        end
        
        traceLabels=traceLabels_unsorted;
        traceLabelTag=traceLabelTag_unsorted;

        
    end

    function dataFolderNameMenuCallback
        currentDataFolder=dataFolderList{get(gcbo,'Value')};
        cd(['..' filesep currentDataFolder]);
        wbstruct=[];
        PrepWBstruct;
        sortMethodMenuCallback;
    end

    function SecondaryPlotMenuCallback
        
        thisMenuVal=get(handles.secondaryPlotMenu,'Value');

        secondaryPlotType=secondaryPlotTypes{thisMenuVal};
        secondaryPlotisColorableFlag=secondaryPlotisColorableFlags(thisMenuVal);
        secondaryPlotXUnit=secondaryPlotXUnits{thisMenuVal};
        secondaryPlotXLabel=secondaryPlotXLabels{thisMenuVal};
        secondaryPlotLegend=secondaryPlotLegends{thisMenuVal};
        
        if strcmp(secondaryPlotType,'none')
            secondaryPlotFlag=false;
            set(handles.secondaryPlotParam1,'Visible','off');
            set(handles.secondaryPlotParam1Label,'Visible','off');
            set(handles.secondaryPlotParam2Label,'Visible','off');
            set(handles.secondaryPlotParam2,'Visible','off');

        else
            secondaryPlotParam1=secondaryPlotParam1DefaultValues(thisMenuVal);
            secondaryPlotParam2=secondaryPlotParam2Values{thisMenuVal}{1}; %first subcell is default

            ComputeSecondaryPlotData;
            secondaryPlotFlag=true;

            set(handles.secondaryPlotParam1Label,'String',secondaryPlotParam1Labels{thisMenuVal});
            if ~strcmp(secondaryPlotParam1Labels{thisMenuVal},'null')
                set(handles.secondaryPlotParam1,'Visible','on');
                set(handles.secondaryPlotParam1Label,'Visible','on');
            else
                set(handles.secondaryPlotParam1,'Visible','off');
                set(handles.secondaryPlotParam1Label,'Visible','off');
            end
            set(handles.secondaryPlotParam1,'String',num2str(secondaryPlotParam1));
            
            if ~strcmp(secondaryPlotParam2Labels{thisMenuVal},'null')
                set(handles.secondaryPlotParam2,'Visible','on'); 
                set(handles.secondaryPlotParam2Label,'Visible','on'); 
            else
                set(handles.secondaryPlotParam2,'Visible','off'); 
                set(handles.secondaryPlotParam2Label,'Visible','off'); 
            end
            set(handles.secondaryPlotParam2Label,'String',secondaryPlotParam2Labels{thisMenuVal});       
            set(handles.secondaryPlotParam2,'String',secondaryPlotParam2Values{thisMenuVal});
            set(handles.secondaryPlotParam2,'Value',1);
        end
        
        DrawPlots;

        
    end

    function SecondaryPlotParam1Callback
        
        secondaryPlotParam1=str2num(get(gcbo,'String'));
        ComputeSecondaryPlotData;   
        DrawPlots;
        
    end

    function SecondaryPlotParam2Callback
        
        valueList=get(gcbo,'String');
        secondaryPlotParam2=valueList{get(gcbo,'Value')};
        ComputeSecondaryPlotData;  
        DrawPlots;
        
    end

    function updateTraceVisibleTags
              
        traceVisibleTag=true(1,size(traces,2));
        
        if hideUnlabeledFlag           
            traceVisibleTag(~traceLabelTag)=false;
        end
        
    end

    function ComputeSecondaryPlotData  %only compute for visible traces
        
        handles.dialog=figure('Position',[500 500 300 100],'MenuBar','none');
        
        annotation('textbox',[0.25 0.5 0.1 0.1],'String',['Computing ' secondaryPlotType '...'],'EdgeColor','none','HorizontalAlignment','center','FontSize',12);
        drawnow;
        clear('secondaryPlotData')
        
        
        secondaryPlotData.traces=nan(size(traces));
        
        if strcmp(secondaryPlotType,'autocorrelation')        
            
            thisRng=GetSecondaryPlotRange;

            [tempMat,thistvRel,~]=autocorr(traces(thisRng(1):thisRng(2),traceVisibleTag),secondaryPlotParam1,1/wbstruct.metadata.fps,false);
   
            secondaryPlotData.tv=thistvRel; %wbstruct.tv(thisRng(1));

            secondaryPlotData.traces=nan(size(tempMat,1),size(traces,2));
            secondaryPlotData.traces(:,traceVisibleTag)=tempMat;
            
            if strcmp(secondaryPlotParam2,'dual')
                
                [tempMat2,thistvRel2,~]=autocorr(traces(thisRng(3):thisRng(4),traceVisibleTag),secondaryPlotParam1,1/wbstruct.metadata.fps,false);
   
                secondaryPlotData.tv2=thistvRel2; %+wbstruct.tv(thisRng(1));

                secondaryPlotData.traces2=nan(size(tempMat2,1),size(traces,2));
                secondaryPlotData.traces2(:,traceVisibleTag)=tempMat2;
   
            end

        elseif strcmp(secondaryPlotType,'PC')   
            
            wbp=load('Quant/wbpcastruct.mat');
            pcNum=secondaryPlotParam1;
            if pcNum==0 
                pcNum=1;
            end
            
            tempMat=repmat(detrend(cumsum(wbp.pcs(:,pcNum)),'linear'),1,size(traces(:,traceVisibleTag),2));
            secondaryPlotData.traces=nan(size(tempMat,1),size(traces,2));
            secondaryPlotData.traces(:,traceVisibleTag)=tempMat;
            secondaryPlotData.range=wbp.options.range(1):wbp.options.range(end);
            secondaryPlotData.tv=tv(secondaryPlotData.range);

        elseif strcmp(secondaryPlotType,'derivOld')   
            
            smoothingWindow=secondaryPlotParam1;
            secondaryPlotData.traces(:,traceVisibleTag)=deriv(fastsmooth(traces(:,traceVisibleTag),smoothingWindow,3,1));
            
            secondaryPlotData.tv=tv;
            secondaryPlotData.range=1:size(secondaryPlotData.traces,1);


        elseif strcmp(secondaryPlotType,'derivRegularized')   
            
            %alpha=secondaryPlotParam1;
            
            if ~isfield(wbstruct.simple,'derivs')
                wbstruct=wbload([],'false');
            end
            
            derivTraces=wbstruct.simple.derivs.traces;
            
            size(derivTraces)
            size(secondaryPlotData.traces)
            
            secondaryPlotData.traces(:,traceVisibleTag)=derivTraces(:,traceVisibleTag);
            %secondaryPlotData.traces(:,traceVisibleTag)=derivTraces;
            
            secondaryPlotData.tv=tv;
            
            if strcmp(secondaryPlotParam2,'show')

                secondaryPlotData.traces2=nan(size(traces));
                secondaryPlotData.traces2(:,traceVisibleTag)=deriv(traces(:,traceVisibleTag));
                secondaryPlotData.tv2=tv;
            
            end
            
            secondaryPlotData.range=1:size(secondaryPlotData.traces,1);

            
        elseif strcmp(secondaryPlotType,'powerspectrum')   
            
            thisRng=GetSecondaryPlotRange;
            
            secondaryPlotData.traces=nan(size(traces(thisRng(1):thisRng(2),:)));

            secondaryPlotData.traces(:,traceVisibleTag)=wbEvalTraces(traces(thisRng(1):thisRng(2),traceVisibleTag),'powerspectrum',[],[]);
      
            secondaryPlotData.traces=secondaryPlotData.traces(1:floor(end/2),:);
            dt=1/wbstruct.fps;
            df=1/(length(thisRng(1):thisRng(2))*dt);
            timevec=0:dt:((length(thisRng(1):thisRng(2))-1)*dt);
            freqvec=0:df:(1/dt);
            freqvec=freqvec(1:(end-1));
            secondaryPlotData.tv=log10(freqvec(1:floor(end/2)))';
            
            if strcmp(secondaryPlotParam2,'dual')
                
                secondaryPlotData.traces2=nan(size(traces(thisRng(3):thisRng(4),:)));

                secondaryPlotData.traces2(:,traceVisibleTag)=wbEvalTraces(traces(thisRng(3):thisRng(4),traceVisibleTag),'powerspectrum',[],[]);

                secondaryPlotData.traces2=secondaryPlotData.traces2(1:floor(end/2),:);
                dt=1/wbstruct.fps;
                df=1/(length(thisRng(3):thisRng(4))*dt);
                timevec=0:dt:((length(thisRng(3):thisRng(4))-1)*dt);
                freqvec=0:df:(1/dt);
                freqvec=freqvec(1:(end-1));
                secondaryPlotData.tv2=log10(freqvec(1:floor(end/2)))';
                
                
            end
        else
            
            secondaryPlotData.traces(:,traceVisibleTag)=traces(:,traceVisibleTag);
            secondaryPlotData.tv=tv;
        end
        
        close(handles.dialog);
    end

    function rng_out=GetSecondaryPlotRange
        
        if strcmp(secondaryPlotParam2,'pre')
            rng_out=[1 floor(length(wbstruct.tv)/2)];
        elseif strcmp(secondaryPlotParam2,'post')
            rng_out=[floor(length(wbstruct.tv)/2)+1 length(wbstruct.tv)];
        elseif strcmp(secondaryPlotParam2,'dual')
            rng_out=[1 floor(length(wbstruct.tv)/2) floor(length(wbstruct.tv)/2)+1 length(wbstruct.tv)];
        elseif strcmp(secondaryPlotParam2,'1/3 v 2/3')
            rng_out=[1 floor(length(wbstruct.tv)/3) floor(length(wbstruct.tv)/3)+1 floor(2*length(wbstruct.tv)/3)];    
            
        else %'full'
            rng_out=[1 length(wbstruct.tv)];
        end
            
    end

    function ZoomInCallback
        if strcmp(sortMethod,'transition')
            center=tv(keyFrame);
        else
            center=mean(currentXLim);
        end
        currentXLim=round([center-(center-currentXLim(1))/2 center+(currentXLim(2)-center)/2]);       
        DrawPlots;

    end

    function ZoomOutCallback
        center=mean(currentXLim);
        currentXLim=round([center-(center-currentXLim(1))*2 center+(currentXLim(2)-center)*2]);
        currentXLim(1)=max([tv(1) currentXLim(1)]);
        currentXLim(2)=min([tv(end) currentXLim(2)]);
        DrawPlots;
    end

%     function negThreshEditCallback
%    
%         newVal=get(gcbo,'String');
%         
%         if ~isempty (str2num(newVal)) %numerical field
%             negThresh=str2num(newVal);
%         end
%         
%         [traceColoring_unsorted,transitionListCellArray]=wbFourStateTraceAnalysis(wbstruct,posThresh,negThresh,threshType);
% 
%         sortMethodMenuCallback;
%         
%     end

%     function posThreshEditCallback
%    
%         newVal=get(gcbo,'String');
%         
%         if ~isempty (str2num(newVal)) %numerical field
%             posThresh=str2num(newVal);
%         end
%         
%         [traceColoring_unsorted,transitionListCellArray]=wbFourStateTraceAnalysis(wbstruct,posThresh,negThresh,threshType);
% 
%         sortMethodMenuCallback;
%         
%     end

%     function threshTypeMenuCallback
%         
%         newVal=get(gcbo,'Value');
% 
%         threshType=threshTypeList(newVal);
%         [traceColoring_unsorted,transitionListCellArray]=wbFourStateTraceAnalysis(wbstruct,posThresh,negThresh,threshType);
% 
%         sortMethodMenuCallback;
%         
%     end

    function hideUnlabeledCheckboxCallback
        
            hideUnlabeledFlag=get(gcbo,'Value');
            
            sortMethodMenuCallback; %includes DrawPlots;
    
    end

    function hideExclusionsCheckboxCallback
        
            hideExclusionsFlag=get(gcbo,'Value');
            sortMethodMenuCallback; %includes DrawPlots;  
        
    end

    function colorStateCheckboxCallback
        
            colorStateFlag=get(gcbo,'Value');
            sortMethodMenuCallback; %includes DrawPlots;
    
    end

%     function showSmoothedCheckboxCallback
%         
%             showSmoothedFlag=get(gcbo,'Value');
%             DrawPlots;
%     
%     end

    function normalizeCheckboxCallback
        
            normalizeFlag=get(gcbo,'Value');
            DrawPlots;
    
    end

    function sortMethodMenuCallback

        sortMethod=sortTypes{get(handles.sortMethodMenu,'Value')};
        if strcmp(sortMethod,'transition')
            %[traceColoring, transitionListCellArray]=wbFourStateTraceAnalysis(wbstruct,posThresh,negThresh,threshType);
            [traceColoring, transitionListCellArray]=wbFourStateTraceAnalysis(wbstruct,'useSaved');

            [~,~, keyNeuronIndex] = wbgettrace(transitionKeyNeuron,wbstruct);
            transitionKeyFrame=transitionListCellArray{keyNeuronIndex,end}(min([transitionNumber length(transitionListCellArray{keyNeuronIndex,end})]));
            [traces_all, sortOrder, sortVal,keyFrame,reducedSortOrder]=wbSortTraces(tracesall_unsorted,sortMethod,exclusionList,{posThresh,negThresh,threshType,transitionKeyFrame,transitionTypes});
        else
            [traces_all, sortOrder, sortVal,keyFrame,reducedSortOrder]=wbSortTraces(tracesall_unsorted,sortMethod,exclusionList);
        end
        
        
        traces=tracesall_unsorted;
        traces(:,exclusionList)=[];
        traces=traces(:,reducedSortOrder);
        
    %     if ~isempty(options.fieldName2)
    %         traces2=traces2_unsorted,sortOrder);
    %     end

        traceColoring=traceColoring_unsorted(:,reducedSortOrder);

        traceLabels=traceLabels_unsorted( reducedSortOrder );
        
        traceLabelTag=traceLabelTag_unsorted(reducedSortOrder);   
        %traceExclusionTag=traceExclusionTag_unsorted(reducedSortOrder);

        updateTraceVisibleTags;

        ComputeSecondaryPlotData;
        DrawPlots;

    end

    function colorByMenuCallback
        
        colorBy=colorByList{get(handles.colorByMenu,'Value')};

        DrawPlots;
        
    end

    function mouseDownCallback(hObject,~)
    
    %launch wbcheck if a trace is clicked, or exclude a neuron if a label
    %is clicked
    
    thisNeuron=get(get(hObject,'YLabel'),'String')
    [~,~,simpleNum]=wbgettrace(thisNeuron,wbstruct);
    
    if isfield(handles,'traceStateAnnotator') && ishghandle(handles.traceStateAnnotator)
        thisOptions.figureHandle=handles.traceStateAnnotator;
        wbTraceStateAnnotator([],thisOptions,simpleNum);
    else
        handles.traceStateAnnotator=wbTraceStateAnnotator([],[],simpleNum);
    end
end

    function DrawPlots      
        
        if secondaryPlotFlag
            numColumns=2;
        else
            numColumns=1;
        end
        
        if options.scrollBar
            %get old scroll value if it exists
            scroll_hndl = findall(handles.figs_main(1),'Type','uicontrol','Tag','scroll');
            if ~isempty(scroll_hndl)
                old_scroll_value=get(scroll_hndl,'Value');
            else
                old_scroll_value=1;
            end
        end
        
        figure(handles.figs_main(1));
        
        
        
        clf;
        np=1;
           
        if currentXLim(2)-currentXLim(1)<50
            markerType='.';
            markerSize=12;
        else
            markerType='none';
            markerSize=12;
        end
                
        if colorStateFlag && ~strcmp(colorBy,'self') %get ColorBy other neuron coloringIndex
             
             [~,~, coloringIndex] = wbgettrace(colorBy,wbstruct);
             coloringIndex=find(reducedSortOrder==coloringIndex,1);
        end
        
        
        for n=1:numTraces         
                     
            if colorStateFlag
                %if self-colored then each colorindex will be separate
                if strcmp(colorBy,'self') 
                    coloringIndex=n;
                end  
            end
            
            
            if ~hideUnlabeledFlag || traceLabelTag(n) 
                % && (~hideExclusionsFlag || traceExclusionTag(n) )

                if options.scrollBar
                    ax(np)=scrollsubplot(10,numColumns,(np-1)*(numColumns)+1  ); %3rd party function
                else
                    figNum=ceil(np/options.maxRowsPerPage);
                    if np>1 && (figNum > ceil((np-1)/options.maxRowsPerPage) )
                        if figNum<=length(handles.figs_main) && ishghandle(handles.figs_main(figNum))
                            figure(handles.figs_main(figNum))
                        else
                            handles.figs_main(figNum)=figure('Position',[10*(figNum+1) 0 1200 1000],'Name',['wbPlotTraces' num2str(figNum)]);
                        end
                    end
                    ax(np)=subplot(options.maxRowsPerPage,numColumns,(mod(np-1,options.maxRowsPerPage)+1-1)*(numColumns)+1);
                end
                %smoothed trace
%                 if showSmoothedFlag
%                     if normalizeFlag
%                         plot(tv,normalize(fastsmooth(traces(:,n),riseSmoothingWindow,3,1),3),'Color','g','HitTest','off');
%                     else
%                         plot(tv,fastsmooth(traces(:,n),riseSmoothingWindow,3,1),'Color','g','HitTest','off');
%                     end
%                     set(p,'HitTest','off');
%                 end
                
                hold off;
                                
                xlim([tv(1) tv(end)]);
                hline;
                hold on;
                
                %main trace   
                if colorStateFlag
                                   
                    for i=1:4  %four states to color
                        
                        coloredData=zero2nan( double( traceColoring(:,coloringIndex)==i )  );
                 
                        if normalizeFlag
                            handles.overlayPlot(np,i)=plot(tv,coloredData.*normalize(traces(:,n),3),'Color',stateColors{i},'LineWidth',1,'Marker',markerType,'MarkerSize',markerSize,'HitTest','off');
                        else
                            handles.overlayPlot(np,i)=plot(tv,coloredData.*traces(:,n),'Color',stateColors{i},'LineWidth',1,'Marker',markerType,'MarkerSize',markerSize,'HitTest','off');
                        end
                        set(handles.overlayPlot(np,i),'HitTest','off');
                        
                        hold on;
                    end
                    
                elseif normalizeFlag
                    plot(tv,normalize(traces(:,n),3),'Marker',markerType,'MarkerSize',markerSize,'HitTest','off');
                else
                    plot(tv,traces(:,n),'Marker',markerType,'MarkerSize',markerSize,'HitTest','off');
                end
                
                SmartTimeAxis([tv(1) tv(end)]);

                
                if drawTransitionLinesFlag && strcmp(sortMethod,'transition') && ~isempty(sortVal)
                    hold on;
                    
                    vline(tv(-sortVal(reducedSortOrder(n))),'r');
                    vline(tv(keyFrame));
                end
                

                box off;
                
                ylabel(traceLabels{n},'Rotation',0);      
                if strcmp(secondaryPlotXUnits,'s')
                    SmartTimeAxis(currentXLim);
                end
                

                %secondary plot
                hold off;
                if secondaryPlotFlag 
                     if options.scrollBar
                        ax2(np)=scrollsubplot(10,numColumns,(np-1)*(numColumns)+2  ); %3rd party function
                     else
                        ax2(np)=subplot(options.maxRowsPerPage,numColumns,(mod(np-1,options.maxRowsPerPage)+1-1)*(numColumns)+2);
                     end
                     if isfield(secondaryPlotData,'traces2')
                         
                         plot(secondaryPlotData.tv2,secondaryPlotData.traces2(:,n),'r');
                         hold on;
                     end
                     
                     plot(secondaryPlotData.tv,secondaryPlotData.traces(:,n));
                     hold on;
                     
                     if isfield(secondaryPlotData,'traces2')
                        legend(secondaryPlotLegend);
                     end
                     
                     if strcmp(secondaryPlotXUnit,'s')
                        SmartTimeAxis([secondaryPlotData.tv(1) secondaryPlotData.tv(end)]);

                     elseif strcmp(secondaryPlotXUnit,'loghz')
                       % ylim([-3 max(secondaryPlotData.traces(:,n))]);
                        set(gca,'XTick',log10(1./[240 120 90 60 40 20 10 4 2 1]));
                        set(gca,'XTickLabel',[240 120 90 60 40 20 10 4 2 1]);
                        xlim([log10(1/240)   log10(1/1)]);
                     end
                     
                     
                     
%                      if colorStateFlag && secondaryPlotisColorableFlag
%                         handles.overlayPlot(np)=plot(secondaryPlotData.tv,zero2nan(traceDerivIsPositive(traces(:,n),riseThresh,riseSmoothingWindow,'abs')).*secondaryPlotData.traces(:,n),'r','LineWidth',1.5,'Marker',markerType,'MarkerSize',markerSize);
%                      end 
                     
                    if colorStateFlag && secondaryPlotisColorableFlag

                        for i=1:4  %four states to color

                            %get coloredData based on colorBy menu value
                            if strcmp(colorBy,'self') 
                                coloringIndex=n;
                            else
                                [~,~, coloringIndex] = wbgettrace(colorBy,wbstruct);

                                coloringIndex=find(reducedSortOrder==coloringIndex,1);

                            end   
                            coloredData=zero2nan( double( traceColoring(:,coloringIndex)==i )  );

                            handles.overlayPlot(np,i)=plot(secondaryPlotData.tv,coloredData(secondaryPlotData.range).*secondaryPlotData.traces(:,n),'Color',stateColors{i},'LineWidth',1,'Marker',markerType,'MarkerSize',markerSize);
             
                        end
                    end

                        %set ylim
                        if isfield(secondaryPlotData,'traces2')
                             ylim([min([secondaryPlotData.traces(:,n) ; secondaryPlotData.traces2(:,n)]) ...
                             max([secondaryPlotData.traces(:,n) ; secondaryPlotData.traces2(:,n)])]);
                        else
                             ylim([min(secondaryPlotData.traces(:,n)) max(secondaryPlotData.traces(:,n))]);
                        end
                    

                end   
             
                %%%%%
                %listen for mouseDown events in all subplots
                set(ax(np), 'ButtonDownFcn',@mouseDownCallback);
                %%%%%
                
                
                np=np+1;
                               
            end


            
        end

        %x axis labels at the bottom and titles at the top
        if exist('ax','var')
            set(get(ax(np-1),'XLabel'),'String','time (s)') 
            set(get(ax(1),'Title'),'String',wbstruct.displayname);
        end
        
        if secondaryPlotFlag
            set(get(ax2(np-1),'XLabel'),'String',secondaryPlotXLabel)
            set(get(ax2(1),'Title'),'String',secondaryPlotType);
        end
              
        if options.scrollBar
            ReScroll(old_scroll_value);
        end
    end

end %main
