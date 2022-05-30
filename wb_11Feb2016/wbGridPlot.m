function traces=wbGridPlot(wbstruct,options)
%function traces=wbGridPlot(wbstruct,options)
%works with wba2
%Saul Kato
%plot all traces in a grid
%20131030 added ability to plot subsets of traces from different htstructs


%% preliminaries

if nargin<2 || ~isfield(options,'doubleWideFlag')
    options.doubleWideFlag=false; 
end

if nargin<2 || ~isfield(options,'normalizeFlag')
    options.normalizeFlag=false; 
end

if nargin<2 || ~isfield(options,'normalizeMethod')
    options.normalizeMethod=2;  %rms 
end

if nargin<2 || ~isfield(options,'derivFlag')
    options.derivFlag=false; 
end

if nargin<2 || ~isfield(options,'extraExclusionList')
    options.extraExclusionList=[]; 
end

if (nargin<2) || ~isfield(options,'lowRes')
    options.lowRes=true;
end

if (nargin<2) || ~isfield(options,'showIDs')
    options.showIDs=true;
end

if (nargin<2) || ~isfield(options,'displayTarget')
    options.displayTarget='presentation';
end

if (nargin<2) || ~isfield(options,'invertColor')
    options.invertColor=false;
end


if (nargin<2) || ~isfield(options,'wbcheckHandle')  %pass a handle from wbcheck
    options.wbcheckHandle=0;
end

if (nargin<2) || ~isfield(options,'hideExclusions')
    options.hideExclusions=false;
end

if (nargin<2) || ~isfield(options,'showSimpleNumbers')
    options.showSimpleNumbers=false;
end


if (nargin<2) || ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF';
end


secondaryTraceTypes={'deltaFOverFNoBackSub','deltaFOverF_bc'};

if (nargin<2) || ~isfield(options,'fieldName2')
    options.fieldName2=secondaryTraceTypes;  %leave as [] to skip plotting second trace overlay
end

if (nargin<2) || ~isfield(options,'fieldName2SimpleFlag')  %is this field name a simple field or a normal field
    options.fieldName2SimpleFlag=[false true]; 
end

if (nargin<1) 
    wbstruct=[];
end

if isempty(wbstruct)
    [wbstruct, options.wbstructFileName]=wbload([],false);
end

if ~isstruct(wbstruct) && ~iscell(wbstruct)  %if wbstruct is just traces
    disp('plotting raw traces');
    traces=wbstruct;
    clear wbstruct;
    wbstruct{1}.ref=traces;
    options.fieldName='ref';
    wbstruct{1}.trialname='ref';
    wbstruct{1}.displayname='ref';
    wbstruct{1}.fps=5;
    wbstruct{1}.tv=mtv(wbstruct{1}.ref(:,1),1/wbstruct{1}.fps);
    
elseif iscell(wbstruct)  %this is a cell array of wbstructs
    
    disp('plotting from multiple wbstructs.')
    if ~isfield(options,'subsets')
        disp('no options.subsets specified. will plot ALL neurons from all trials.');
        for i=1:length(wbstruct)
            options.subsets{i}=1:size(wbstruct{i}.f_parents,2);  %ALL neurons
        end       
    end
    
else
    tempht=wbstruct;
    clear wbstruct;
    wbstruct{1}=tempht;
    if ~isfield(options,'subsets')
        options.subsets{1}=1:size(wbstruct{1}.f_parents,2);
    end
end

%hide exclusions if simple struct exists
if isfield(wbstruct{1},'simple')
    options.hideExclusions=true;
end
    
    
if nargin<2 || ~isfield(options,'saveFlag')
    options.saveFlag=false;
end

if nargin<2 || ~isfield(options,'saveDir')
    if exist([pwd '/Quant'],'dir')==7
        options.saveDir=([pwd '/Quant']);
    else
        options.saveDir=pwd;
    end
end

if nargin<2 || ~isfield(options,'range')
    options.range=0;
end

if nargin<2 || ~isfield(options,'useExistingFigureHandle')
    options.useExistingFigureHandle=0;
end

if nargin<2 || ~isfield(options,'scalefactor')
    options.scalefactor=1;
end

if nargin<2 || ~isfield(options,'smoothing')
    options.smoothing=1;
end

if nargin<2 || ~isfield(options,'trialcolors')
    for i=1:length(wbstruct)
        if options.invertColor
            options.trialcolors{i}=MyColor('y');
        else
            options.trialcolors{i}=MyColor('b');
        end
%        options.trialcolors{i}=MyColor(i,1+length(wbstruct));
    end
end

if nargin<2 || ~isfield(options,'names')
    for i=1:length(wbstruct)
        options.names{i}=repcell({''},size(wbstruct{i}.f_parents,2));
    end
end

for i=1:length(wbstruct)
    TeXColor{i}=['\color[rgb]{' num2str(options.trialcolors{i}) '}'];
end


%parse custom sort order

if nargin<2 || ~isfield(options,'customSortOrder')  %overrides sortMethod
    for i=1:length(wbstruct)
        options.customSortOrder{i}=[];
    end
end

if nargin<2 || ~isfield(options,'customSortOrderName')
    options.customSortOrderName='custom';
end

sortTypes=[wbSortTraces('get') options.customSortOrderName];  %get sortTypes from wbSortTraces function

%% load traces and give labels and markup
neurons_allsubsets=[];
neurons_allsubsets_trial=[];
neurons_allsubsets_color=[];
neurons_allsubsets_name={};

for i=1:length(wbstruct)
    neurons_allsubsets=[neurons_allsubsets options.subsets{i}];
    neurons_allsubsets_trial=[neurons_allsubsets_trial i*ones(1,length(options.subsets{i}))];
    neurons_allsubsets_color=[neurons_allsubsets_color; repmat(options.trialcolors{i},length(options.subsets{i}),1)];
    neurons_allsubsets_name=[neurons_allsubsets_name options.names{i}];
end

if nargin<2 || ~isfield(options,'sortMethod')  
        options.sortMethod='position';
end


%%GLOBALS

    %choose grid layout depending on number of neurons
    dims.num=[400 300 240 200 160 120 90 40 10 1]; 
    dims.x=[5 5 5 4 4 3 3 2 1];
    dims.y=[8 6 5 5 4 4 3 2 1];
    
    flagStr=[];
    
    hideExclusionsFlag=options.hideExclusions;  

    dataFolderList=listfolders([pwd filesep '..']);
    pwdtemp=pwd;
    currentDataFolder=pwdtemp(find(pwdtemp==filesep,1,'last')+1:end);

    figureName='wbGridPlot';
    tittext=[];
    options.plotStep=3;
    traces=[];traces_unsorted=[];
    traces2=[];traces2_unsorted=[];
    tracesD=[];tracesD_unsorted=[];
     
    sortOrder=[];
    simpleSortOrder=[];
    sortMethod=[];
    thisColor=[];
    thisColor2=[];
    showSimpleNumbersFlag=options.showSimpleNumbers;
    normalizeFlag=options.normalizeFlag;
    normalizeMethod=options.normalizeMethod;
    derivFlag=options.derivFlag;
    
    rngvec=[];rngstr=[];
        
    if isfield(options,'fieldName2') && ~isempty(options.fieldName2)  
        showSecondaryTracesFlag=true;
    else
        showSecondaryTracesFlag=false;
    end
    
    secondaryTraceTypeNum=1;
    
    traceLabels=[];
    traceLabels_unsorted=[];
    traceLabelsSimple=[];
    traceLabelsSimple_unsorted=[];
    traceExclusionTag=[]; 
    traceExclusionTag_unsorted=[];
    
PrepWBstruct;

dimtype=find(nn>dims.num,1,'first')-1;

if nn>dims.num
    disp('>400 neurons.  only 400 will be displayed.');
    dimtype=1;
end
    
    
%%SETUP FIGURE

setupFigure;

%%GUI OBJECTS


handles.dataFolderName=uicontrol('Style','popupmenu','Units','normalized','Position',[0.01 0.98 0.08 0.02],'String',dataFolderList,'Value',find(strcmp(upper(dataFolderList),upper(currentDataFolder))),'ForegroundColor','k','Callback', @(s,e) dataFolderNameMenuCallback);
handles.titleText= uicontrol('Style','text','Units','Normalized','Position',[0.09 0.98 0.22 0.02],'String',tittext,'ForegroundColor','b');

handles.saveButton = uicontrol('Style','pushbutton','Units','normalized','String','save PDF','Position',[0.57 0.98 0.05 0.02],'Callback',@(s,e) saveButtonCallback);
handles.hideExclusionsCheckbox = uicontrol('Style','checkbox','Units','normalized','Value',hideExclusionsFlag,'String','hideExclusions','Position',[0.62 0.98 0.08 0.02],'Callback',@(s,e) hideExclusionsCheckboxCallback);
handles.showSimpleNumbersCheckbox = uicontrol('Style','checkbox','Units','normalized','Value',showSimpleNumbersFlag,'String','simple #s','Position',[0.68 0.98 0.08 0.02],'Visible','on','Callback',@(s,e) showSimpleNumbersCheckboxCallback);

handles.launchIEButton = uicontrol('Style','pushbutton','Units','normalized','String','I.E.','Position',[0.73 0.98 0.015 0.02],'Callback',@(s,e) launchIEButtonCallback);

handles.normalizeCheckbox = uicontrol('Style','checkbox','Units','normalized','Value',normalizeFlag,'String','norm.','Position',[0.31 0.98 0.03 0.02],'ForegroundColor','k','Callback',@(s,e) normalizeCallback);
handles.normalizeMethodPopup = uicontrol('Style','popup','Units','normalized','Value',options.normalizeMethod,'String',{'rms','peak','maxsnr'},'Position',[0.34 0.98 0.05 0.02],'ForegroundColor','k','Callback',@(s,e) normalizeMethodCallback);

handles.derivCheckbox = uicontrol('Style','checkbox','Units','normalized','Value',derivFlag,'String','deriv','Position',[0.39 0.98 0.05 0.02],'ForegroundColor','k','Callback',@(s,e) derivCallback);


if isfield(options,'fieldName2') && ~isempty(options.fieldName2)
    handles.showSecondaryTracesCheckbox = uicontrol('Style','checkbox','Units','normalized','Value',showSecondaryTracesFlag,'String','2:','Position',[0.42 0.98 0.1 0.02],'ForegroundColor','r','Callback',@(s,e) showSecondaryTracesCheckboxCallback);
end

handles.showSecondaryTracesPopup=uicontrol('Style','popupmenu','Units','normalized','String',secondaryTraceTypes,'Value',secondaryTraceTypeNum,'Position',[0.44 0.98 0.09 0.02],'Callback',@(s,e) showSecondaryTracesPopupCallback);

handles.autoExcludeButton = uicontrol('Style','pushbutton','Units','normalized','String','autohide','Position',[0.53 0.98 0.04 0.02],'ForegroundColor','r','Callback',@(s,e) autoExcludeButtonCallback);
handles.sortMethodMenu = uicontrol('Style','popupmenu','Units','normalized','Value',find(strcmp(options.sortMethod,sortTypes)),'String',sortTypes,'Position',[0.79 0.98 0.15 0.02],'Callback',@(s,e) sortMethodMenuCallback);
handles.sortedbyText=uicontrol('Style','text','Units','Normalized','Position',[0.75 0.98 0.035 0.02],'String','sorted by','ForegroundColor','k'); 

%%SORT DATA AND DRAW PLOTS
sortMethodMenuCallback;
 
%%SAVE FIGURE
if (options.saveFlag) 
    saveButtonCallback;
end

%%END MAIN

%% subfunctions

function setupFigure
    
    %create new figure or use old one
    if options.useExistingFigureHandle ~= 0
        set(0,'CurrentFigure',options.useExistingFigureHandle);
        handles.fig=options.useExistingFigureHandle;
        if options.doubleWideFlag
            handles.fig2=figure('Position',[0 0 1700 1000],'Name',figureName);
        end
    else
        
        handles.fig=figure('Position',[0 0 1700 1000],'Name',figureName);
        if options.doubleWideFlag
            handles.fig2=figure('Position',[0 0 1700 1000],'Name',figureName);
            figure(handles.fig);
        end
        %set background to white
        if options.invertColor           
            whitebg('k'); 
        else
            whitebg('w'); 
        end
    end

    

end

function drawPlots

    if derivFlag
        thisTraces=tracesD{1}*15;
        thisTraces2=tracesD{1}*15;
    else
        thisTraces=traces{1};
        thisTraces2=traces2{1}{secondaryTraceTypeNum};

    end
    
    
    ttotal=size(thisTraces,1)/wbstruct{1}.fps;
    
    numTracesPerSection=10;
    
    validTraces=1:nn;

    if isfield(wbstruct{1},'exclusionList') && hideExclusionsFlag               
        validTraces(logical(traceExclusionTag))=[];
    end
    nnValid=length(validTraces);
      
    if nnValid>dims.num
        dimtype=1;
    else
        dimtype=find(nnValid>dims.num,1,'first')-1;
    end
    
    numSections=dims.x(dimtype)*dims.y(dimtype);
    
    nextTraceToPlot=1;
        
    for sp=1:numSections
        rangeInSection{sp}=nextTraceToPlot:min([nextTraceToPlot+numTracesPerSection-1   ,  nnValid  ]);
        nextTraceToPlot= min([nextTraceToPlot+numTracesPerSection-1   ,  nnValid  ]) +1;
    end
    
    for sp=1:numSections
     
       if options.doubleWideFlag
           if sp<=numSections/2
               
           else
               
           end
           
       else
           
            handles.ax(sp)=subtightplot (dims.x(dimtype),dims.y(dimtype),sp, [0.02 .02], [0.02 0.02], [0.02 0.02]);
       end
       cla;
       hold off;
            
%         k=1;
%         nvec=(1:10)+10*(sp-1);

%         if nn<11
%             nvec=1:nn;
%         end
%         
%         pruned=1:size(neurons_allsubsets,2);
%         if isfield(wbstruct{1},'exclusionList')  && hideExclusionsFlag               
%              pruned(wbstruct{1}.exclusionList)=[];
%         end
%       
        if ~isempty(traces{1})
                                %set range
            thisrngvec=rngvec(1):rngvec(end);

            if options.lowRes
               thisrngvec=thisrngvec(1):options.plotStep:thisrngvec(end);
            end
                       
            if normalizeMethod==3               
                
                
                [~,~,normalizationFactor1( validTraces(rangeInSection{sp})) ]=snrmaximize(traces{1}{secondaryTraceTypeNum}(thisrngvec,validTraces(rangeInSection{sp})));
                [~,~,normalizationFactor2( validTraces(rangeInSection{sp})) ]=snrmaximize(traces2{1}{secondaryTraceTypeNum}(thisrngvec,validTraces(rangeInSection{sp})));
                normalizationFactor1(validTraces(rangeInSection{sp}))=1./normalizationFactor1(validTraces(rangeInSection{sp}));
                normalizationFactor2(validTraces(rangeInSection{sp}))=1./normalizationFactor2(validTraces(rangeInSection{sp}));              
                
            end
            
            for n=1:length(rangeInSection{sp})

                    if normalizeFlag
                        if normalizeMethod==1
                            normalizationFactor1(n)=rms( traces{1}(thisrngvec,validTraces(rangeInSection{sp}(n))) )*5;
                            normalizationFactor2(n)=rms( traces2{1}{secondaryTraceTypeNum}(thisrngvec,validTraces(rangeInSection{sp}(n))) )*5;
                        elseif normalizeMethod==2 %peaknorm
                            normalizationFactor1(n)=max(abs(detrend( traces{1}(thisrngvec,validTraces(rangeInSection{sp}(n))),'linear')))*1;
                            normalizationFactor2(n)=max(abs(detrend( traces2{1}{secondaryTraceTypeNum}(thisrngvec,validTraces(rangeInSection{sp}(n))),'linear' )))*1;
                        end
                    else
                        normalizationFactor1(n)=1;
                        normalizationFactor2(n)=1;
                    end

                    %set colors                                             
    %                if ~ismember(validTraces(rangeInSection{sp}(n)),wbstruct{1}.exclusionList)

                     if ~traceExclusionTag(validTraces(rangeInSection{sp}(n)))
                        thisColor=neurons_allsubsets_color(n,:);
                        thisColor2='r';
                    else %gray out the trace
                        thisColor=[0.8 0.8 0.8];
                        thisColor2=[0.8 0.8 0.8];
                    end            


                    %plot a trace
                    %AXIS ARE FLIPPED SO WE ADD A NEGATIVE SIGN
                    hold on;

                    if exist('traces2','var') && showSecondaryTracesFlag
                        p2=plot(wbstruct{1}.tv(thisrngvec),n-thisTraces2(thisrngvec,validTraces(rangeInSection{sp}(n)))*options.scalefactor/normalizationFactor1(n),'Color',thisColor2);
                        set(p2,'HitTest','off');
                    end
                    p=plot(wbstruct{1}.tv(thisrngvec),n-thisTraces(thisrngvec,validTraces(rangeInSection{sp}(n)))*options.scalefactor/normalizationFactor2(n),'Color',thisColor);
                    set(p,'HitTest','off');
                    hold on;

            end

            xlim([rngvec(1) rngvec(end)]/wbstruct{1}.fps);
            ylim([0 1+numTracesPerSection]);
            set(gca,'YDir','reverse');
            set(gca,'YTick',1:length(rangeInSection{sp})); 

            if showSimpleNumbersFlag
                
                set(gca,'YTickLabel',traceLabelsSimple(rangeInSection{sp}));
            else
                set(gca,'YTickLabel',traceLabels(validTraces(rangeInSection{sp})));

            end
            
            if strcmp(options.displayTarget,'presentation');
                 set(gca,'XMinorTick','off');
                 set(gca,'XTick',0:30:ttotal);
                 xtl={};
                 for i=0:60:60*floor(ttotal/60);
                     xtl=[xtl {num2str(i)},{''}];
                 end
                 set(gca,'XTickLabel',xtl);
                grid off;
                stimTextFlag=false;
            else
                set(gca,'XMinorTick','on');
                set(gca,'XTick',0:10:ttotal);
                grid on;
                xtl={};
                for i=0:60:60*floor(ttotal/60);
                    xtl=[xtl {num2str(i)},{''},{''},{''},{''},{''}];
                end
                set(gca,'XTickLabel',xtl);
                stimTextFlag=true;

            end
            box off;

            %%%%%
            %listen for mouseDown events in all subplots
            set(handles.ax(sp), 'ButtonDownFcn',@mouseDownCallback);
            %%%%%
    
            %plot stimulus

        %   wbplotstimulus(wbstruct,stimTextFlag,[1 0 0]); %this should work but it
        %   doesn't. plot context?

            if isfield(wbstruct{1},'stimulus') && ~isempty(wbstruct{1}.stimulus)
                if isfield(wbstruct{1}.stimulus,'ch')
                    for thisswitch=1:length(wbstruct{1}.stimulus.ch(1).switchtimes)
                       vline(wbstruct{1}.stimulus.ch(1).switchtimes(thisswitch));
                       numconclevels=length(wbstruct{1}.stimulus.ch(1).conc);
                       thisconcval=wbstruct{1}.stimulus.ch(1).conc(1+mod(wbstruct{1}.stimulus.ch(1).initialstate+thisswitch-1, numconclevels));
                       if stimTextFlag
                         text(wbstruct{1}.stimulus.ch(1).switchtimes(thisswitch),0.2,['  ' num2str(thisconcval) ' ' wbstruct{1}.stimulus.ch(1).concunits ' ' wbstruct{1}.stimulus.ch(1).identity],'Color',[0.5 0.5 0.5],'FontSize',12);
                       end

                    end
                else  %for stimulus with no channel info
                    for thisswitch=1:length(wbstruct{1}.stimulus.switchtimes)
                       vline(wbstruct{1}.stimulus.switchtimes(thisswitch));
                       numconclevels=length(wbstruct{1}.stimulus.conc);
                       thisconcval=wbstruct{1}.stimulus.conc(1+mod(wbstruct{1}.stimulus.initialstate+thisswitch-1, numconclevels));
                       if stimTextFlag
                           text(wbstruct{1}.stimulus.switchtimes(thisswitch),0.2,['  ' num2str(thisconcval) ' ' wbstruct{1}.stimulus.concunits ' ' wbstruct{1}.stimulus.identity],'Color',[0.5 0.5 0.5],'FontSize',12);
                       end
                    end
                end
            end

        end
    
    end

ylabel('\DeltaF/F_0');
xlabel('time (s)');


end
 
function PrepWBstruct
    
    if isempty(wbstruct)
        [wbstruct{1}, options.wbstructFileName]=wbload([],false);
    end
    
    if length(wbstruct)>1
        nn=length(neurons_allsubsets);
    else
        nn=wbstruct{1}.nn;
    end
    
    for i=1:length(wbstruct)
        traces_unsorted{i}=wbstruct{i}.(options.fieldName);

        if ~isempty(options.fieldName2)
            
            if ~iscell(options.fieldName2)
                options.fieldName2={options.fieldName2};
            end
            
            for i2=1:numel(options.fieldName2)
                
                if options.fieldName2SimpleFlag(i2)
                    
                    traces2_unsorted{i}{i2}=zeros(size(traces_unsorted{i}));
                    if isfield(wbstruct{i},'simple') && isfield(wbstruct{i}.simple,'derivs') 
                        traces2_unsorted{i}{i2}(:,wbstruct{i}.simple.nOrig)=wbstruct{i}.simple.(options.fieldName2{i2});
                    end

                else
                    
                    traces2_unsorted{i}{i2}=wbstruct{i}.(options.fieldName2{i2});
                    
                end
                
            end
            
            
            
            
            
        end
        
        tracesD_unsorted{i}=zeros(size(traces_unsorted{i}));
        if isfield(wbstruct{i},'simple') && isfield(wbstruct{i}.simple,'derivs') 
            tracesD_unsorted{i}(:,wbstruct{i}.simple.nOrig)=wbstruct{i}.simple.derivs.traces;
        end
        

        
        
        
        
    end

    for j=1:nn
        traceLabels_unsorted{j}=num2str(j);
    end

    if isfield(wbstruct{1},'simple')
        for j=1:wbstruct{1}.simple.nn
            traceLabelsSimple_unsorted{j}=num2str(j);
        end
    end

    %write in known IDs
    if options.showIDs
        if isfield(wbstruct{1},'ID')
            for k=1:length(wbstruct{1}.ID)

                if ~isempty(wbstruct{1}.ID{k}) && ~isempty(wbstruct{1}.ID{k}{1})

                    traceLabels_unsorted{k}=wbstruct{1}.ID{k}{1};
                end
            end
        end

        if isfield(wbstruct{1},'simple')
            if isfield(wbstruct{1}.simple,'ID')
                for k=1:length(wbstruct{1}.simple.ID)

                    if ~isempty(wbstruct{1}.simple.ID{k}) && ~isempty(wbstruct{1}.simple.ID{k}{1})

                        traceLabelsSimple_unsorted{k}=wbstruct{1}.simple.ID{k}{1};
                    end
                end


            end
        end

    end

    traceExclusionTag_unsorted=zeros(1,nn);
    traceExclusionTag_unsorted(wbstruct{1}.exclusionList)=1;
    traceExclusionTag_unsorted(options.extraExclusionList)=1;
    
    traceLabels=traceLabels_unsorted;
    traceLabelsSimple=traceLabelsSimple_unsorted;
    traceExclusionTag=traceExclusionTag_unsorted; 

    %set range and rangestr
    if options.range>0
        rngvec=options.range(1):options.range(2);
        rngstr=['[' num2str(options.range(1)) '-' num2str(options.range(2)) ']'];
    else
        rngvec=1:size(traces_unsorted{1},1);
        rngstr='';
    end
    
    %make title text
    if length(wbstruct)>1

        tittext='';
        for i=1:length(wbstruct)
            %tittext=[tittext   TeXColor{i} wbstruct{i}.displayname];
            tittext=[tittext ' ' wbMakeShortTrialname(wbstruct{i}.trialname)];
        end

    else
        tittext=wbstruct{i}.trialname;
    end
    
end

%% CALLBACKS

function dataFolderNameMenuCallback
    currentDataFolder=dataFolderList{get(gcbo,'Value')};
    cd(['..' filesep currentDataFolder]);
    if exist([pwd '/Quant'],'dir')==7
        options.saveDir=([pwd '/Quant']);
    else
        options.saveDir=pwd;
    end
    
    wbstruct=[];
    PrepWBstruct;
    set(handles.titleText,'String',tittext);
    sortMethodMenuCallback;
    

end

function launchIEButtonCallback
    %options.wbInteractiveExcludeHandle;
    handles.wbInteractiveExclude=wbInteractiveExclude(wbstruct{1},options.wbstructFileName,handles);
    
end

function autoExcludeButtonCallback
    
    disp('excluding')
    
    if ~isfield(wbstruct{1},'exclusionList')      
        wbstruct{1}.exclusionList=[];
    end
      
    thisRMS=rms(traces{1});
    
    for n=1:nn
        if ( sum(isnan(traces{1}(:,n)))>0 && ~ismember(n,wbstruct{1}.exclusionList)) || thisRMS(n)>0.9
              wbstruct{1}.exclusionList=[wbstruct{1}.exclusionList n];
              
        end
    end
    
    wbstruct{1}.exclusionList=unique(wbstruct{1}.exclusionList);
        
    if isfield(options,'wbstructFileName')
        exclusionList=wbstruct{1}.exclusionList;
        save(options.wbstructFileName,'exclusionList','-append');
    end
    
    traceExclusionTag_unsorted=zeros(1,nn);
    traceExclusionTag_unsorted(wbstruct{1}.exclusionList)=1;
    traceExclusionTag_unsorted(options.extraExclusionList)=1;
    traceLabels=traceLabels_unsorted( sortOrder{1}  );
    traceLabelsSimple=traceLabels_unsorted(simpleSortOrder{1});
    traceExclusionTag=traceExclusionTag_unsorted(sortOrder{1});
        
size(traceExclusionTag)
    
    drawPlots;
    
end

function saveButtonCallback
    
    if options.lowRes
        rngstr2=[rngstr 'lowres'];
    end
    
    flagStr=[];
    
    if derivFlag
        flagStr=[flagStr '-D'];
    end
    
    if normalizeFlag
        if normalizeMethod==1
            flagStr=[flagStr '-Nrms'];
        else
            flagStr=[flagStr '-Npeak'];
        end
    end
    
    wbMakeShortTrialname(wbstruct{1}.trialname);
    
    if length(wbstruct)==1
        hideGUI;
        export_fig([options.saveDir filesep 'GridPlot-'  wbMakeShortTrialname(wbstruct{1}.trialname) '-' sortMethod flagStr '-' rngstr2 '.pdf'],'-transparent','-painters'); 
        showGUI;
    else
        hideGUI;
        export_fig([options.saveDir filesep 'GridPlot-multitrial' '-' sortMethod '-' rngstr2 '.pdf'],'-transparent'); 
        showGUI;
    end
    
    
end

function hideGUI

    set(handles.saveButton,'Visible','off');
    set(handles.titleText,'Visible','off');
    set(handles.hideExclusionsCheckbox,'Visible','off');
    set(handles.showSimpleNumbersCheckbox,'Visible','off');
    set(handles.normalizeCheckbox,'Visible','off');
    set(handles.autoExcludeButton,'Visible','off');
    set(handles.dataFolderName,'Visible','off');
    handles.dataFolderNameStroked=annotation('textbox',[0.03 0.96 0.1 0.04],'String',strrep(tittext,'_','\_'),'EdgeColor','none','Color','k'); 
    set(handles.sortMethodMenu,'Visible','off');    
    set(handles.sortedbyText,'Visible','off')
    handles.sortbyTextStroked=annotation('textbox', [0.75 0.98 0.1 0.02], 'String',['sorted by ' strrep(sortMethod,'_','\_')],'EdgeColor','none','Color','k');
    set(handles.showSecondaryTracesCheckbox,'Visible','off');
    set(handles.launchIEButton,'Visible','off');
    set(handles.derivCheckbox,'Visible','off');
    set(handles.normalizeMethodPopup,'Visible','off');
    
    handles.flagsTextStroked=annotation('textbox', [0.35 0.98 0.1 0.02], 'String',['flags: ' flagStr],'EdgeColor','none','Color','k');

end

function showGUI
    
    set(handles.titleText,'Visible','on');
    set(handles.saveButton,'Visible','on');
    set(handles.hideExclusionsCheckbox,'Visible','on');
    set(handles.normalizeCheckbox,'Visible','on');
    set(handles.autoExcludeButton,'Visible','on');
    set(handles.dataFolderName,'Visible','on');
    set(handles.dataFolderNameStroked,'Visible','off');
    if get(handles.hideExclusionsCheckbox,'Value')
        set(handles.showSimpleNumbersCheckbox,'Visible','on');
    end
    set(handles.sortMethodMenu,'Visible','on');
    set(handles.sortedbyText,'Visible','on')
    set(handles.sortbyTextStroked,'Visible','off');
    set(handles.showSecondaryTracesCheckbox,'Visible','on');
    set(handles.launchIEButton,'Visible','on');
    set(handles.derivCheckbox,'Visible','on');
    set(handles.normalizeMethodPopup,'Visible','on');
    
    set(handles.flagsTextStroked,'Visible','off');
end

function normalizeCallback
    
    normalizeFlag=get(gcbo,'Value');
    drawPlots;
    
end

function normalizeMethodCallback
    
    normalizeMethod=get(gcbo,'Value');
    drawPlots;
    
end

function derivCallback
    
    derivFlag=get(gcbo,'Value');
    drawPlots;
    
end



function showSecondaryTracesCheckboxCallback
    
    showSecondaryTracesFlag=get(gcbo,'Value');
    drawPlots;
    
end
   


function showSecondaryTracesPopupCallback
    
    secondaryTraceTypeNum=get(gcbo,'Value');
    drawPlots;
    
end

function hideExclusionsCheckboxCallback
       
%disp('hideExclusionsCheckboxCallback')
    
    hideExclusionsFlag=get(gcbo,'Value');

    showSimpleNumbersFlag=hideExclusionsFlag;
    set(handles.showSimpleNumbersCheckbox,'Value',showSimpleNumbersFlag);
    if hideExclusionsFlag
        set(handles.showSimpleNumbersCheckbox,'Visible','on');
    else
        set(handles.showSimpleNumbersCheckbox,'Visible','off');
    end
    sortMethodMenuCallback; %includes drawPlots;
    
end

function showSimpleNumbersCheckboxCallback
    
    showSimpleNumbersFlag=get(gcbo,'Value');
    sortMethodMenuCallback; %includes drawPlots;
    
end

function sortMethodMenuCallback
    
    sortMethod=sortTypes{get(handles.sortMethodMenu,'Value')};
    
    for j=1:length(wbstruct)
        
        
        SToptions.refWBStruct=wbstruct{j};
        
        if hideExclusionsFlag

            
            [traces{j},sortOrder{j},~,~, simpleSortOrder{j}]=wbSortTraces(traces_unsorted{j},sortMethod,wbstruct{1}.exclusionList,[],SToptions);

        else
            
            [traces{j},sortOrder{j},~,~,simpleSortOrder{j}]=wbSortTraces(traces_unsorted{j},sortMethod,[],[],SToptions);
            
        end
        
 
        if ~isempty(sortOrder{j})
        
            if ~isempty(options.fieldName2)
                for i2=1:numel(options.fieldName2)
                    traces2{j}{i2}=traces2_unsorted{j}{i2}(:,sortOrder{j});
                end
            end
            
            tracesD{j}=tracesD_unsorted{j}(:,sortOrder{j});
            
            traceLabels=traceLabels_unsorted(sortOrder{j});
            
            if hideExclusionsFlag
                try
                     traceLabelsSimple=traceLabelsSimple_unsorted(simpleSortOrder{j});
                catch me
                     disp('wbstruct .simple discrepancy.  run wbMakeSimpleStruct and retry.');
                     return;
                end
            end
          
            
            traceExclusionTag=traceExclusionTag_unsorted(sortOrder{j});

        end
        
    end

    drawPlots;
    %updatePlots;
    
end

function mouseDownCallback(hObject,~)
    
    %launch wbcheck if a trace is clicked, or exclude a neuron if a label
    %is clicked
    
    plotNums=get(hObject,'YTickLabel')
    basePlotNum=str2num(plotNums{1});
    
    %get basePlotNum if it is string labeled
    if isempty(basePlotNum)
        [~,basePlotNum]=wbgettrace(plotNums{1},wbstruct{1});
    end
    
    pos=get(hObject,'CurrentPoint'); %pos is 2x3??

    plotnum=round(pos(1,2));
    
disp(['You clicked Y:',num2str(plotnum)]);
disp(['You clicked plot number: ' num2str(plotnum+basePlotNum-1)]);
    
    thisNeuron=sortOrder{1}(plotnum+basePlotNum-1);
    
    xpos=round(pos(1,1));
    %disp(['You clicked X: ',num2str(xpos)]);
    if xpos<0  %this is a click in the axes so exclude neuron
        
        if isfield(wbstruct{1},'exclusionList') && ~isempty(wbstruct{1}.exclusionList)
            if ~ismember(thisNeuron,wbstruct{1}.exclusionList) %exclude
                disp(['adding ' num2str(thisNeuron) ' to exclusion list.']);
                %%wbstruct{1}.exclusionList=[wbstruct{1}.exclusionList(1:find(wbstruct{1}.exclusionList<thisNeuron,1,'last')) thisNeuron wbstruct{1}.exclusionList(1+find(wbstruct{1}.exclusionList<thisNeuron,1,'last'):end)]; %ninja insert code
                wbstruct{1}.exclusionList=[wbstruct{1}.exclusionList thisNeuron];
                wbstruct{1}.exclusionList=sort(wbstruct{1}.exclusionList);
            else %unexclude

disp(['removing ' num2str(thisNeuron) ' from exclusion list.']);
                wbstruct{1}.exclusionList(wbstruct{1}.exclusionList==thisNeuron)=[];
            end
        else
             disp('did not find exclusionList.  creating one.');
             wbstruct{1}.exclusionList=thisNeuron;
        end     
        
        traceExclusionTag_unsorted=zeros(1,nn);
        traceExclusionTag_unsorted(wbstruct{1}.exclusionList)=1;
        traceExclusionTag_unsorted(options.extraExclusionList)=1;
        traceLabels=traceLabels_unsorted( sortOrder{1}  );    
        traceLabelsSimple=traceLabelsSimple_unsorted( simpleSortOrder{1} );
        
        traceExclusionTag=traceExclusionTag_unsorted(sortOrder{1});
        
        
        if isfield(options,'wbstructFileName')
            exclusionList=wbstruct{1}.exclusionList;
            save(options.wbstructFileName,'exclusionList','-append');
        end
        
        drawPlots;
        
    else %this is a click on the graph so launch wbCheck

        handles.wbcheckHandle=options.wbcheckHandle;
        wbCheck(thisNeuron,[],handles);
        %set(handles.hSlider,'Value',(pos(1)-0.5)/ds.numFrames); 
    end
    
end

end 