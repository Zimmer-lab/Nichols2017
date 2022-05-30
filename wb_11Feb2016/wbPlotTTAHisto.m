function TTAPairStructCellArray=wbPlotTTAHisto(wbstructOrTTAStructCellArray,neuron1,neuron2,options)


%% parse inputs 

if nargin<4
    options=[];
end

if nargin<1 || isempty(wbstructOrTTAStructCellArray)
    if exist('Quant','dir')
        wbstruct=wbload([],false);
    else  %multi datasets in one directory
%         folders=listfolders(pwd);
%         for i=1:length(folders)
%             wbstructOrTTAStructCellArray{i}=load([folders{i} filesep 'Quant' filesep 'wbTTAstruct.mat']);
%         end
        wbstruct=[];
    end
elseif isstruct(wbstructOrTTAStructCellArray)
    wbstruct=wbstructOrTTAStructCellArray;
else
    wbstruct=[];
end

% if ~isfield(options,'transitionKeyNeuron')
%     options.transitionKeyNeuron='AVAL';
% end 

if ~isfield(options,'transitionTypes')
    options.transitionTypes='SignedAllRises';
end 

% if ~isfield(options,'useOnlyIDedNeurons')
%     options.useOnlyIDedNeurons=true;
% end

% if ~isfield(options,'neuronSubset')
%     options.neuronSubset=[];
% end
if ~isfield(options,'neuron1Sign')
    options.neuron1Sign=0;
end

if ~isfield(options,'neuron2Sign')
    options.neuron2Sign=0;
end

if ~isfield(options,'hideOutliers')
    options.hideOutliers=false;
end 

if ~isfield(options,'subPlot')
    options.subPlot=false;
end

if ~isfield(options,'yLim')
    options.yLim=[];
end

if ~isfield(options,'plotTraces')
    options.plotTraces=true;
end

if ~isfield(options,'plotRefTrace')
    options.plotRefTrace=true;
end

if ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF';
end

if ~isfield(options,'timeWindowSize')
    options.timeWindowSize=10;  %seconds
end

if ~isfield(options,'FSAParams')
    posThresh=.05;
    negThresh=-.3;
    threshType='rel';
    options.FSAParams={posThresh,negThresh,threshType};
end

if ~isfield(options,'savePDFFlag')
    options.savePDFFlag=true;
end

if ~isfield(options,'savePDFDirectory')
    options.savePDFDirectory=pwd;
end

if ~isempty(wbstruct) 
    
    TTAPairStructCellArray={wbComputeTTAPair(wbstruct,neuron1,neuron2,options)};
    trialname=wbMakeShortTrialname(wbstruct.trialname);
    
elseif isempty(wbstructOrTTAStructCellArray)
    
    if ischar(neuron2)
        neuron2cellarray={neuron2};
    elseif iscell(neuron2)
        neuron2cellarray=neuron2;
    end
    
    disp('computing TTAs.');
    folders=listfolders(pwd);
    k=1;
    for i=1:length(folders)
        wbstruct=wbload(folders{i},false);
        wbstruct.trialname
        for j=1:length(neuron2cellarray)
           neuron2cellarray{j}
           
           if ~isnan(wbgettrace(neuron2cellarray{j},wbstruct))
                TTAPairStructCellArray{k}=wbComputeTTAPair(wbstruct,neuron1,neuron2cellarray{j},options);
                k=k+1;
           end
        end
    end
    trialname=[num2str(length(folders)) 'sets'];
else
    TTAPairStructCellArray=wbstructOrTTAStructCellArray;
    trialname='multisets';
end

TTAtraces1={};
TTAtraces2={};
TTAtv={};
delayDistribution=[];
precedingStateLength2=[];


for i=1:length(TTAPairStructCellArray)

    TTAtraces1=[TTAtraces1 TTAPairStructCellArray{i}.TTAtraces1];
    TTAtraces2=[TTAtraces2 TTAPairStructCellArray{i}.TTAtraces2];
    TTAtv=[TTAtv TTAPairStructCellArray{i}.TTAtv];

    delayDistribution=[delayDistribution TTAPairStructCellArray{i}.delayDistribution];
    precedingStateLength2=[precedingStateLength2 TTAPairStructCellArray{i}.precedingStateLength2];


end

if isfield(wbstruct,'fps')
    fps=wbstruct.fps;
else
    fps=3;
end

frameStartRel=-floor((fps*options.timeWindowSize)/2);
frameEndRel=floor((fps*options.timeWindowSize)/2);




if ~options.subPlot
    figure('Position',[0 0 1200 1000]);
end

whitebg('w');
% for n=1:nn
    
%     if options.useOnlyIDedNeurons || ~isempty(options.neuronSubset)
%          %[~,~, simpleNeuronNumber] = wbgettrace(IDs{n},wbstruct);
% simpleNeuronNumber=find(strcmp(IDs,'AVAL'))
% 
%         
%     else
%         simpleNeuronNumber=n;
%     end
    
%     if nn==1 
%         
%     elseif nn<16
%         
%          subtightplot(ceil( nn/4),4,n,[.01 .01],[],[.05 .05]);
%     else
%          subtightplot(ceil( nn/10),10,n,[.01 .01],[],[.05 .05]);
%     end
    
hold on;

% TTAtraces1=SubtractZeroValue(TTAtraces1);
% TTAtraces2=SubtractZeroValue(TTAtraces2);

if options.plotTraces || options.plotRefTrace %currently broken
    
    TTAtrace1_mean=nanmean(TTAtraces1,2);
    TTAtrace2_mean=nanmean(TTAtraces2,2);

    yMax=max([ TTAtrace1_mean; TTAtrace2_mean; TTAtraces2(:);]);
    yMin=min([ TTAtrace1_mean; TTAtrace2_mean; TTAtraces2(:);]);
    
else
    yMin=0;
    yMax=1;
end

if ~isempty(options.yLim)
    ylim(options.yLim);
    yMax=options.yLim(2);
else
    ylim(1.1*[yMin yMax]);
end
    
% if options.hideOutliers
%     xlim([TTAtv{1}(1) TTAtv{1}(end)]);
% end


hline(0);
vline(0,'r');

dD=delayDistribution
[histo,histoIndex]=hist(dD,-floor(options.timeWindowSize):floor(options.timeWindowSize));
if options.hideOutliers
    histo(end)=0;
    histo(1)=0;
end

%set(gca,'XTick',ceil(TTAtv{1}(1)):1:floor(TTAtv{1}(end)));
set(gca,'XTick',-floor(options.timeWindowSize):floor(options.timeWindowSize));


bar(histoIndex, histo/max(histo)*yMax, 'FaceColor','r','EdgeColor','none');

%mean excluding outliers
clippedMean=mean(dD(dD<options.timeWindowSize/2 & dD>-options.timeWindowSize/2));
vline(clippedMean,'b');
clippedStd=std(dD(dD<options.timeWindowSize/2 & dD>-options.timeWindowSize/2));
vline((clippedMean+clippedStd),color('g'));
vline((clippedMean-clippedStd),color('g'));

if options.plotTraces
    for i=1:size(TTAtraces2,2)
            plot(TTAtv,TTAtraces2(:,i),'Color',color('lb'));
    end
    plot(TTAtv,TTAtrace2_mean,'Color','b','LineWidth',1.5);
    
end

if options.plotRefTrace
    plot(TTAtv,TTAtrace1_mean,'Color','r','LineWidth',1.5);
end
    


if options.neuron1Sign<0
    neuron1_cased=lower(neuron1);
else
    neuron1_cased=upper(neuron1);
end

if options.neuron2Sign<0
    neuron2_cased=lower(neuron2);
else
    neuron2_cased=upper(neuron2);
end

textur(['\color{red}{' neuron1_cased '}\color{black}{\rightarrow} \color{blue}{' neuron2_cased '}']);

if ~options.subPlot
    if options.plotTraces
        
        ylabel('\DeltaF/F_0');
    else
        ylabel('fraction of transitions');
        set(gca,'YTick',[0 0.25 0.5 0.75 1]*yMax);
        set(gca,'YTickLabel',{'','','','',num2str(max(histo)/sum(histo),3)});
    end
end

if iscell(neuron2)
    neuron2string=(char(neuron2))';
    neuron2string=(neuron2string(:))';
else
    neuron2string=neuron2;
end

if ~options.subPlot
    xlabel('time (s)');
    if ~isfield(wbstruct,'trialname')
        wbstruct.trialname=[length(TTAPairStructCellArray) ' trials'];
    end
    
    
    title(['TTA:' neuron1 ' -> ' neuron2string  ' - ' trialname ',  ' num2str(length(dD)) ' transitions, ' options.transitionTypes]);
end


if options.savePDFFlag
   export_fig([options.savePDFDirectory filesep 'TTAPairHisto-' neuron1 '-' neuron2string '-' options.transitionTypes '-' trialname '.pdf'],'-transparent');
end


