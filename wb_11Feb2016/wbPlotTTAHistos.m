function wbPlotTTAHistos(GlobalTTAStructFileName,options)

if nargin<2
    options=[];
end

if ~isfield(options,'savePDF');
    options.savePDF=true;
end

if ~isfield(options,'subPlotFlag');
    options.subPlotFlag=false;
end

if ~isfield(options,'neuronSubset');
    options.neuronSubset=[];
end

if ~isfield(options,'plotClusterMeanLines')
    options.plotClusterMeanLines=true;
end

if ~isfield(options,'clusterColoring');    
    options.clusterColoring=[];
end

if ~isfield(options,'showPercentages')
    options.showPercentages=true;
end

if ~isfield(options,'sortingMethod')
    options.sortingMethod='delay';
end

if ~isfield(options,'plotStairStep')
    options.plotStairStep=true;
end

if ~isfield(options,'barOutline')
    options.barOutline=true;
end

if ~isfield(options,'refGlobalTTAStructFileName');    
    options.refGlobalTTAStructFileName=[];
end

if ~isfield(options,'plotRefTTA') 
    if isempty(options.refGlobalTTAStructFileName);      
        options.plotRefTTA=false;
    else
        options.plotRefTTA=true;
    end
end

if ~isfield(options,'skipUnmatchedEntries') 
    options.skipUnmatchedEntries=true;
end

if ~isfield(options,'legend');    
    options.legend=[];
end

    
if ~isfield(options,'plotSpacing')
    options.plotSpacing=10;
end

if ~isfield(options,'timeRange')
    options.timeRange=[-10 10];
end

if ~isfield(options,'hideOutliers')
    options.hideOutliers=true;
end


if ~isfield(options,'multiPanelFlag')
    options.multiPanelFlag=false;
end

if ~isfield(options,'maxPlotsPerPanel')
    options.maxPlotsPerPanel=[];
end

if ~isfield(options,'plotGaussians');    
    options.plotGaussians=false;
end

if ~isfield(options,'clusterIndividualFlag');    
    options.clusterIndividualFlag=false;
end

if ~isfield(options,'rainbowColor');    
    options.rainbowColor=false;
end


if nargin<1
    GlobalTTAStructFileName='GlobalTTA-SignedAllRises.mat';
end

GlobalTTAstruct=load(GlobalTTAStructFileName);

if ~isempty(options.refGlobalTTAStructFileName)
    refGlobalTTAstruct=load(options.refGlobalTTAStructFileName);
end

lineStyles={'-','--','-.',':'};

        
for n=1:length(GlobalTTAstruct.compiled.labels);
   colorList(n,:)=color(n,length(GlobalTTAstruct.compiled.labels));
   colorListLight(n,:)=colorList(n,:)/5;
end

        
%compute sorting by timing
if strcmpi(options.sortingMethod,'modality')
     [modes, strength_1mode, strength_2modes, sortVals]=AssignGaussianModes(GlobalTTAstruct.compiled);
    sortVals(isnan(sortVals))=[];
    [sortedVals, sortIndex]=sort(sortVals,'descend');
    disp('sorting by modality.');
    
    %create mode info labels
    for i=1:length(modes)
        modeInfoLabels{i}=[num2str(modes(i)) ', ' num2str(max([strength_1mode(i) strength_2modes(i)]))];
    end

elseif strcmpi(options.sortingMethod,'delay')
    sortVals=[GlobalTTAstruct.compiled.gaussianFitData(1).neuron(:).mu];
    sortVals(isnan(sortVals))=[];
    [sortedVals, sortIndex]=sort(sortVals,'descend');
else
    sortIndex=length(GlobalTTAstruct.compiled.labels):-1:1;
end


if ~options.subPlotFlag
    figure('Position',[0 0 1600 1200],'Name',['TTA histograms- ' GlobalTTAstruct.runInfo.options.transitionTypes]);
end
        
if isempty(options.maxPlotsPerPanel) 
    options.maxPlotsPerPanel=length(GlobalTTAstruct.compiled.labels);
end

    
if options.multiPanelFlag

    plotCount=1;  %individual histo
    panelCount=1; 
    numPanels=ceil(length(GlobalTTAstruct.compiled.labels)/options.maxPlotsPerPanel);

    for n=1:length(GlobalTTAstruct.compiled.labels)

        yBase=options.plotSpacing*(plotCount-1);

        if ~options.subPlotFlag
                    subtightplot(1,numPanels,panelCount,[0.05 0.05],[0.05 0.05],[0.05 0.05]);
        end

        if (plotCount>options.maxPlotsPerPanel) || (n==1) % && ~options.subPlotFlag)

            disp('this is running')

            yBase=0;

            %figure('Position',[0 0 800 1200],'Name',['TTA histograms- ' GlobalTTAstruct.runInfo.options.transitionTypes '- ' num2str(panelCount)']);

            set(gca,'YDir','reverse')
            ylim([-options.plotSpacing*3 options.plotSpacing*(options.maxPlotsPerPanel)]);
            xlim([-GlobalTTAstruct.runInfo.options.delayCutoff GlobalTTAstruct.runInfo.options.delayCutoff]);


            xlabel(['Relative onset (s)']);
            if (n==1) ylabel(['count - 1 row=' num2str(options.plotSpacing)]); end

            set(gca,'XTick',-10:10);


            if n<length(GlobalTTAstruct.compiled.labels)-options.maxPlotsPerPanel    
                yTickMax=(options.maxPlotsPerPanel-1);
            else
                yTickMax=mod(length(GlobalTTAstruct.compiled.labels),options.maxPlotsPerPanel)-1;
            end

            set(gca,'YTick',(0:yTickMax)*options.plotSpacing);
            set(gca,'YTickLabel',GlobalTTAstruct.compiled.labels(sortIndex(n:n+yTickMax)));


            normalAxes=gca;
    %       na=axes('Position',get(gca,'Position'),'YAxisLocation','right','XAxisLocation','top','Color','none');
    %       set(na,'YLim',get(normalAxes,'YLim'));
    %       set(na,'YTick',(0:yTickMax)*options.plotSpacing);
    %       set(na,'YTickLabel',modeInfoLabels(sortIndex(n:n+yTickMax)));
    %       set(na,'XTick',[]);
    %       set(na,'YDir','reverse');
    %        
    %       axes(normalAxes);

            if (panelCount==2) title([GlobalTTAstruct.runInfo.options.transitionTypes]); end

            plotCount=1;
            panelCount=panelCount+1;
            
            hold on;
        end

        yScaleAdj=max(cellfun(@length,GlobalTTAstruct.compiled.delays))/length(GlobalTTAstruct.compiled.delays{sortIndex(n)});

        [thisHist,thisHistInd ]=hist(GlobalTTAstruct.compiled.delays{sortIndex(n)},-GlobalTTAstruct.runInfo.options.delayCutoff:.5:GlobalTTAstruct.runInfo.options.delayCutoff);

        if options.plotStairStep   
            [thisHistInd,thisHist]=Stepify(thisHistInd,thisHist);      
        end

        if options.clusterIndividualFlag

            [clusterMembership,clusterCenters]=AssignToCluster1D(GlobalTTAstruct.compiled.delays{sortIndex(n)}',2);

            clusterIndices2=find(clusterMembership==2);
            clusterIndices1=find(clusterMembership==1);
            clusterIndices0=find(clusterMembership==0);


            if ~isempty(clusterIndices0)
                [thisHistC0,thisHistIndC0 ]=hist(GlobalTTAstruct.compiled.delays{sortIndex(n)}(clusterIndices0),-GlobalTTAstruct.runInfo.options.delayCutoff:.5:GlobalTTAstruct.runInfo.options.delayCutoff);

                if options.plotStairStep
                    [thisHistIndC0,thisHistC0]=Stepify(thisHistIndC0,thisHistC0);
                end

                if options.rainbowColor
                     thisEdgeColor=colorList(n,:);
                     thisLineStyle=lineStyles{mod(n-1,length(lineStyles))+1};
                else
                    thisEdgeColor='k';
                    thisLineStyle='-';

                end
                area(thisHistIndC0,-yScaleAdj*thisHistC0+yBase,yBase,'FaceColor','g','EdgeColor',thisEdgeColor,'LineStyle',thisLineStyle);
                alpha(0.8);
                hold on;
            end

            if ~isempty(clusterIndices1)
                [thisHistC1,thisHistIndC1 ]=hist(GlobalTTAstruct.compiled.delays{sortIndex(n)}(clusterIndices1),-GlobalTTAstruct.runInfo.options.delayCutoff:.5:GlobalTTAstruct.runInfo.options.delayCutoff);

                if options.plotStairStep
                    [thisHistIndC1,thisHistC1]=Stepify(thisHistIndC1,thisHistC1);
                end

                if options.rainbowColor
                    thisEdgeColor=colorList(n,:);
                    thisLineStyle=lineStyles{mod(n-1,length(lineStyles))+1}
                else
                    thisEdgeColor='k';
                    thisLineStyle='-';
                end

                area(thisHistIndC1,-yScaleAdj*thisHistC1+yBase,yBase,'FaceColor','r','EdgeColor',thisEdgeColor,'LineStyle',thisLineStyle);
                alpha(0.8);
            hold on;
            end

            if ~isempty(clusterIndices2)
                [thisHistC2,thisHistIndC2 ]=hist(GlobalTTAstruct.compiled.delays{sortIndex(n)}(clusterIndices2),-GlobalTTAstruct.runInfo.options.delayCutoff:.5:GlobalTTAstruct.runInfo.options.delayCutoff);

                if options.plotStairStep
                    [thisHistIndC2,thisHistC2]=Stepify(thisHistIndC2,thisHistC2);
                end


                if options.rainbowColor
                    thisEdgeColor=colorList(n,:);
                    thisLineStyle=lineStyles{mod(n-1,length(lineStyles))+1};
                else
                    thisEdgeColor='k';
                    thisLineStyle='-';

                end

                area(thisHistIndC2,-yScaleAdj*thisHistC2+yBase,yBase,'FaceColor','b','EdgeColor',thisEdgeColor,'LineStyle',thisLineStyle);
                hold on;
                alpha(0.8);   
            end

        else %do not cluster individual
            

            if options.rainbowColor
                 thisEdgeColor=colorList(n,:);
                 thisFaceColor=colorListLight(n,:);
                 thisLineStyle=lineStyles{mod(n-1,length(lineStyles))+1};
            else
                thisEdgeColor='k';
                thisFaceColor='k';
                thisLineStyle='-';
            end  

            area(thisHistInd,-yScaleAdj*thisHist+yBase,yBase,'FaceColor',thisFaceColor,'EdgeColor',thisEdgeColor,'LineStyle',thisLineStyle);
            hold on;
            alpha(0.8);

        end

        
        
        if options.plotGaussians

            %cluster gaussian mean line
            if options.plotClusterMeanLines
                for i=1:length(GlobalTTAstruct.compiled.gaussianFitData(1).neuron(sortIndex(n)).mu)         
                     vline(GlobalTTAstruct.compiled.gaussianFitData(1).neuron(sortIndex(n)).mu(i),colorList(n,:),[],[yBase yBase-10],1);
                end

                %cluster2 gaussian mean line
                for i=1:length(GlobalTTAstruct.compiled.gaussianFitData(2).neuron(sortIndex(n)).mu)         
                     vline(GlobalTTAstruct.compiled.gaussianFitData(2).neuron(sortIndex(n)).mu(i),[0.5 0.5 0.5],[],[yBase yBase-7],1);
                end
            end

            %gaussian curves
            for i=1:length(GlobalTTAstruct.compiled.gaussianFitData(2).neuron(sortIndex(n)).mu)  
                if size(GlobalTTAstruct.compiled.gaussianFitData(2).neuron(sortIndex(n)).tv,1)>0
                 plot(GlobalTTAstruct.compiled.gaussianFitData(2).neuron(sortIndex(n)).tv,...
                      -options.plotSpacing*GlobalTTAstruct.compiled.gaussianFitData(2).neuron(sortIndex(n)).modeltraces(:,i)+yBase);
                end
            end
        else
            if options.plotClusterMeanLines
                clusterColor={[1 0 0],[0 0 1]};
                clusterCentersSorted=sort(clusterCenters);
                for i=1:length(clusterCentersSorted)               
                    vline(clusterCentersSorted(i),clusterColor{i},[],[yBase yBase-7],1);
                end

            end
        end

        %percentage occupancy

        if options.showScores
             text(7.5,yBase-2,[num2str((1-length(clusterIndices0)/length(clusterMembership)),2) '(' num2str(length(clusterMembership))  ')']);
        end

        plotCount=plotCount+1; 

    end

    yTickMax=(options.maxPlotsPerPanel-1);

    options.plotSpacing
    set(gca,'YTick',(0:yTickMax)*options.plotSpacing);
    set(gca,'YTickLabel',GlobalTTAstruct.compiled.labels(sortIndex));


else  %single panel
   
    
    plotCount=1;  %individual histo
    set(gca,'YDir','reverse');
    hold on;         

%     if n<length(GlobalTTAstruct.compiled.labels)-options.maxPlotsPerPanel    
%         yTickMax=(options.maxPlotsPerPanel-1);
%     else
%         yTickMax=mod(length(GlobalTTAstruct.compiled.labels),options.maxPlotsPerPanel)-1;
%     end

    yBase(1)=0;
    
    validLabels={};
    skipFlag=0;
    nn=1;
    for n=1:length(GlobalTTAstruct.compiled.labels)

   
%       yScaleAdj=max(cellfun(@length,GlobalTTAstruct.compiled.delays))/length(GlobalTTAstruct.compiled.delays{sortIndex(n)});

        if options.skipUnmatchedEntries
             refn= find(strcmp(   GlobalTTAstruct.compiled.labels{sortIndex(n)},  refGlobalTTAstruct.compiled.labels));
             if  isempty(refn)
                 skipFlag=1;
             else
                 skipFlag=0;
             end
        end

        if ~skipFlag
        
            if strcmp(options.clusterColoring,'fall')
                [thisHist1,thisHistInd ]=hist(GlobalTTAstruct.compiled.delays{sortIndex(n)}(  GlobalTTAstruct.compiled.clusterFallMembership{sortIndex(n)}==1),...
                    -GlobalTTAstruct.runInfo.options.delayCutoff:.5:GlobalTTAstruct.runInfo.options.delayCutoff);
                [thisHist2,thisHistInd ]=hist(GlobalTTAstruct.compiled.delays{sortIndex(n)}( GlobalTTAstruct.compiled.clusterFallMembership{sortIndex(n)}==2),...
                    -GlobalTTAstruct.runInfo.options.delayCutoff:.5:GlobalTTAstruct.runInfo.options.delayCutoff);
            elseif strcmp(options.clusterColoring,'rise')
                [thisHist1,thisHistInd ]=hist(GlobalTTAstruct.compiled.delays{sortIndex(n)}(  GlobalTTAstruct.compiled.clusterRiseMembership{sortIndex(n)}==1),...
                    -GlobalTTAstruct.runInfo.options.delayCutoff:.5:GlobalTTAstruct.runInfo.options.delayCutoff);
                [thisHist2,thisHistInd ]=hist(GlobalTTAstruct.compiled.delays{sortIndex(n)}( GlobalTTAstruct.compiled.clusterRiseMembership{sortIndex(n)}==2),...
                    -GlobalTTAstruct.runInfo.options.delayCutoff:.5:GlobalTTAstruct.runInfo.options.delayCutoff); 
            else
                [thisHist1,thisHistInd ]=hist(GlobalTTAstruct.compiled.delays{sortIndex(n)},...
                    -GlobalTTAstruct.runInfo.options.delayCutoff:.5:GlobalTTAstruct.runInfo.options.delayCutoff);
                thisHist2=0;
            end
        
        
            if options.plotRefTTA
                refn= find(strcmp(   GlobalTTAstruct.compiled.labels{sortIndex(n)},  refGlobalTTAstruct.compiled.labels));
                if ~isempty(refn)
                    [thisHistRef,thisHistIndRef ]=hist(refGlobalTTAstruct.compiled.delays{refn},...
                        -refGlobalTTAstruct.runInfo.options.delayCutoff:.5:refGlobalTTAstruct.runInfo.options.delayCutoff);
                else
                    thisHistRef=zeros(size(thisHist1));
                end
            else
                thisHistRef=zeros(size(thisHist1));
            end

        
                
            if options.hideOutliers
                thisHist1(1)=0;
                thisHist1(end)=0;
                thisHist2(1)=0;
                thisHist2(end)=0;
                thisHistRef(1)=0;
                thisHistRef(end)=0;
            end

        
        
            if nn>1
                  yBase(nn)=yBase(nn-1)+max([4 max(thisHist1+thisHist2) max(thisHistRef)])+1;
    %             yBase(n)=options.plotSpacing*(plotCount-1);
            else
                yMin=-max([thisHist1+thisHist2, thisHistRef])/3;
            end
        
        
    %         if options.plotStairStep   
    %             [thisHistInd,thisHist]=Stepify(thisHistInd,thisHist);      
    %         end

    %         if options.showScores
    %               [clusterMembership,clusterCenters]=AssignToCluster1D(GlobalTTAstruct.compiled.delays{sortIndex(n)}',2);
    %               clusterIndices0=find(clusterMembership==0);
    %               text(10.5,yBase(n)-3,[num2str(100*(1-length(clusterIndices0)/length(clusterMembership)),3) '% (' num2str(length(clusterMembership))  ')'],...
    %                   'HorizontalAlignment','left','FontSize',8);
    %         end



    %       thisEdgeColor='r';
    %       thisFaceColor='r';
    %       thisLineStyle='-';
    %       yScaleAdj=1;
    %       area(thisHistInd,-yScaleAdj*thisHist+yBase(n),yBase(n),'FaceColor',thisFaceColor,'EdgeColor',thisEdgeColor,'LineStyle',thisLineStyle);

            if options.plotRefTTA

                    if n==1  %ref neuron
                        [x,y]=Stepify(thisHistIndRef,yBase(nn)-thisHistRef/3);
                    else
                        [x,y]=Stepify(thisHistIndRef,yBase(nn)-thisHistRef);
                    end   

                    if sum(abs(thisHistRef))>0
                        plot(x(1:end-1),y(1:end-1),'b');
                    end

            end

            if isempty(options.clusterColoring)

                if options.barOutline

                    if n==1  %ref neuron
                        [x,y]=Stepify(thisHistInd,yBase(nn)-thisHist1/3);
                    else
                        [x,y]=Stepify(thisHistInd,yBase(nn)-thisHist1);
                    end                

                    plot(x(1:end-1),y(1:end-1),'r');

                    if n==1 && options.plotRefTTA
                        legend(options.legend);
                    end


                    hline(yBase(nn));

                else

                    if n==1  %ref neuron
                        hb=bar(thisHistInd,yBase(nn)-thisHist1'/3,1);
                    else
                        hb=bar(thisHistInd,yBase(nn)-thisHist1',1);
                    end

                end

            else %color by cluster

                if n==1  %ref neuron
                    hb{nn}=bar(thisHistInd,[yBase(nn)-thisHist1'/3,-thisHist2'/3],1,'stacked');
                else
                    hb{nn}=bar(thisHistInd,[yBase(nn)-thisHist1',-thisHist2'],1,'stacked');
                end

                set(hb{nn},'BaseValue',yBase(nn));
                set(hb{nn}(1),'FaceColor',[14 72 207]/255);
                set(hb{nn}(2),'FaceColor',[168 0 4]/255);
                set(hb{nn},'EdgeColor','none');            

            end    

            alpha(0.8);
            plotCount=plotCount+1;

    
    
            if options.showPercentages
                 text(10,yBase(nn)-3,[num2str( sum( GlobalTTAstruct.compiled.delays{sortIndex(n)}>options.timeRange(1)  & ...
                                                       GlobalTTAstruct.compiled.delays{sortIndex(n)}<options.timeRange(end))  / ...
                                        numel(GlobalTTAstruct.compiled.delays{sortIndex(n)})  ,2) ...
                    '(' num2str(numel(GlobalTTAstruct.compiled.delays{sortIndex(n)}))  ')'],...
                       'HorizontalAlignment','left','FontSize',8,'Color','r');         


                 if options.plotRefTTA
                     refn= find(strcmp(   GlobalTTAstruct.compiled.labels{sortIndex(n)},  refGlobalTTAstruct.compiled.labels));
                     if ~isempty(refn)

                             text(15,yBase(nn)-3,[num2str( sum( refGlobalTTAstruct.compiled.delays{refn}>options.timeRange(1)  & ...
                                                               refGlobalTTAstruct.compiled.delays{refn}<options.timeRange(end))  / ...
                                                numel(refGlobalTTAstruct.compiled.delays{refn})  ,2) ...
                            '(' num2str(numel(refGlobalTTAstruct.compiled.delays{refn}))  ')'],...
                               'HorizontalAlignment','left','FontSize',8,'Color','b'); 
                     end

                 end

            end
            nn=nn+1;
            validLabels=[validLabels GlobalTTAstruct.compiled.labels{sortIndex(n)}];
        end
    
    end


    xlabel(['Relative onset (s)']);
    set(gca,'XTick',options.timeRange(1):options.timeRange(end));

    ylim([yMin yBase(end)]);
    
    %xlim([-GlobalTTAstruct.runInfo.options.delayCutoff GlobalTTAstruct.runInfo.options.delayCutoff+5]);
    
    if options.plotRefTTA
        extraXaxis=5;
    else
        extraXaxis=10;
    end
    
    xlim([options.timeRange(1) options.timeRange(end)+extraXaxis]);
    
    set(gca,'YTick',yBase);
    set(gca,'YTickLabel',validLabels);
    set(gca,'FontSize',8);
    
    proplot;
    set(gca,'ticklength',0.3*get(gca,'ticklength'));
    vline(0);
end



if options.savePDF
    export_fig(['TTAHistos-' GlobalTTAstruct.runInfo.options.transitionTypes '-SortedBy' options.sortingMethod '.pdf']);
end

%end main



    function [modes, strength_1mode, strength_2modes, sortVals]=AssignGaussianModes(data)

        numN=length(data.gaussianFitData(1).neuron);

        hwpc=0.5;  %halfwidthForPeakCount in seconds

        modes=zeros(1,numN);
        strength_1mode=zeros(1,numN);
        strength_2modes=zeros(1,numN);
        sortVals=zeros(1,numN);  %compute a value to sort neurons by

        for n=1:numN

            strength_1mode(n)=  sum((data.delays{n}>data.gaussianFitData(1).neuron(n).mu(1)-hwpc  &  data.delays{n}<data.gaussianFitData(1).neuron(n).mu(1)+hwpc));

            if length(data.gaussianFitData(2).neuron(n).mu)==2
                strength_2modes(n)= sum((data.delays{n}>data.gaussianFitData(2).neuron(n).mu(1)-hwpc &  data.delays{n}<data.gaussianFitData(2).neuron(n).mu(1)+hwpc))+...
                                     sum((data.delays{n}>data.gaussianFitData(2).neuron(n).mu(2)-hwpc &  data.delays{n}<data.gaussianFitData(2).neuron(n).mu(2)+hwpc));
            else
                strength_2modes(n)=0; %no valid 2-gaussian fit
            end

            if strength_2modes(n)>strength_1mode(n)  &&  ...
                    data.gaussianFitData(2).neuron(n).sigma(1)+data.gaussianFitData(2).neuron(n).sigma(2) < abs( data.gaussianFitData(2).neuron(n).mu(1)-data.gaussianFitData(2).neuron(n).mu(2) )...
                && abs(data.gaussianFitData(2).neuron(n).mu(1)-data.gaussianFitData(2).neuron(n).mu(2))>1
                modes(n)=2;
            else
                modes(n)=1;
            end


            sortVals(n)=max([strength_1mode(n) strength_2modes(n)]);
        end
        
    end

        
end

