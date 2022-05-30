function [sortOrder,sortExtraData,colorRange]=wbHeatPlot(wbstructOrFolder,options)

if nargin<1 || isempty(wbstructOrFolder)
    wbstructOrFolder=pwd;
end

if ischar(wbstructOrFolder)
    wbstruct={wbload(wbstructOrFolder)};
elseif isstruct(wbstructOrFolder)
    wbstruct={wbstructOrFolder};
elseif iscell(wbstructOrFolder)  %cell array of structs
    wbstruct=wbstructOrFolder;
end


if (nargin<2) options=[]; end


if ~isfield(options,'subPlotFlag')
    options.subPlotFlag=false;
end

if ~isfield(options,'sortMethod')
    options.sortMethod='position'; %'power'
end

if ~isfield(options,'sortParam')
    options.sortParam=[]; 
end

if ~isfield(options,'neuronSubset')
    options.neuronSubset=[]; 
end

if ~isfield(options,'neuronSigns')
    options.neuronSigns=[]; 
end

if ~isfield(options,'staggerLabels')  %overrides range
   options.staggerLabels=false;
end

if ~isfield(options,'savePDFFlag')
   options.savePDFFlag=false;
end

if ~isfield(options,'saveTIFFlag')
   options.saveTIFFlag=false;
end

if ~isfield(options,'saveFIGFlag')
   options.saveFIGFlag=false;
end

if ~isfield(options,'saveFigCopyDirectory')
   options.saveFigCopyDirectory='';
end

if ~isfield(options,'titlePrefix')
    options.titlePrefix='';
end

if ~isfield(options,'range')
   options.range=1:length(wbstruct{1}.tv);
end

if ~isfield(options,'rangeLimits')  %overrides range
   options.rangeLimits=[];
end

if ~isfield(options,'timeZeros')
    options.timeZeros=zeros(length(options.rangeLimits(:))/2,1);
end

if ~isfield(options,'normalizeType')
    options.normalizeType='peakdr';
end


if ~isfield(options,'multiColumnPlotFlag')
    options.multiColumnPlotFlag=false;
end

if ~isfield(options,'multiColumnPlotFields')
    options.multiColumnPlotFields={'deltaFOverF','derivs','stateColor'};
end


if ~isempty(options.rangeLimits)
    if size(options.rangeLimits,1)==1
        options.range=options.rangeLimits(1):options.rangeLimits(2);
        multiRangeFlag=false;
    else
        multiRangeFlag=true;
        assert(mod(length(options.rangeLimits(:)),2)==0);  %check evenness

    end
else
    multiRangeFlag=false;
end


if ~isfield(options,'colorRange')
   options.colorRange='autoscale';
end

if ~isfield(options,'colorRangeColumn2')
    options.colorRangeColumn2=options.colorRange;
end


if ~isempty(options.neuronSubset)

 
    dataSet=[];
    transitionList=[];
    for i=1:length(wbstruct)
         [traces{i},traceSimpleIndices{i}]=wbGetTraces(wbstruct{i},[],[],options.neuronSubset);
      
         if isfield(options,'numTransitionsinTrial')
             dataSet=[dataSet i*ones(1,options.numTransitionsInTrial(i))];
             transitionList=[transitionList 1:options.numTransitionsInTrial(i)];
         end
         
         %peaknorm
         if strcmp(options.normalizeType,'peakTrace')
             disp('peaknorming.');
             for j=1:size(traces{i},2)
                traces{i}(:,j)=traces{i}(:,j)/max(traces{i}(:,j));
             end     
         end
         
    end
    
    if isfield(options,'numTransitionsinTrial')

        dataSet=dataSet(options.sorting);  %need to clear up this vague variable scheme
        transitionList=transitionList(options.sorting);
        clusterLabels=options.clusterLabels(options.sorting);
        
    end
   

    if options.multiColumnPlotFlag
        
        if strcmp(options.multiColumnPlotFields{3},'stateColor')
            
            
            for i=1:length(wbstruct)
               [traceColoring{i}, ~, ~]=wbFourStateTraceAnalysis(wbstruct{i},'useSaved');
               traces3{i}=traceColoring{i}(:,traceSimpleIndices{i});
               
            end
            
        end
    
        for i=1:length(wbstruct)
           traces2{i}=wbstruct{i}.simple.derivs.traces(:,traceSimpleIndices{i});
         
        end
        
    else
        
        [traces{1}, sortOrder, ~, sortExtraData]=wbSortTraces(traces{1},options.sortMethod,[],options.sortParam);
        
    end
     
else
    
    %exclude and sort traces
    traces_unsorted=wbstruct{1}.deltaFOverF;
    
    %use BC traces
    traces_unsorted=zeros(size(traces_unsorted));
    traces_unsorted(:,wbstruct{1}.simple.nOrig)=wbstruct{1}.simple.deltaFOverF_bc;

    
    
    
    if isfield(wbstruct{1},'exclusionList')
        traces_unsorted(:,wbstruct{1}.exclusionList)=[];
    end
        
    [traces{1}, sortOrder, ~, sortExtraData]=wbSortTraces(traces_unsorted,options.sortMethod);
end
    

numPlotsPerFigure=10;
stateColors=[0 0 1;1 0 0;0 1 0;1 1 0];
   
for i=1:size(traces{1},2)
    
    yLabels{i}=num2str(i);
    
    if options.staggerLabels && mod(i,2)
        yLabels{i}=[ yLabels{i} '......'];
    end
    
end

    if ~multiRangeFlag 
        
        if ~options.subPlotFlag
            figure('Position',[0 0 800 1000]);
        end


        
        if ischar(options.colorRange)  %autoscale
            options.colorRange=[0.05*(-max(traces{1}(:))+ min(traces{1}(:)))   + min(traces{1}(:)), 0.75*max(traces{1}(:))];
        end
            
        colorRange=options.colorRange;

        imf=imagesc(wbstruct{1}.tv(options.range),1:size(traces{1},2),traces{1}(options.range,:)',options.colorRange); 

        xlabel('time (s)'); ylabel('neuron');

        set(gca,'XTick',0:60:wbstruct{1}.tv(end));
        set(gca,'YTick',1:size(traces{1},2));
        set(gca,'YTickLabel',yLabels);
        
        wbplotstimulus(wbstruct{1},false,'k',[],'lines');

        if ~options.subPlotFlag
          title([wbstruct{1}.displayname '   sorted by ' options.sortMethod ' ']);
        end
         
        if (options.savePDFFlag)
            export_fig([pwd filesep 'Quant' filesep options.titlePrefix 'HeatPlot-' wbMakeShortTrialname(wbstruct{1}.trialname) '-' options.sortMethod '.pdf']);

            if ~isempty(options.saveFigCopyDirectory)
                export_fig([options.saveFigCopyDirectory filesep options.titlePrefix 'HeatPlot-' wbMakeShortTrialname(wbstruct{1}.trialname) '-' options.sortMethod  '.pdf']);
            end   
        end
        

    else  %multi-ranges, multi wbstructs
        
        %currently uses RenderMatrix instead of imagesc, could make an
        %option
            
        
        if (options.multiColumnPlotFlag) 
            nc=length(options.multiColumnPlotFields); 
        else nc=1; 
        end
              
        

        allNumRanges=length(options.rangeLimits(:))/2;
        

        rr=1;

        if ~isempty(options.neuronSigns)
            for i=1:length(wbstruct)
                traces{i}=traces{i}*diag(options.neuronSigns);   %flip negative signed neurons
            end
        end
             
        
        
        for fi=1:ceil(allNumRanges/numPlotsPerFigure)

            if ~options.subPlotFlag
                figure('Position',[0 0 800 1000]);
            end
            

             if fi<ceil(allNumRanges/numPlotsPerFigure)
                thisNumPlots=numPlotsPerFigure;
             else
                 thisNumPlots=mod(allNumRanges,numPlotsPerFigure);
             end
             
             for i=1:thisNumPlots

                subtightplot(10,nc, nc*i-2,[0.01 0.01],[.05 .05],[.075 .05]);

                
                   
                
                thisRangeLimit=[options.rangeLimits(rr,1) options.rangeLimits(rr,2)];
                thisFrameRange=(time2frame(wbstruct{dataSet(rr)}.tv,thisRangeLimit(1))-1):time2frame(wbstruct{dataSet(rr)}.tv,thisRangeLimit(2));


                if strcmp(options.normalizeType,'peakdr');

                        for j=1:size(traces{dataSet(rr)},2);
                            traces{dataSet(rr)}(:,j)=traces{dataSet(rr)}(:,j)-min(traces{dataSet(rr)}(thisFrameRange,j));
                            traces{dataSet(rr)}(:,j)=traces{dataSet(rr)}(:,j)/max(traces{dataSet(rr)}(thisFrameRange,j));
                        end

                end

                if ischar(options.colorRange)
                  % imf=imagesc(wbstruct.tv(thisFrameRange)-options.timeZeros(rr),1:size(traces,2),traces(thisFrameRange,:)'); 
                    RenderMatrix(traces{dataSet(rr)}(thisFrameRange,:)',[],[],[],wbstruct{dataSet(rr)}.tv(thisFrameRange)-options.timeZeros(rr),1:size(traces{dataSet(rr)},2)); 
                  
                else
                    %imf=imagesc(wbstruct.tv(thisFrameRange)-options.timeZeros(rr),1:size(traces,2),traces(thisFrameRange,:)',options.colorRange); 
                    RenderMatrix(traces{dataSet(rr)}(thisFrameRange,:)',options.colorRange,[],[],wbstruct{dataSet(rr)}.tv(thisFrameRange)-options.timeZeros(rr),1:size(traces{dataSet(rr)},2)); 

                    
                end
                
                set(gca,'TickDir','out');
                set(gca,'YTick',1:size(traces{dataSet(rr)},2));
                set(gca,'YTickLabel',options.neuronSubset);
                set(gca,'FontSize',6);


                SmartTimeAxis([thisRangeLimit(1) thisRangeLimit(end)]-options.timeZeros(rr));
                if i<10 
                    set(gca,'XTickLabel',[]); 
                else
                    xlabel('time (s)');
                    ylabel('neuron');
                end
                
                if i==1 title('\DeltaF-F0/Fmax-F0'); end

                %COLUMN 2
                subtightplot( 10,nc, nc*i-1,[0.01 0.01],[.05 .05],[.075 .05]);
                

                
                if strcmp(options.normalizeType,'peakdr');
 
                        for j=1:size(traces2{dataSet(rr)},2);
                            traces2{dataSet(rr)}(:,j)=traces2{dataSet(rr)}(:,j)-min(traces2{dataSet(rr)}(thisFrameRange,j));
                            traces2{dataSet(rr)}(:,j)=traces2{dataSet(rr)}(:,j)/max(traces2{dataSet(rr)}(thisFrameRange,j));
                        end

                end
                

                if ischar(options.colorRangeColumn2)
                    %imf=imagesc(wbstruct.tv(thisFrameRange)-options.timeZeros(rr),1:size(traces2,2),traces2(thisFrameRange,:)'); 
                    RenderMatrix(traces2{dataSet(rr)}(thisFrameRange,:)',[],[],[],wbstruct{dataSet(rr)}.tv(thisFrameRange)-options.timeZeros(rr),1:size(traces2{dataSet(rr)},2)); 

                else
                    %imf=imagesc(wbstruct.tv(thisFrameRange)-options.timeZeros(rr),1:size(traces2,2),traces2(thisFrameRange,:)',options.colorRangeColumn2); 
                    RenderMatrix(traces2{dataSet(rr)}(thisFrameRange,:)',options.colorRangeColumn2,[],[],wbstruct{dataSet(rr)}.tv(thisFrameRange)-options.timeZeros(rr),1:size(traces2{dataSet(rr)},2)); 

                end
                
                set(gca,'TickDir','out');
                SmartTimeAxis([thisRangeLimit(1) thisRangeLimit(end)]-options.timeZeros(rr));

                if i<10 
                    set(gca,'XTickLabel',[]); 
                else
                    xlabel('time (s)');
                end
                set(gca,'YTickLabel',[]);

                if i==1 title('norm. deriv'); end
               
                %COLUMN 3
                subtightplot( 10,nc, nc*i,[0.01 0.01],[.05 .05],[.075 .05]);              
                RenderMatrix(traces3{dataSet(rr)}(thisFrameRange,:)',[],[],stateColors,wbstruct{dataSet(rr)}.tv(thisFrameRange)-options.timeZeros(rr),1:size(traces3{dataSet(rr)},2)); 

                set(gca,'TickDir','out');
                set(gca,'yaxislocation','right');
                
                ylabel([num2str(dataSet(rr)) '#' num2str(transitionList(rr)) ' -> C' num2str(clusterLabels(rr))]);
                
                SmartTimeAxis([thisRangeLimit(1) thisRangeLimit(end)]-options.timeZeros(rr));

                if i<10 
                    set(gca,'XTickLabel',[]); 
                end
                if i==1 title('state color'); end
                
                rr=rr+1;   
                
             end
             

             if length(wbstruct)>1
                 titleSuffix=[num2str(length(wbstruct)) 'trials'];
             else   
                 titleSuffix=wbMakeShortTrialname(wbstruct.trialname);
             end
             
             mtit([titleSuffix ': page ' num2str(fi) '/' num2str(ceil(allNumRanges/numPlotsPerFigure))],'yoff',.025);
             
             if (options.savePDFFlag)
                
                if fi==1  %start a new pdf
                     export_fig([pwd filesep options.titlePrefix 'HeatPlot-' titleSuffix '-' options.sortMethod '.pdf']);
                else
                     export_fig([pwd filesep options.titlePrefix 'HeatPlot-' titleSuffix '-' options.sortMethod '.pdf'],'-append');
                end
                
                if ~isempty(options.saveFigCopyDirectory)
                    export_fig([options.saveFigCopyDirectory filesep options.titlePrefix 'HeatPlot-' titleSuffix '-' options.sortMethod  '.pdf']);
                end
                
             end       
        end
    end
    
    if (options.saveTIFFlag)
        export_fig([pwd filesep options.titlePrefix 'HeatPlot-' wbMakeShortTrialname(wbstruct.trialname) '-' options.sortMethod],'-tif','-a1');
        
        if ~isempty(options.saveFigCopyDirectory)
            export_fig([options.saveFigCopyDirectory filesep options.titlePrefix 'HeatPlot-' wbMakeShortTrialname(wbstruct.trialname) '-' options.sortMethod],'-tif','-a1');
        end
    end
    
    if (options.saveFIGFlag)
        saveas(imf, [pwd filesep options.titlePrefix 'HeatPlot-' wbMakeShortTrialname(wbstruct.trialname) '-' options.sortMethod '.fig'], 'fig');
        
        if ~isempty(options.saveFigCopyDirectory)
            saveas(imf, [options.saveFigCopyDirectory filesep options.titlePrefix 'HeatPlot-' wbMakeShortTrialname(wbstruct.trialname) '-' options.sortMethod  '.fig'], 'fig');
        end
    end
        

    

end