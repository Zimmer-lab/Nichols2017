function wbgridplot2(wbstruct,options)
%function wbgridplot2(wbstruct,options)
%works with wba2
%Saul Kato
%plot all traces in a grid
%
%some, but not all options:
% .lowRes=true      %decimate traces to reduce plot size and complexity
% .showIDs=false    %replace neuron numbers with neuron IDs where they exist
% .displayTarget='presentation'  %change certain graphic settings for
% .invertColor=false  %black background for that slick look
%


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


if (nargin<2) || ~isfield(options,'wbcheckHandle')  %pass a handle from wbcheck2
    options.wbcheckHandle=0;
end


if (nargin<2) || ~isfield(options,'hideExclusions')
    options.hideExclusions=0;
end


if (nargin<2) || ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF';
end

if (nargin<2) || ~isfield(options,'fieldName2')
    options.fieldName2=[]; %'deltaFOverFNoBackSub';
end

if (nargin<1) || isempty(wbstruct)
    if exist('Quant/wbstruct.mat','file')
        load('Quant/wbstruct.mat');
    elseif exist('wbstruct.mat','file')
        load('wbstruct.mat');
    else
        disp('no wbstruct.mat found. quitting.');
        return;
    end
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


if nargin<2 || ~isfield(options,'saveDir')
    if exist([pwd '/Quant'],'dir')==7
        options.saveDir=([pwd '/Quant']);
    else
        options.saveDir=pwd;
    end
end

if nargin<2 || ~isfield(options,'saveFlag')
    options.saveFlag=1;
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
            options.trialcolors{i}=color('y');
        else
            options.trialcolors{i}=color('b');
        end
%        options.trialcolors{i}=color(i,1+length(wbstruct));
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

%nn=size(traces,2);
nn=length(neurons_allsubsets);


%parse custom sort order

if nargin<2 || ~isfield(options,'customSortOrder')  %overrides sortMethod
    for i=1:length(wbstruct)
        options.customSortOrder{i}=[];
    end
end

if nargin<2 || ~isfield(options,'customSortOrderName')
    options.customSortOrderName='custom';
end

sortTypes={'position','power','detrendedpower','corrcluster','pcaloading1','pcaloading2','pcaloading7','pcamaxloading',options.customSortOrderName};


%load traces and give labels and markup

if nargin<2 || ~isfield(options,'sortMethod')  
        options.sortMethod='position';
end

for i=1:length(wbstruct)
    traces_unsorted{i}=getfield(wbstruct{i},options.fieldName);
        
    if ~isempty(options.fieldName2)
        traces2_unsorted{i}=getfield(wbstruct{i},options.fieldName2);
    end
    

end

for j=1:nn
         traceLabels_unsorted{j}=num2str(j);
end


%write in known IDs
if options.showIDs
    if isfield(wbstruct{1},'ID')
        for k=1:length(wbstruct{1}.ID)

            if ~isempty(wbstruct{1}.ID{k})

                traceLabels_unsorted{k}=wbstruct{1}.ID{k}{1};
            end
        end
    end
end



traceExclusionTag_unsorted=zeros(1,nn);
traceExclusionTag_unsorted(wbstruct{1}.exclusionList)=1;







%choose grid layout depending on number of neurons
dims.num=[300 240 200 160 120 90 40 10 1]; 
dims.x=[5 5 4 4 3 3 2 1];
dims.y=[6 5 5 4 4 3 2 1];

dimtype=find(nn>dims.num,1,'first')-1;

if nn>dims.num
    disp('>300 neurons.  only 300 will be displayed.');
    dimtype=1;
end

if options.range>0
    rngvec=options.range(1):options.range(2);
    rngstr=['[' num2str(options.range(1)) '-' num2str(options.range(2)) ']'];
else
    rngvec=1:size(traces_unsorted{1},1);
    rngstr='';
end

%make title text
tittext='';
for i=1:length(wbstruct)
    %tittext=[tittext   TeXColor{i} wbstruct{i}.displayname];
    tittext=[tittext ' ' wbstruct{i}.displayname];
end


%% GLOBALS
    traceLabels=[];
    traceExclusionTag=[];
    traces=[];
    traces2=[];
    hideExclusionsFlag=options.hideExclusions;
    sortOrder=[];

%% SETUP FIGURE

setupFigure;

%% GUI OBJECTS

handles.saveButton = uicontrol('Style','pushbutton','Units','normalized','String','save PDF','Position',[0.58 0.98 0.05 0.02],'Callback',@(s,e) saveButtonCallback);

handles.hideExclusionsCheckbox = uicontrol('Style','checkbox','Units','normalized','Value',hideExclusionsFlag,'String','hideExclusions','Position',[0.65 0.98 0.08 0.02],'Callback',@(s,e) hideExclusionsCheckboxCallback);
handles.sortMethodMenu = uicontrol('Style','popupmenu','Units','normalized','Value',1,'String',sortTypes,'Position',[0.79 0.96 0.15 0.04],'Callback',@(s,e) sortMethodMenuCallback);
annotation('textbox',[0.75 0.96 0.1 0.04],'String','sorted by','EdgeColor','none'); 
annotation('textbox',[0.03 0.96 0.3 0.04],'String',tittext,'EdgeColor','none','Color','b');


%% SORT DATA
sortMethodMenuCallback;
 
%% DRAW PLOTS
drawPlots;


%% SAVE FIGURE

if (options.saveFlag) 

    saveButtonCallback;
    
end

%%END MAIN

%% nested functions

function setupFigure
    
    %create new figure or use old one
    if options.useExistingFigureHandle ~= 0
        set(0,'CurrentFigure',options.useExistingFigureHandle);
        handles.fig=options.useExistingFigureHandle;
    else
        handles.fig=figure('Position',[0 0 1700 1000]);
        %set background to white
        if options.invertColor
            
            whitebg('k'); 
        else
            whitebg('w'); 
        end
    end

    

end

function drawPlots
    
    ttotal=size(traces{1},1)/wbstruct{1}.fps;
    
    numTracesPerSection=10;
    
    validTraces=1:nn;

    if isfield(wbstruct{1},'exclusionList')  && hideExclusionsFlag               
        validTraces(logical(traceExclusionTag))=[];
    end
    nnValid=length(validTraces);
      
    dimtype=find(nnValid>dims.num,1,'first')-1;
   
    numSections=dims.x(dimtype)*dims.y(dimtype);
    
    nextTraceToPlot=1;
        
    for sp=1:numSections
        rangeInSection{sp}=nextTraceToPlot:min([nextTraceToPlot+numTracesPerSection-1   ,  nnValid  ]);
        nextTraceToPlot= min([nextTraceToPlot+numTracesPerSection-1   ,  nnValid  ]) +1;
    end
    
  
    for sp=1:numSections

        handles.ax(sp)=subtightplot (dims.x(dimtype),dims.y(dimtype),sp, [0.02 .02], [0.02 0.02], [0.02 0.02]);
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
        for n=1:length(rangeInSection{sp})
              
%               %set range
                thisrngvec=rngvec(1):rngvec(end);
%                   

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
                if options.lowRes
                    lowResRngVec=thisrngvec(1):3:thisrngvec(end);
                    p=plot(wbstruct{1}.tv(lowResRngVec),n-traces{1}(lowResRngVec,validTraces(rangeInSection{sp}(n)))*options.scalefactor,'Color',thisColor);
                else
                    p=plot(wbstruct{1}.tv(thisrngvec),n-traces{1}(thisrngvec,validTraces(rangeInSection{sp}(n)))*options.scalefactor,'Color',thisColor);
                end
                set(p,'HitTest','off');
                hold on;

        end
          
%         for n=nvec;
%             if n<=length(pruned)
% 
%                 
%                 thisrngvec=rngvec(1):min([rngvec(end) length(traces{neurons_allsubsets_trial(pruned(n))}(rngvec,sortOrder{neurons_allsubsets_trial(pruned(n))}(neurons_allsubsets(pruned(n)))))]);
%                                 
%                 
%                 if isfield(wbstruct{1},'exclusionList')
%                     
%                     
%                         if ~ismember(sortOrder{neurons_allsubsets_trial(pruned(n))}(pruned(n)),wbstruct{1}.exclusionList)
%                             thisColor=neurons_allsubsets_color(pruned(n),:);
%                             thisColor2='r';
%                         else
%                             thisColor=[0.8 0.8 0.8];
%                             thisColor2=[0.8 0.8 0.8];
%                         end
%                     
%                 else
%                     thisColor=neurons_allsubsets_color(pruned(n),:);
%                     thisColor2='r';
%                     wbstruct{1}.exclusionList=[];
%                 end
%                 
%                 if ( ~hideExclusionsFlag || ~ismember(sortOrder{neurons_allsubsets_trial(pruned(n))}(pruned(n)),wbstruct{1}.exclusionList))
%                     
%                 
%                     if exist('traces2','var')
%                         pp=plot(wbstruct{1}.tv(thisrngvec),(min(1+[nn 10])-k)+traces2{neurons_allsubsets_trial(pruned(n))}(thisrngvec,pruned(n))*options.scalefactor,...
%                         'Color',thisColor2);
%                         hold on;
%                         set(pp,'HitTest','off');
%                     end
% 
% 
%                     p=plot(wbstruct{1}.tv(thisrngvec),(min(1+[nn 10])-k)+traces{neurons_allsubsets_trial(pruned(n))}(thisrngvec,pruned(n))*options.scalefactor,...
%                         'Color',thisColor);
% 
%                     set(p,'HitTest','off');
%                 end
%                 
%                 %end
%                 text(rngvec(end)/wbstruct{neurons_allsubsets_trial(n)}.fps, min(1+[nn 10])-k, [neurons_allsubsets_name{n} ' '],...
%                     'VerticalAlignment','bottom','HorizontalAlignment','right','Color',neurons_allsubsets_color(n,:));
%             end
%             hold on;
%             k=k+1;
%         end   
    

         xlim([rngvec(1) rngvec(end)]/wbstruct{1}.fps);
         ylim([0 1+numTracesPerSection]);
         set(gca,'YDir','reverse');
         set(gca,'YTick',1:length(rangeInSection{sp})); 
    
         set(gca,'YTickLabel',traceLabels(validTraces(rangeInSection{sp})));
%         
%         
%         nvec_clipped=nvec(nvec<=size(neurons_allsubsets,2));
%         set(gca,'YTick', 11-length(nvec_clipped) : 10);
%         if length(nvec)==10
%             set(gca,'YTickLabel',(sortOrder{1}(neurons_allsubsets(nvec_clipped(end:-1:1)))));
% 
%         end
    
        if strcmp(options.displayTarget,'presentation');
            set(gca,'XMinorTick','off');
            set(gca,'XTick',0:30:ttotal);
                    xtl=[];
             for i=0:60:60*floor(ttotal/60);
                 xtl=[xtl num2str(i) '||'];
             end
             set(gca,'XTickLabel',xtl);
            grid off;
            stimTextFlag=false;
        else
            set(gca,'XMinorTick','on');
            set(gca,'XTick',0:10:ttotal);
            grid on;
            xtl=[];
            for i=0:60:60*floor(ttotal/60);
                xtl=[xtl num2str(i) '||||||'];
            end
            set(gca,'XTickLabel',xtl);
            stimTextFlag=true;

        end
        box off;

        %%%%%
        %listen for mouseDown events in all subplots
        set(handles.ax(sp), 'ButtonDownFcn',@mouseDownCallback);
        %%%%%
    
        %%
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
    

ylabel('\DeltaF/F_0');
xlabel('time (s)');


end


%% CALLBACKS

function saveButtonCallback
    if options.lowRes
        rngstr=[rngstr '-lowres'];
    end
     if length(wbstruct)==1
        export_fig([options.saveDir '/gridplot-' wbstruct{1}.trialname rngstr '.pdf']); 
    else
        export_fig([options.saveDir '/gridplot-multitrial' rngstr '.pdf']); 
    end
    
    
end

function hideExclusionsCheckboxCallback
    hideExclusionsFlag=get(gcbo,'Value');
    disp(hideExclusionsFlag)
    drawPlots;
end

function sortMethodMenuCallback
    sortMethod=sortTypes{get(handles.sortMethodMenu,'Value')};
    
    for j=1:length(wbstruct)
        [traces{j} sortOrder{j}]=wbsorttraces(traces_unsorted{j},sortMethod);
        

        if ~isempty(options.fieldName2)
            traces2{j}=traces2_unsorted{j}(:,sortOrder{j});
        end
    

    traceLabels=traceLabels_unsorted( sortOrder{1}  );
    traceExclusionTag=traceExclusionTag_unsorted(sortOrder{1});

        
        if ~isempty(options.fieldName2)
            traces2{j}=traces2_unsorted{j}(:,sortOrder{j});
        end
        
        

    end
    drawPlots;
    %updatePlots;
    
end

function mouseDownCallback(hObject,~)
    
    plotNums=get(hObject,'YTickLabel');
    basePlotNum=str2num(plotNums{1});
    pos=get(hObject,'CurrentPoint'); %pos is 2x3??
    plotnum=round(pos(1,2));
    %disp(['You clicked Y:',num2str(plotnum)]);
    %disp(['You clicked plot number: ' num2str(plotnum+basePlotNum-1)]);
    
    handles.wbcheckHandle=options.wbcheckHandle;
    
    
    wbcheck2(sortOrder{1}(plotnum+basePlotNum-1),[],handles);
    %set(handles.hSlider,'Value',(pos(1)-0.5)/ds.numFrames); 
    
end


end 