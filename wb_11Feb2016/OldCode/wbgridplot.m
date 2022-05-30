function wbgridplot(wbstruct,options)
%function wbgridplot(wbstruct,options)
%
%Saul Kato
%plot all traces in a grid
%20131030 added ability to plot subsets of traces from different htstructs


if (nargin<2) || ~isfield(options,'wbcheckHandle')  %pass a handle from wbcheck
    options.wbcheckHandle=0;
end


if (nargin<2) || ~isfield(options,'hideExclusions')
    options.hideExclusions=1;
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
        options.trialcolors{i}=color(i,1+length(wbstruct));
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


%load and sort traces

if nargin<2 || ~isfield(options,'sortMethod')  
        options.sortMethod='position';
end

for i=1:length(wbstruct)
    traces_unsorted{i}=getfield(wbstruct{i},options.fieldName);
        
    if ~isempty(options.fieldName2)
        traces2_unsorted{i}=getfield(wbstruct{i},options.fieldName2);
    end
end


for i=1:length(wbstruct)
    [traces{i} sortOrder{i}]=wbsorttraces(traces_unsorted{i},options.sortMethod);
    
    if ~isempty(options.fieldName2)
        traces2{i}=traces2_unsorted{i}(:,sortOrder{i});
    end
end

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


%% DRAW FIGURE

setupFigure;
drawPlots;


%% GUI OBJECTS

handles.sortMethodMenu = uicontrol('Style','popupmenu','Units','normalized','Value',1,'String',sortTypes,'Position',[0.79 0.96 0.15 0.04],'Callback',@(s,e) sortMethodMenuCallback);
annotation('textbox',[0.75 0.96 0.1 0.04],'String','sorted by','EdgeColor','none'); 
annotation('textbox',[0.03 0.96 0.1 0.04],'String',tittext,'EdgeColor','none','Color','b');


%% SAVE FIGURE

if (options.saveFlag) 
    if length(wbstruct)==1
        save2pdf([options.saveDir '/gridplot-' wbstruct{1}.trialname rngstr '.pdf']); 
    else
        save2pdf([options.saveDir '/gridplot-multitrial' rngstr '.pdf']); 
    end
    
    
end



%% nested functions

function setupFigure
    
    %create new figure or use old one
    if options.useExistingFigureHandle ~= 0
        set(0,'CurrentFigure',options.useExistingFigureHandle);
        handles.fig=options.useExistingFigureHandle;
    else
        handles.fig=figure('Position',[0 0 1200 1000]);
        %set background to white
        whitebg('w');
    end


end

function drawPlots
    
    for sp=1:(dims.x(dimtype)*dims.y(dimtype))

        handles.ax(sp)=subtightplot (dims.x(dimtype),dims.y(dimtype),sp, [0.02 .02], [0.02 0.02], [0.02 0.02]);
        hold off;
        k=1;

        nvec=(1:10)+10*(sp-1);

        if nn<11
            nvec=1:nn;
        end
        for n=nvec;
            if n<=size(neurons_allsubsets,2)
                %plot(htstruct.tv,1*(11-k)+traces(:,n));

                
                thisrngvec=rngvec(1):min([rngvec(end) length(traces{neurons_allsubsets_trial(n)}(rngvec,sortOrder{neurons_allsubsets_trial(n)}(neurons_allsubsets(n))))]);
                                
                
                if isfield(wbstruct{1},'exclusionList')
                    
                        if ~ismember(sortOrder{neurons_allsubsets_trial(n)}(n),wbstruct{1}.exclusionList)
                            thisColor=neurons_allsubsets_color(n,:);
                            thisColor2='r';
                        else
                            thisColor=[0.8 0.8 0.8];
                            thisColor2=[0.8 0.8 0.8];
                        end
                    
                else
                    thisColor=neurons_allsubsets_color(n,:);
                    thisColor2='r';
                    wbstruct{1}.exclusionList=[];
                end
                
                if ( ~options.hideExclusions || ~ismember(sortOrder{neurons_allsubsets_trial(n)}(n),wbstruct{1}.exclusionList))
                    
                
                    if exist('traces2','var')
                        pp=plot(wbstruct{1}.tv(thisrngvec),(min(1+[nn 10])-k)+traces2{neurons_allsubsets_trial(n)}(thisrngvec,n)*options.scalefactor,...
                        'Color',thisColor2);
                        hold on;
                        set(pp,'HitTest','off');
                    end


                    p=plot(wbstruct{1}.tv(thisrngvec),(min(1+[nn 10])-k)+traces{neurons_allsubsets_trial(n)}(thisrngvec,n)*options.scalefactor,...
                        'Color',thisColor);

                    set(p,'HitTest','off');
                end
                
                %end
                text(rngvec(end)/wbstruct{neurons_allsubsets_trial(n)}.fps, min(1+[nn 10])-k, [neurons_allsubsets_name{n} ' '],...
                    'VerticalAlignment','bottom','HorizontalAlignment','right','Color',neurons_allsubsets_color(n,:));
            end
            hold on;
            k=k+1;
    end   
    

    
    ttotal=size(traces{1},1)/wbstruct{1}.fps;
    set(gca,'XTick',0:10:ttotal);
    
    xtl=[];
    for i=0:60:60*floor(ttotal/60);
        xtl=[xtl num2str(i) '||||||'];
    end
    
    set(gca,'XTickLabel',xtl);
    set(gca,'XMinorTick','on');
    xlim([rngvec(1) rngvec(end)]/wbstruct{1}.fps);
    ylim([0 1+min([nn 10])]);

    nvec_clipped=nvec(nvec<=size(neurons_allsubsets,2));
    set(gca,'YTick', 11-length(nvec_clipped) : 10);
    if length(nvec)==10
        set(gca,'YTickLabel',(sortOrder{1}(neurons_allsubsets(nvec_clipped(end:-1:1)))));
        
    end
    grid on;
    box off;
    
    %%%%%
    %listen for mouseDown events in all subplots
    set(handles.ax(sp), 'ButtonDownFcn',@mouseDownCallback);
    
    
    %plot stimulus
    if isfield(wbstruct{1},'stimulus') && ~isempty(wbstruct{1}.stimulus)
        if isfield(wbstruct{1}.stimulus,'ch')
            for thisswitch=1:length(wbstruct{1}.stimulus.ch(1).switchtimes)
               vline(wbstruct{1}.stimulus.ch(1).switchtimes(thisswitch));
               numconclevels=length(wbstruct{1}.stimulus.ch(1).conc);
               thisconcval=wbstruct{1}.stimulus.ch(1).conc(1+mod(wbstruct{1}.stimulus.ch(1).initialstate+thisswitch-1, numconclevels));
               text(wbstruct{1}.stimulus.ch(1).switchtimes(thisswitch),0.2,['  ' num2str(thisconcval) ' ' wbstruct{1}.stimulus.ch(1).concunits ' ' wbstruct{1}.stimulus.ch(1).identity],'Color',[0.5 0.5 0.5],'FontSize',12);


            end
        else  %for stimulus with no channel info
            for thisswitch=1:length(wbstruct{1}.stimulus.switchtimes)
               vline(wbstruct{1}.stimulus.switchtimes(thisswitch));
               numconclevels=length(wbstruct{1}.stimulus.conc);
               thisconcval=wbstruct{1}.stimulus.conc(1+mod(wbstruct{1}.stimulus.initialstate+thisswitch-1, numconclevels));
               text(wbstruct{1}.stimulus.switchtimes(thisswitch),0.2,['  ' num2str(thisconcval) ' ' wbstruct{1}.stimulus.concunits ' ' wbstruct{1}.stimulus.identity],'Color',[0.5 0.5 0.5],'FontSize',12);

            end
        end
    end
    
    
end

ylabel('\DeltaF/F_0');
xlabel('time (s)');



end



%% CALLBACKS
function sortMethodMenuCallback
    sortMethod=sortTypes{get(gcbo,'Value')};
    
    for j=1:length(wbstruct)
        [traces{j} sortOrder{j}]=wbsorttraces(traces_unsorted{j},sortMethod);
        
        if ~isempty(options.fieldName2)
            traces2{j}=traces2_unsorted{j}(:,sortOrder{j});
        end

    end
    drawPlots;
    %updatePlots;
    
end


function mouseDownCallback(hObject,~)
    
    %get(hObject)
    plotNums=get(hObject,'YTickLabel');
    basePlotNum=str2num(plotNums(end,:));
    pos=get(hObject,'CurrentPoint'); %pos is 2x3??
    plotnum=round(11-pos(1,2));
    %disp(['You clicked Y:',num2str(plotnum)]);
    %disp(['You clicked plot number: ' num2str(plotnum+basePlotNum-1)]);
    
    handles.wbcheckHandle=options.wbcheckHandle;
    
    
    wbcheck(sortOrder{1}(plotnum+basePlotNum-1),[],handles);
    %set(handles.hSlider,'Value',(pos(1)-0.5)/ds.numFrames); 
    
end


end 