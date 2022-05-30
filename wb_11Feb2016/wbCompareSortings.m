function labels=wbCompareSortings(wbstructsFileListOrRootFolder,options)


if nargin<1 || isempty(wbstructsFileListOrRootFolder)
   
    if ismember('Quant',listfolders(pwd))  %this is not a rootFolder
       wbstructFileList{1}=pwd;
    else
       wbstructFileList=listfolders(pwd);
    end
    
elseif ischar(wbstructsFileListOrRootFolder)
    
    rootFolder=wbstructsFileListOrRootFolder;
    wbstructFileList=getfolders(rootFolder);
    
elseif iscell(wbstructsFileListOrRootFolder)
    
    wbstructFileList=wbstructsFileListOrRootFolder;
    
end

if nargin<2
    options=[];
end


if ~isfield(options,'useValueNotRank')
    options.useValueNotRank=false;
end


if ~isfield(options,'savePDFFlag')
    options.savePDFFlag=false;
end

if ~isfield(options,'neuronSubset')
    options.neuronSubset=[];
end

if ~isfield(options,'drawConnectorLines')
    options.drawConnectorLines=true;
end

if ~isfield(options,'savePDFDirectory')
    options.savePDFDirectory=[pwd filesep 'Quant'];
end

if ~isfield(options,'showReferencePlot')
    options.showReferencePlot='true';
end

if  ~isfield(options,'sortMethod')
    options.sortMethod='tta';
end

if ~isfield(options,'multiSortingsFlag')
    options.multiSortingsFlag=true;
end

if ~isfield(options,'sortParams')
    posThresh=.05;
    negThresh=-.3;
    threshType='rel';
    transitionTypes=[1 6 8];
    options.sortParams={posThresh,negThresh,threshType,-1,transitionTypes};
end

options.transitionKeyNeuron='AVAL';

options.xSpacing=1;
options.ySpacing=1;

%Make appropriate xLabel
if ~isfield(options,'numberedXLabel')
    if strcmp(options.sortMethod,'tta')
        options.numberedXLabel='tr#';
    elseif strcmp(options.sortMethod,'pcaloading')
        options.numberedXLabel='pc#';
    else
        options.numberedXLabel='#';
    end
end


figure('Position',[0 0 1200 1000]);    

%% reference plot at the top of the figure
if options.showReferencePlot
    subtightplot(6,1,1,[.02 .01],[],[.05 .05]);

    wbstruct=wbload(wbstructFileList{1},false);
    [traceColoring, transitionListCellArray]=wbFourStateTraceAnalysis(wbstruct,options.sortParams{1},options.sortParams{2},options.sortParams{3});
    [refTrace,~, keyNeuronIndex] = wbgettrace(options.transitionKeyNeuron,wbstruct);
    transitions=wbGetTransitions(transitionListCellArray,keyNeuronIndex,transitionTypes);

    %plot(wbstruct.tv,refTrace);
    
    markerType='none';
    markerSize=12;
                                   
    %coloringIndex=find(reducedSortOrder==keyNeuronIndex,1);
    stateColors={[0 0 1],[1 0 0],[0 1 0],[1 1 0]};
    
    for i=1:4  %four states to color

        coloredData=zero2nan( double( traceColoring(:,keyNeuronIndex)==i )  );
        handles.overlayPlot(i)=plot(wbstruct.tv,coloredData.*refTrace,'Color',stateColors{i},'LineWidth',1,'Marker',markerType,'MarkerSize',markerSize);
        hold on;
    end
                                   
    SmartTimeAxis([wbstruct.tv(1) wbstruct.tv(end)]);

    ylim([min(refTrace) 1.1*max(refTrace)]);
    xlim([wbstruct.tv(1) wbstruct.tv(end)]);
    hold on;
    for tf=1:length(transitions)
        vline(wbstruct.tv(transitions(tf)));
        text(wbstruct.tv(transitions(tf)),max(refTrace),num2str(tf));
    end
    intitle(options.transitionKeyNeuron); 
    
end

if options.showReferencePlot
    subtightplot(6,1,2:6,[.02 .01],[],[.05 .05]);
else
    subtightplot(1,1,1,[],[],[.05 .05]);
end

set(gca,'TickDir','out');


%% sortings


margin=.2;
currentYLim=[1 1];
allSortingLabels={};
numTrials=length(wbstructFileList);

if options.multiSortingsFlag
    
    ik=1;
    for i=1:numTrials
        
        wbstruct=wbload(wbstructFileList{i},false);
        
        
        %prepare sort-specific data
        
        if strcmp(options.sortMethod,'tta')
        
            [traceColoring, transitionListCellArray]=wbFourStateTraceAnalysis(wbstruct,options.sortParams{1},options.sortParams{2},options.sortParams{3});
            [~,~, keyNeuronIndex] = wbgettrace(options.transitionKeyNeuron,wbstruct);
            transitions=wbGetTransitions(transitionListCellArray,keyNeuronIndex,transitionTypes);
            
            variableParamArray=transitions;
            variableParamNumber=4;

        elseif strcmp(options.sortMethod,'pcaloading')
            
            variableParamArray=1:10;
            variableParamNumber=1;     
            
        end
        
        
        
        for k=1:length(variableParamArray)
            
                        
            xPos(ik)=ik*options.xSpacing;

            allSortingLabels=[allSortingLabels  {[options.numberedXLabel num2str(k) ' ']}];

            plotSortingOptions.xPos=xPos(ik);
            plotSortingOptions.useForSubplot=true;            
            sortLabelsOptions.sortMethod=options.sortMethod;
            sortLabelsOptions.useOnlyIDedNeurons=true;
            plotSortingOptions.useValueNotRank=options.useValueNotRank;
            
            
            
            %load in variable parameter
            thisSortParams=options.sortParams;
            thisSortParams{variableParamNumber}=variableParamArray(k);
            
            sortLabelsOptions.sortParams=thisSortParams;
            
            [labels{ik},values{ik},columnYLimits]=wbPlotSortingColumn(wbstruct,plotSortingOptions,sortLabelsOptions);
            hold on;
            
            if options.useValueNotRank
                currentYLim=[min([currentYLim(1)  columnYLimits(1)])   max([currentYLim(2)   columnYLimits(2) ])   ];
            else
                set(gca,'YTick',1:currentYLim);
                currentYLim= [0 max([currentYLim(2) length(labels{ik})])];
                
            end
            ylim(currentYLim+0.5);
            
                
            if options.drawConnectorLines
                
                if options.useValueNotRank
                    
                    if ik>1
                        
                        yList1=values{ik-1};
                        yList2=values{ik};
                        
                        DrawConnectorLines([xPos(ik-1)+margin xPos(ik)-margin],yList1,yList2);
                    end      
                    
                else
                            
                    yList1=[];
                    yList2=[];
                             
                    if ik>1
                        for ii=1:length(labels{ik-1})


                            j=find(strcmp(labels{ik},labels{ik-1}{ii}));

                            if j
                                yList1=[yList1 ii];
                                yList2=[yList2 j];
                            end
                        end
                        DrawConnectorLines([xPos(ik-1)+margin xPos(ik)-margin],yList1,yList2);
                    end
           
                end
            
            end
            
            
            
            
            xlim([0.5 (ik)*options.xSpacing+0.5]);
            ik=ik+1;
            set(gca,'XTick',1:length(allSortingLabels));
            set(gca,'XTickLabel',allSortingLabels);
            drawnow;
         end
        
    end
    
else
    
    numSortings=numTrials;
    xlim([0.5 numSortings*options.xSpacing+0.5]);
    set(gca,'XTick',1:numSortings);

    for i=1:numSortings

        xPos(i)=i*options.xSpacing;

        wbstruct=wbload(wbstructFileList{i},false);
        allSortingLabels=[allSortingLabels  wbMakeShortTrialname(wbstruct.trialname)];

        plotSortingOptions.xPos=xPos(i);
        plotSortingOptions.sortMethod=options.sortMethod;
        plotSortingOptions.useForSubplot=true;

        [labels{i},values{i},columnYLimits]=wbPlotSorting(wbstruct,plotSortingOptions);
        hold on;
        
        if options.useValueNotRank
            currentYLim=[min([currentYLim(1)  columnYLimits(1)])   max([currentYLim(2)   columnYLimits(2) ])   ];
        else
            set(gca,'YTick',1:currentYLim);
            currentYLim= [0 max([currentYLim(2) length(labels{ik})])];

        end
        ylim(currentYLim+0.5);
            
        drawnow;

        if options.drawConnectorLines
            yList1=[];
            yList2=[];
            if i>1
                for ii=1:length(labels{i-1})
                    if options.useValueNotRank
                        j=values{i}(ii);
                    else
                        j=find(strcmp(labels{i},labels{i-1}{ii}));
                    end
                    
                    if j
                        yList1=[yList1 ii];      
                        yList2=[yList2 j];
                        
                        
                    end
                end
                DrawConnectorLines([xPos(i-1)+margin xPos(i)-margin],yList1,yList2);
            end
        end
        
        
        
        set(gca,'XTickLabel',allSortingLabels);
    end

end

if options.useValueNotRank
    ylabel('value');
else
    ylabel('rank');
end

mtit(['rank ordering by ' options.sortMethod ' ' wbMakeShortTrialname(wbstruct.trialname) ]);


if options.savePDFFlag
   export_fig([options.savePDFDirectory filesep 'CompareSortings-' options.sortMethod '-' wbMakeShortTrialname(wbstruct.trialname) '.pdf'],'-transparent');
end

%end main

    function DrawConnectorLines(xEndpoints,yList1,yList2)
                
        for yi=1:min([length(yList1) length(yList2)])
            line(xEndpoints,[yList1(yi) yList2(yi)]);
        end

    end

end