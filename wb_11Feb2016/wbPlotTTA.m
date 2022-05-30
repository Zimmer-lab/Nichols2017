function values=wbPlotTTA(wbstruct,options)

histogramPlotFlag=true;
circlePlotFlag=false;


%% parse inputs 
if nargin<2
    options=[];
end

if ~isfield(options,'refNeuron')
    options.refNeuron='AVAL';
end

if ~isfield(options,'transitionTypes')
    options.transitionTypes='SignedAllRises';
end

if ~isfield(options,'neuronSubset')
    options.neuronSubset=[];
end
    
if ~isfield(options,'useValueNotRank')
    options.useValueNotRank=true;
end

if ~isfield(options,'savePDFFlag')
    options.savePDFFlag=false;
end

if ~isfield(options,'drawConnectorLines')
    options.drawConnectorLines=true;
end

if ~isfield(options,'savePDFDirectory')
    options.savePDFDirectory=[pwd filesep 'Quant'];
end

if ~isfield(options,'savePDFCopyName')
    options.savePDFCopyName=[];
end

if ~isfield(options,'appendToPDFCopy')   
    options.appendToPDFCopy=true;
end

if ~isfield(options,'showReferencePlot')
    options.showReferencePlot='true';
end

if ~isfield(options,'delayCutoff')
    options.delayCutoff=10;
end

if ~isfield(options,'plotTextLabels')
    options.plotTextLabels=false;
end

if ~isfield(options,'mixedLineStyles')
    options.mixedLineStyles=true;
end

if ~isfield(options,'mixedLineStyles')
    options.mixedLineStyles=true;
end

if ~isfield(options,'neuronSigns')   
    options.neuronSigns=[];
end

if ~isfield(options,'neuronNumGaussians')   
    options.neuronNumGaussians=[];
end


%% plot layout options

options.xSpacing=1;
options.ySpacing=1;
options.numberedXLabel='tr#';

%% load data and run four state analysis

if nargin<1 || isempty(wbstruct)
    wbstruct=wbload([],false);
end

%subset
if ischar(options.neuronSubset) && strcmp(options.neuronSubset(1:10),'topNeurons')
    numNeurons=str2double(options.neuronSubset(11:end));
    thisOptions.useOnlyIDedNeurons=true;  %will use less than 20 if some aren't IDed
    sortType='pcaloading1';
    options.neuronSubset=wbGetTopNeurons(sortType,numNeurons,wbstruct,thisOptions);
    options.neuronSubset
    
    %get neuron signs
    options.fieldName='deltaFOverF';
    [~, ~, loading]=wbSortTraces(wbstruct.simple.(options.fieldName),'signed_pcaloading1');
    [~,traceIndices]=wbGetTraces(wbstruct,[],options.fieldName,options.neuronSubset);

    
    [~,~,AVASimpleIndex]=wbgettrace('AVAL',wbstruct,options.fieldName);
    if isnan(AVASimpleIndex)
        [~,~,AVASimpleIndex]=wbgettrace('AVAR',wbstruct,options.fieldName);
    end
    if isnan(AVASimpleIndex)
        disp('no AVAs in dataset.  guessing +PC1.');
        AVAsign=1;
    else
        AVASign=sign(loading(AVASimpleIndex));
    end
    
    options.neuronSigns=ones(1,length(options.neuronSubset));
    for i=1:length(options.neuronSubset)
        if loading(traceIndices(i))*AVASign < 0
            options.neuronSigns(i)=-1;
        end
    end

end



%handle missing neurons gracefully
[~,neuronSimpleIndicesSubset]=wbGetTraces(wbstruct,true,[],options.neuronSubset);
if ~isempty(options.neuronSigns)
    options.neuronSigns(isnan(neuronSimpleIndicesSubset))=[];
end
if ~isempty(options.neuronNumGaussians)
    options.neuronNumGaussians(isnan(neuronSimpleIndicesSubset))=[];
end
neuronSimpleIndicesSubset(isnan(neuronSimpleIndicesSubset))=[];



[traceColoring, transitionListCellArray,transitionPreRunLengthListArray]=wbFourStateTraceAnalysis(wbstruct,'useSaved',options.refNeuron);
[refTrace,~, ~] = wbgettrace(options.refNeuron,wbstruct);


[transitions,transitionsType]=wbGetTransitions(transitionListCellArray,1,options.transitionTypes,options.neuronSigns,transitionPreRunLengthListArray);





labels=wbListIDs(wbstruct,false,neuronSimpleIndicesSubset);

if ~isempty(options.neuronSigns)
    labels=wbSetLabelCaseByNeuronSign(labels,options.neuronSigns,wbstruct);
end

% if ~isempty(options.neuronSigns)
%     for i=1:length(labels)
%         if options.neuronSigns(i)<1
%             labels{i}=lower(labels{i});
%         end
%     end
% end



if options.mixedLineStyles
    lineStyles={'-','--','-.',':'};
else
    lineStyles={'-'};
end

disp('done loading data.');
             
%% plots 

figure('Position',[0 0 1200 1000],'Name','TTA Analysis');    
nc=8;
if (options.showReferencePlot) 
    PlotReferenceTrace;
    handles.mainPlot=subtightplot(6,nc,[nc+1:2*nc-1   2*nc+1:3*nc-1   3*nc+1:4*nc-1  4*nc+1:5*nc-1  5*nc+1:6*nc-1    ],[.02 .01],[],[.05 .05]);  
else
    subtightplot(1,nc,1:nc,[],[],[.05 .05]);
end
set(gca,'TickDir','out');
margin=.2;
currentYLim=[-1 1];
allSortingLabels={};

for n=1:length(labels);
    colorList(n,:)=color(n,length(labels));
    colorListLight(n,:)=colorList(n,:)/5;
end

values=nan(length(transitions),length(labels));
xPos=zeros(length(transitions),length(labels));

%compute valid delays and positions

transitionOrdering=nan(length(transitions),length(labels));

for k=1:length(transitions)
        
    xPos(k,:)=k*options.xSpacing;
    allSortingLabels=[allSortingLabels  {[options.numberedXLabel num2str(k) ' ']}];

    transitionKeyFrame=transitions(k);
    evalParams{1}=transitionKeyFrame;
    evalParams{2}=options.transitionTypes;
    evalParams{3}=options.neuronSigns;
    
    values(k,:)=wbEvalTraces(wbstruct,'tta',evalParams,labels)/wbstruct.fps;
    
    values(k,abs(values(k,:))>options.delayCutoff)=NaN;  %don't plot very big delays since they are meaningless
    
    theseValues=values(k,:);
    theseValues(isnan(theseValues))=[];
    
    [~,transitionOrdering(k,1:length(theseValues))]=sort(theseValues);
    
    
    
end



%labels for circle plot

for i=1:length(labels)
    
    if ~isempty(options.neuronSigns) && options.neuronSigns(i)<1
        QLabels{i}=lower(labels{i});
    else
        QLabels{i}=upper(labels{i});
    end
    
    if ~isempty(options.neuronNumGaussians) && options.neuronNumGaussians(i)>1
        QLabels1{i}=[QLabels{i} '1'];    
    else
        QLabels1{i}=QLabels{i};
    end
end

for i=1:length(labels)
    if ~isempty(options.neuronNumGaussians) && options.neuronNumGaussians(i)>1
       QLabels2{i}=[QLabels{i} '2'];    
    else
       QLabels2{i}='';
    end
end



%% plot main plot
set(gca,'XTick',1:length(allSortingLabels));
set(gca,'XTickLabel',allSortingLabels);
xlim([0.5 length(transitions)*options.xSpacing+0.5]); 
 
if options.plotTextLabels
    hold on;
    for k=1:length(transitions)

        PlotTextColumn(xPos(k,1),options.ySpacing,labels,values(k,:));

        if options.drawConnectorLines  && k>1
            DrawConnectorLines([xPos(k-1,1)+margin xPos(k,1)-margin],values(k-1,:),values(k,:),colorList);
        end  


        %set ylimits
        if options.useValueNotRank
%              currentYLim=[min([currentYLim(1)  min(values(k,:))])   max([currentYLim(2)   max(values(k,:)) ])   ];
%              ylim(1.1*currentYLim);
               ylim([-options.delayCutoff options.delayCutoff]);
        else
             set(gca,'YTick',1:currentYLim);
             currentYLim= [0 max([currentYLim(2) length(labels{k})])];
             ylim(currentYLim+0.5);
             
        end
        drawnow;

    end
    
    
    
else  %plots
    hold on;
    for n=1:length(labels)
        
        plot(xPos(:,n),values(:,n),'Color',colorList(n,:),'Marker','.','MarkerSize',12,'LineStyle',lineStyles{mod(n-1,length(lineStyles))+1});
        
    end
    
    legend(QLabels,'Location','NorthEast');
end




if options.useValueNotRank
    ylim([-options.delayCutoff options.delayCutoff]);
    ylabel('delay (s)');
    %mtit(['relative transition delays for ' wbMakeShortTrialname(wbstruct.trialname)]);
else
    ylabel('rank');
    % mtit(['rank TTA ordering ' wbMakeShortTrialname(wbstruct.trialname)]); 
end




PlotSideHisto;
mtit([wbMakeShortTrialname(wbstruct.trialname)  ' - ' options.transitionTypes],'xoff',-.02);
SaveCurrentFig;

%histogram plot
if histogramPlotFlag   
    PlotHistos;  
    SaveCurrentFig;
end




%circle plot
if circlePlotFlag
    
    figure('Position',[0 0 800 800],'Name',['CirclePlot - ' wbMakeShortTrialname(wbstruct.trialname)]);


    QThetas=nanmean(values,1);

    tta=load('Quant/wbTTAstruct.mat');
    neuronLabel1=options.refNeuron;
    n1=find(strcmpi(tta.neuronLabels,neuronLabel1));

    for i=1:length(labels)
        if  ~isempty(options.neuronNumGaussians) && options.neuronNumGaussians(i)>1
            nc=options.neuronNumGaussians(i);

            n2=find(strcmpi(tta.neuronLabels,labels{i}));
            [dataToCluster, inBoundsIndices]=InBounds(tta.delayDistributionMatrix{n2,n1}/tta.fps,-10,10);

            [clusterAssignment{i},model,L]=emgm(dataToCluster',nc,false);  %em mixture modeling
            clusterAssignmentAll{i}=zeros(size(tta.delayDistributionMatrix{n2,n1}));
            clusterAssignmentAll{i}(inBoundsIndices)=clusterAssignment{i};

            QThetas(i)=model.mu(1);
            QThetas2(i)=model.mu(2);

            %update transitionOrdering
            for tr=1:size(transitionOrdering,1)

                if clusterAssignmentAll{i}( tr  )==2
                    transitionOrdering(tr,i)=transitionOrdering(tr,i)+length(labels);
                end
            end


        else
            QThetas2(i)=0;
        end


    end

    scale=options.delayCutoff;
    %wbCirclePlot([],[QThetas QThetas2],[QLabels1 QLabels2] ,scale,transitionOrdering');
    wbCirclePlot([],[QThetas QThetas2],[QLabels1 QLabels2] ,scale,sort(values'));

end


%end main

%% inline funcs

    function PlotTextColumn(xPos,ySpacing,textLabels,vals)
        
        for i=1:length(textLabels)
             text(xPos,ySpacing*vals(i),textLabels{i},'HorizontalAlignment','center');
        end
    end


    function DrawConnectorLines(xEndpoints,yList1,yList2,colorList)
                
        for yi=1:min([length(yList1) length(yList2)])
            line(xEndpoints,[yList1(yi) yList2(yi)],'Color',colorList(yi,:));
        end

    end

    function PlotReferenceTrace

        %reference plot at the top of the figure
        subtightplot(6,nc,1:nc,[.02 .01],[],[.05 .05]);

        markerType='none';
        markerSize=12;
        stateColors={[0 0 1],[1 0 0],[0 1 0],[1 1 0]};
        


        for i=1:4  %four states to color

            coloredData=zero2nan( double(traceColoring(:,1)==i )  );
            handles.overlayPlot(i)=plot(wbstruct.tv,coloredData.*refTrace,'Color',stateColors{i},'LineWidth',1,'Marker',markerType,'MarkerSize',markerSize);
            hold on;
        end

        SmartTimeAxis([wbstruct.tv(1) wbstruct.tv(end)]);

        ylim([min(refTrace) 1.1*max(refTrace)]);
        xlim([wbstruct.tv(1) wbstruct.tv(end)]);
        hold on;
        for tf=1:length(transitions)
            vline(wbstruct.tv(transitions(tf)));
            text(wbstruct.tv(transitions(tf)),max(refTrace),[num2str(tf) ': ' num2str(transitionsType(tf))]);
        end
        intitle(options.refNeuron,14,false,[],'b'); 



    end

    function PlotHistos
        
        figure('Position',[0 0 800 1200],'Name',['TTA histograms - ' wbMakeShortTrialname(wbstruct.trialname)]);
        subtightplot(1,1,1,[0.05 0.05],[0.1 0.1],[0.1 0.1]);
        hold on;
        yLim=get(handles.mainPlot,'YLim');
        
        
        for n=length(labels):-1:1
            
            [thisHist,thisHistInd ]=hist(values(:,n),yLim(1):1:yLim(2));
        
            xBase=10*(n-1);
            area(thisHistInd,thisHist+xBase,xBase,'FaceColor',colorListLight(n,:),'EdgeColor',colorList(n,:),'LineStyle',lineStyles{mod(n-1,length(lineStyles))+1});
            hold on;
           % fill([thisHistInd(1) thisHistInd thisHistInd(end)],xBase+[0 thisHist 0],colorList(n,:));
            alpha(0.8);
        end
        ylim([-5 10*(length(labels))]);
        xlabel(['timing (s) relative to ' options.refNeuron]);
        ylabel('count - 1 row=10');
        set(gca,'YTick',0:10:10*(length(labels)-1));
        set(gca,'YTickLabel',labels);
        title([wbMakeShortTrialname(wbstruct.trialname)  ' - ' options.transitionTypes]);
        xlim([-options.delayCutoff options.delayCutoff]);
        
    end

    function PlotSideHisto
        subtightplot(6,nc,(2:6)*nc,[.02 .02],[],[.05 .05]);
        hold on;
        yLim=get(handles.mainPlot,'YLim');
        for n=length(labels):-1:1
            
            [thisHist,thisHistInd ]=hist(values(:,n),yLim(1):1:yLim(2));
        
            %area(thisHistInd,thisHist,'EraseMode','xor','FaceColor',colorListLight(n,:),'EdgeColor',colorList(n,:),'LineStyle',lineStyles{mod(n-1,length(lineStyles))+1});
            fill([thisHistInd(1) thisHistInd thisHistInd(end)],[0 thisHist 0],colorList(n,:));
            alpha(0.8);
        end
    view([90 -90]);
    ylim([0 8]);
    ylabel('count');
    end

    function SaveCurrentFig
        
        if options.savePDFFlag
           export_fig([ 'TTA-' options.transitionTypes  '-ref' options.refNeuron '-' num2str(length(labels)) 'neurons-' wbMakeShortTrialname(wbstruct.trialname) '.pdf'],...
               '-append','-transparent');

        end

        if ~isempty(options.savePDFCopyName)
            if options.appendToPDFCopy

               export_fig([options.savePDFDirectory filesep options.savePDFCopyName],'-append');
            else

               export_fig([options.savePDFDirectory filesep options.savePDFCopyName]);
            end
        end

    end

end