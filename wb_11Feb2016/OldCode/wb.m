function wb(wbstruct,options)
%%whole brain browser and annotater
%
%based on wbgridplot
%

%set background to white
whitebg('w');

if (nargin<2) || ~isfield(options,'wbcheckHandle')
    options.wbcheckHandle=0;
end


if (nargin<2) || ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF';
end

if (nargin<2) || ~isfield(options,'fieldName2')
    options.fieldName2='deltaFOverFNoBackSub';
end

if nargin<1 || isempty(wbstruct)
    if exist('Quant/wbstruct.mat','file')
        load('Quant/wbstruct.mat');
    elseif exist('wbstruct.mat','file')
        load('wbstruct.mat');
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
    traces{i}=getfield(wbstruct{i},options.fieldName);
    if ~isempty(options.fieldName2)
        traces2{i}=getfield(wbstruct{i},options.fieldName2);
    end
    neurons_allsubsets=[neurons_allsubsets options.subsets{i}];
    neurons_allsubsets_trial=[neurons_allsubsets_trial i*ones(1,length(options.subsets{i}))];
    neurons_allsubsets_color=[neurons_allsubsets_color; repmat(options.trialcolors{i},length(options.subsets{i}),1)];
    neurons_allsubsets_name=[neurons_allsubsets_name options.names{i}];
end


%nn=size(traces,2);
nn=length(neurons_allsubsets);

if nargin<2 || ~isfield(options,'sortOrder')  %overrides sortMethod
    for i=1:length(wbstruct)
        options.sortOrder{i}=1:wbstruct{i}.nn;
    end
end

if nargin<2 || ~isfield(options,'sortOrderName')
    options.sortOrderName='sorted by position';
end

if nargin<2 || ~isfield(options,'sortMethod')  
        options.sortMethod='position';
end



%choose grid layout depending on number of neurons
dims.num=[300 240 200 160 120 90 40 10 1]; 
dims.x=[5 4 4 4 3 3 2 1];
dims.y=[6 5 4 4 4 3 2 1];

dimtype=find(nn>dims.num,1,'first')-1;

if nn>dims.num
    disp('>300 neurons.  only 300 will be displayed.');
    dimtype=1;
end

if options.range>0
    rngvec=options.range(1):options.range(2);
    rngstr=['[' num2str(options.range(1)) '-' num2str(options.range(2)) ']'];
else
    rngvec=1:size(traces{1},1);
    rngstr='';
end

%create new figure or use old one
% if options.useExistingFigureHandle ~= 0
%     disp('dfsdf')
%     set(0,'CurrentFigure',options.useExistingFigureHandle);
% else
%     handles.fig=figure('Position',[0 0 1200 1000]);
% end

figure('Position',[0 0 1200 1000]);

for sp=1:(dims.x(dimtype)*dims.y(dimtype))
    
    handles.ax(sp)=subtightplot (dims.x(dimtype),dims.y(dimtype),sp, [0.02 .02], [0 0.2], [0 0]);
   
    k=1;

    nvec=(1:10)+10*(sp-1);
    
    if nn<11
        nvec=1:nn;
    end
    for n=nvec;
            if n<=size(neurons_allsubsets,2)
                %plot(htstruct.tv,1*(11-k)+traces(:,n));
                thisrngvec=rngvec(1):min([rngvec(end) length(traces{neurons_allsubsets_trial(n)}(rngvec,options.sortOrder{neurons_allsubsets_trial(n)}(neurons_allsubsets(n))))]);
                                
                
                if isfield(wbstruct{1},'exclusionList')
                    if ~ismember(n,wbstruct{1}.exclusionList)
                        thisColor=neurons_allsubsets_color(n,:);
                        thisColor2='r';
                    else
                        thisColor=[0.8 0.8 0.8];
                        thisColor2=[0.8 0.8 0.8];
                    end
                else
                    thisColor=neurons_allsubsets_color(n,:);
                    thisColor2='r';
                end
                
                
                if exist('traces2','var')
                    pp=plot(wbstruct{1}.tv(thisrngvec),(min(1+[nn 10])-k)+traces2{neurons_allsubsets_trial(n)}(thisrngvec,options.sortOrder{neurons_allsubsets_trial(n)}(neurons_allsubsets(n)))*options.scalefactor,...
                    'Color',thisColor2);
                    hold on;
                    set(pp,'HitTest','off');
                end
                

                p=plot(wbstruct{1}.tv(thisrngvec),(min(1+[nn 10])-k)+traces{neurons_allsubsets_trial(n)}(thisrngvec,options.sortOrder{neurons_allsubsets_trial(n)}(neurons_allsubsets(n)))*options.scalefactor,...
                    'Color',thisColor);

                set(p,'HitTest','off');
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
        set(gca,'YTickLabel',neurons_allsubsets(nvec_clipped(end:-1:1)));
    end
    grid on;
    box off;
    
    %%%%%
    %listen for mouseDown events in all subplots
    set(handles.ax(sp), 'ButtonDownFcn',@mouseDownCallback);
    
    
    %plot stimulus
    if isfield(wbstruct{1},'stim') && ~isempty(wbstruct{1}.stim)
        for thisswitch=1:length(wbstruct{1}.stim.ch(1).switchtimes)
           vline(wbstruct{1}.stim.ch(1).switchtimes(thisswitch));
           numconclevels=length(wbstruct{1}.stim.ch(1).conc);
           thisconcval=wbstruct{1}.stim.ch(1).conc(1+mod(wbstruct{1}.stim.ch(1).initialstate+thisswitch-1, numconclevels));
           text(wbstruct{1}.stim.ch(1).switchtimes(thisswitch),0.2,['  ' num2str(thisconcval) ' ' wbstruct{1}.stim.ch(1).concunits ' ' wbstruct{1}.stim.ch(1).identity],'Color',[0.5 0.5 0.5],'FontSize',12);
           

        end
    end
    
    
end

ylabel('\DeltaF/F_0');
xlabel('time (s)');

tittext='';
for i=1:length(wbstruct)
    tittext=[tittext   TeXColor{i} wbstruct{i}.displayname ' '];
end
mtit([tittext ' \color{black}- ' options.sortOrderName]);

tightfig;

if (options.saveFlag) 
    if length(wbstruct)==1
        save2pdf([options.saveDir '/gridplot-' wbstruct{1}.trialname rngstr '.pdf']); 
    else
        save2pdf([options.saveDir '/gridplot-multitrial' rngstr '.pdf']); 
    end
end


%% nested functions

function mouseDownCallback(hObject,~)
    
    %get(hObject)
    plotNums=get(hObject,'YTickLabel');
    basePlotNum=str2num(plotNums(end,:));
    pos=get(hObject,'CurrentPoint'); %pos is 2x3??
    plotnum=round(11-pos(1,2));
    %disp(['You clicked Y:',num2str(plotnum)]);
    %disp(['You clicked plot number: ' num2str(plotnum+basePlotNum-1)]);
    
    handles.wbcheckHandle=options.wbcheckHandle;
    wbcheck(plotnum+basePlotNum-1,[],handles);
    %set(handles.hSlider,'Value',(pos(1)-0.5)/ds.numFrames); 
    
end


end 


%{
options.globalMovieFlag = true;

%
% find a data directory containing a ZMIP folder, or prompt user to find
% one using the file dialog
%

if nargin<1
    maindir=pwd;
else
    maindir=dataDirectory;
end

while ~exist([maindir filesep 'ZMIPs'])
    disp('wb: could not find ZMIPs directory. please find a data directory with a ZMIP subdirectory.');
    maindir = uigetdir('Pick a WB data directory:')
    if isequal(maindir,0)
            disp('wb cancelled.');
            return;
    end
end


%% load ZMIPs
zMIPfnames=dir([maindir filesep 'ZMIPs' filesep '*.tif']);

for i=1:length(zMIPfnames)
    ZMIP{i}=loadSingleTif([maindir filesep 'ZMIPs' filesep zMIPfnames(i).name]);
end

ZMIPwidth=size(ZMIP{1},2);
ZMIPheight=size(ZMIP{1},1);

%%
%initFigure
%
function initFigure

    figure('Position',[0 0 3*ZMIPwidth ZMIPheight ]);

    
end

%% MAIN LOOP


    initFigure;



end %main function


function imageData=loadSingleTif(absoluteFilename)
   
    warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning');

    infoImage=imfinfo(absoluteFilename);
    mImage=infoImage(1).Width;
    nImage=infoImage(1).Height;
    NumberImages=length(infoImage);
    if NumberImages>1
        disp('multi-image TIF found.  using first image.');
    end
    imageData=zeros(nImage,mImage,'uint16');
    TifLink = Tiff(absoluteFilename, 'r');  
    TifLink.setDirectory(1);   
    imageData=TifLink.read();

    TifLink.close();

    warning('on','MATLAB:imagesci:tiffmexutils:libtiffWarning');
    
end
%}