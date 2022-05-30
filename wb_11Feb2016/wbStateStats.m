function wbStateStatsStruct=wbStateStats(wbstructsFileListOrRootFolder,options,neuronStringsOrNumbers)

flagstr=[];

if nargin<2
    options=[];
end


if ~isfield(options,'stimulusAnalysisFlag')
    options.stimulusAnalysisFlag=false;
end


if ~isfield(options,'useFictiveSwitchTimes')
    options.useFictiveSwitchTimes=true;
end

if ~isfield(options,'useHints')
    options.useHints=true;
end

if ~isfield(options,'refNeuronOverride')
    options.refNeuronOverride=[];
end

if ~isfield(options,'sixStateFlag')
    options.sixStateFlag=false;
end


if ~isfield(options,'usePRLFlag')
    options.usePRLFlag=true;
    
end

if ~isfield(options,'useSMDFlag')
    options.useSMDFlag=true;
    
end

if options.usePRLFlag
    flagstr=[flagstr 'PRL'];
end

if options.usePRLFlag
    flagstr=[flagstr 'SMD'];
end

fieldName='deltaFOverF_bc';

if options.sixStateFlag 
   stateColors= {[0 0 .9];[ .9 0 0]; [0 .9 0]; [255 204 0]/255;  [0.9 0 0.9] ; [255 108 0]/255};  %1 2a 3 4a 2b 4b 
   stateLineWidths=[1 1 1 1 2 2 ];
else
   stateColors={[0 0 0.9];[0.9 0 0];[0 0.9 0];[255 204 0]/255}; 
   stateLineWidths=[1 1 1 1];
end



numStateColors=numel(stateColors);

markerType='none';
markerSize=12;



%parse inputs
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


if ~isfield(options,'refNeuron')
   options.refNeuron={'AVAL'};    %default if no refNeuron in hints
end

numTrials=length(wbstructFileList);


if options.sixStateFlag
            clusterKeys={[2 1],[1 1],[1 1],[2 1],[1 1],[1 1],[2 1]};
end

for i=1:numTrials
    disp(['loading ' wbstructFileList{i}]);
    wbstruct{i}=wbload(wbstructFileList{i},false);

    if options.useHints && exist([wbstructFileList{i} filesep 'Quant' filesep 'wbhints.mat'],'file')
        hints=load([wbstructFileList{i} filesep 'Quant' filesep 'wbhints.mat']);

        if isfield(hints,'stateRefNeuron') && ~isempty(hints.stateRefNeuron)
            options.refNeuron{i}=hints.stateRefNeuron;
        elseif isfield(hints,'AVA') && ~isempty(hints.AVA)
            options.refNeuron{i}=hints.AVA;
        else
            options.refNeuron{i}='AVAL';
        end

        disp(['using wbhints.mat file:  state reference neuron=' options.refNeuron{i}]);
    end

        
    if ~isempty(options.refNeuronOverride)
        disp(['overriding refNeuron with ' options.refNeuronOverride]);
        options.refNeuron{i}=options.refNeuronOverride;
    end
         
    neuronStringsOrNumbers{i}=options.refNeuron{i};

    
    if options.sixStateFlag
        
        CRS{i}=load([wbstructFileList{i} filesep 'Quant' filesep 'wbClusterRiseStruct.mat']);
        
        if options.usePRLFlag
            CRS{i}=CRS{i}.PRL;
            clusterKeys{i}=[];
        end
        
        CFS{i}=load([wbstructFileList{i} filesep 'Quant' filesep 'wbClusterFallStruct.mat']);
        if options.usePRLFlag
            CFS{i}=CFS{i}.SMD;
            clusterKeys{i}=[];
        end
    end
    
    
    
end




disp('wbStateStats> all wbstructs loaded.');


if options.useFictiveSwitchTimes
    for i=1:numTrials
        if isempty(wbstruct{i}.stimulus.switchtimes)
            wbstruct{i}.stimulus.switchtimes=[360   390   420   450   480   510   540   570   600   630   660   690];
        end
    end
end



%parse options
if ~isfield(options,'ranges')
    for i=1:numTrials
%         options.ranges{1,i}=[1:floor(size(wbstruct{i}.simple.deltaFOverF,1)/2)];
%         options.ranges{2,i}=[1+floor(size(wbstruct{i}.simple.deltaFOverF,1)/2): size(wbstruct{i}.simple.deltaFOverF,1)];
%         
        options.ranges{1,i}=1:find(wbstruct{i}.simple.tv>360,1,'first');
        endRange2Frame=find(wbstruct{i}.simple.tv>=720,1,'first');
        if isempty(endRange2Frame)
            endRange2Frame=length(wbstruct{i}.simple.tv);
        end
        options.ranges{2,i}=(1+find(wbstruct{i}.simple.tv>360,1,'first')):endRange2Frame;
        
        
        if options.stimulusAnalysisFlag
            
            %segmented stimulus ranges
            for j=1:11  
                options.ranges{j+2,i}=find(wbstruct{i}.simple.tv>=wbstruct{i}.stimulus.switchtimes(j),1,'first') :  ...
                                     find(wbstruct{i}.simple.tv>=wbstruct{i}.stimulus.switchtimes(j+1),1,'first')  ;                               
            end
            options.ranges{14,i}=find(wbstruct{i}.simple.tv>=wbstruct{i}.stimulus.switchtimes(12),1,'first'):endRange2Frame;

        end
        
    end
end


if ~isfield(options,'epochNames')
    options.epochNames={'pre','post','post1','post2','post3','post4',...
                              'post5','post6','post7','post8'...
                              'post9','post10','post11','post12'};
end



if ~isfield(options,'plotFlag')
    options.plotFlag=true;
end

if ~isfield(options,'statType')
    options.statType='all';
end



if ~isfield(options,'dataGroupName')
    thisFolder=pwd;
    slashes=strfind(thisFolder,'/');
    options.dataGroupName=thisFolder(slashes(end)+1:end);
end


if ~isfield(options,'statParams')
    options.statParams{1}='SignedAllRises';
    options.statParams{2}='SignedAllFalls';
end


if ~isfield(options,'savePDFFlag')
    options.savePDFFlag=false;
end

if ~isfield(options,'savePDFDirectory')
    options.savePDFDirectory=[pwd filesep 'Quant'];
end


if ischar(neuronStringsOrNumbers)
    for i=1:numTrials
        [trace{i},~,neuronNumbers{i}]=wbgettrace(neuronStringsOrNumbers,wbstruct{i});
    end
else

    for i=1:numTrials        
        [trace{i},~,neuronNumbers{i}]=wbgettrace(neuronStringsOrNumbers{i},wbstruct{i});
    end
end



wbStateStatsStruct.options=options;

if options.plotFlag
    figure('Position',[0 0 1000 800]);
end

%compile stats

wbStateStatsStruct.transitionTimesAllTrials=[];
wbStateStatsStruct.transitionFallTimesAllTrials=[];
for i=1:numTrials

    wbStateStatsStruct.stimTimeVector{i}=wbgetstimcoloring(wbstruct{i});
    
    if ischar(neuronStringsOrNumbers)
       wbStateStatsStruct.refNeuron{i}=neuronStringsOrNumbers;
    else
       wbStateStatsStruct.refNeuron{i}=neuronStringsOrNumbers{i};
    end
    wbStateStatsStruct.trialName{i}=wbstruct{i}.trialname;
    wbStateStatsStruct.fps(i)=wbstruct{i}.fps;
    wbStateStatsStruct.tv{i}=wbstruct{i}.tv;

    wbStateStatsStruct.refTrace{i}=wbgettrace(wbStateStatsStruct.refNeuron{i},wbstruct{i});
    
    if ischar(neuronStringsOrNumbers)
       [traceColoring, transitionListCellArray,transitionPreRunLengthArray]=wbFourStateTraceAnalysis(wbstruct{i},'useSaved',neuronStringsOrNumbers);
    else
       [traceColoring, transitionListCellArray,transitionPreRunLengthArray]=wbFourStateTraceAnalysis(wbstruct{i},'useSaved',neuronStringsOrNumbers{i});
    end
    
    
    if options.sixStateFlag
        
        
        [F2FMat{i},R2RMat{i},~]=wbGetTransitionRanges(transitionListCellArray);
        TRM{i}=F2FMat{i};
        TFM{i}=R2RMat{i};
% i
% CRS{i}
% CFS{i}
        traceColoring=wbConvertFourToSixStateColoring(traceColoring,TRM{i},TFM{i},CRS{i},CFS{i},clusterKeys{i});
        
    end
    

    
    if strcmp(options.statType,'countTransitions') || strcmp(options.statType,'all')

        transitionTypes=options.statParams{1};
        transitionTypes2=options.statParams{2};
         
        %transitionIndices,transitionTimes
        wbStateStatsStruct.transitionIndices{i}=wbGetTransitions(transitionListCellArray,1,transitionTypes);
        
        wbStateStatsStruct.transitionTimes{i}=wbstruct{i}.tv(wbStateStatsStruct.transitionIndices{i});
        wbStateStatsStruct.transitionTimesAllTrials=[wbStateStatsStruct.transitionTimesAllTrials; wbStateStatsStruct.transitionTimes{i}];       
        
        wbStateStatsStruct.transitionFallIndices{i}=wbGetTransitions(transitionListCellArray,1,transitionTypes2);
        wbStateStatsStruct.transitionFallTimes{i}=wbstruct{i}.tv(wbStateStatsStruct.transitionFallIndices{i});
        wbStateStatsStruct.transitionFallTimesAllTrials=[wbStateStatsStruct.transitionFallTimesAllTrials; wbStateStatsStruct.transitionFallTimes{i}];       
        
        
        if options.stimulusAnalysisFlag
            
            for r=1:size(options.ranges,1)
                %limit to ranges
                wbStateStatsStruct.transitionsWithin{r,i}=find(wbStateStatsStruct.transitionIndices{i}>options.ranges{r,i}(1) & ...
                                                                 wbStateStatsStruct.transitionIndices{i}<options.ranges{r,i}(end) );     
                wbStateStatsStruct.numTransitionsWithin(r,i)=length(wbStateStatsStruct.transitionsWithin{r,i});


                wbStateStatsStruct.transitionFallsWithin{r,i}=find(wbStateStatsStruct.transitionFallIndices{i}>options.ranges{r,i}(1) & ...
                                                                 wbStateStatsStruct.transitionFallIndices{i}<options.ranges{r,i}(end) );     
                wbStateStatsStruct.numTransitionFallsWithin(r,i)=length(wbStateStatsStruct.transitionFallsWithin{r,i});


            end
            
        end
        
        wbStateStatsStruct.traceColoring{i}=traceColoring;
        
        minRunLength=0;
        %stateLengths
        for j=1:4
            [wbStateStatsStruct.stateFrameLengths{i,j}, wbStateStatsStruct.stateRunStartIndices{i,j}]=RunLengths(wbStateStatsStruct.traceColoring{i}==j);
            wbStateStatsStruct.stateLengths{i,j}=wbStateStatsStruct.stateFrameLengths{i,j}/wbStateStatsStruct.fps(i);
            wbStateStatsStruct.stateLengths{i,j}(wbStateStatsStruct.stateLengths{i,j}<minRunLength)=[];
            for k=1:size(options.ranges,1)
                [wbStateStatsStruct.stateFrameLengthsWithin{k,i,j},  wbStateStatsStruct.stateRunStartIndicesWithin{k,i,j}]=RunLengths(wbStateStatsStruct.traceColoring{i}(options.ranges{k,i})==j);
                wbStateStatsStruct.stateLengthsWithin{k,i,j}=wbStateStatsStruct.stateFrameLengthsWithin{k,i,j}/wbStateStatsStruct.fps(i);
                wbStateStatsStruct.stateLengthsWithin{k,i,j}(wbStateStatsStruct.stateLengthsWithin{k,i,j}<minRunLength)=[];
            end
        end
        
        %riseMagnitudes, riseMaxSlope 
        riseState=2;
        n=neuronNumbers{i};
        
        for j=1:length(wbStateStatsStruct.stateRunStartIndices{i,riseState})

            wbStateStatsStruct.riseMagnitudes{i}(j)=wbstruct{i}.simple.(fieldName)( wbStateStatsStruct.stateRunStartIndices{i,riseState}(j)+wbStateStatsStruct.stateFrameLengths{i,riseState}(j)-1,n)  -  ...
                                                    wbstruct{i}.simple.(fieldName)( wbStateStatsStruct.stateRunStartIndices{i,riseState}(j),n);
            wbStateStatsStruct.riseMaxSlopes{i}(j)=max(wbstruct{i}.simple.derivs.traces( wbStateStatsStruct.stateRunStartIndices{i,riseState}(j):...
                wbStateStatsStruct.stateRunStartIndices{i,riseState}(j)+wbStateStatsStruct.stateFrameLengths{i,riseState}(j)-1 , n));
        
            
            
            
        end
        
        if options.stimulusAnalysisFlag
            
            for k=1:size(options.ranges,1)
                 validRunIndices=find(wbStateStatsStruct.stateRunStartIndices{i,riseState}> options.ranges{k,i}(1)  & ...
                                      wbStateStatsStruct.stateRunStartIndices{i,riseState}< options.ranges{k,i}(end));
                 wbStateStatsStruct.riseMagnitudesWithin{k,i}=wbStateStatsStruct.riseMagnitudes{i}(validRunIndices);
                 wbStateStatsStruct.riseMaxSlopesWithin{k,i}=wbStateStatsStruct.riseMaxSlopes{i}(validRunIndices);
            end
            
        end
        
        
    end 

    
    if options.plotFlag
        nc=1;
        subtightplot(numTrials,nc,i,[.02 .01]);
        
        if options.stimulusAnalysisFlag && isfield(wbstruct{i},'stimulus')
            for st=1:floor(length(wbstruct{i}.stimulus.switchtimes)/2)
                rectangle('Position',[wbstruct{i}.stimulus.switchtimes(2*st-1), -1,  ...
                    wbstruct{i}.stimulus.switchtimes(2*st)- wbstruct{i}.stimulus.switchtimes(2*st-1),2],...
                    'FaceColor',[0.8 0.8 0.8],'EdgeColor','none');
            end
        end
        hold on;
        
        
        for st=1:numStateColors
            
            coloredData=zero2nan( double( traceColoring==st )  );
        
            
            handles.statePlot(i,st)=plot(wbStateStatsStruct.tv{i},coloredData.*trace{i},'Color',stateColors{st},'LineWidth',stateLineWidths(st),'Marker',markerType,'MarkerSize',markerSize,'HitTest','off');
            set(handles.statePlot(i,st),'HitTest','off');         
            hold on;

        end            
            
%base('tc',traceColoring)
  
        set(gca,'XTick',0:10:wbStateStatsStruct.tv{i}(end));
        xTickLabel={'0','',''};
        for k=30:30:wbStateStatsStruct.tv{i}(end)
            xTickLabel=[xTickLabel num2str(k)  {''} {''}];
        end
        set(gca,'XTickLabel',xTickLabel);
        
        xlim([0 wbStateStatsStruct.tv{i}(end)]);
        %grid on;
        intitleHandle=intitle(strrep(wbStateStatsStruct.trialName{i},'_','\_'));
        set(intitleHandle,'Color','r');
        
        if i==1
            if ischar(neuronStringsOrNumbers)         
               title([strrep(options.dataGroupName,'_','\_') ' ref:' neuronStringsOrNumbers ' ' flagstr]);
            else
               title([strrep(options.dataGroupName,'_','\_') ' ref:MIXED ' flagstr]);
            end
        end
    end
    
end

save(['wbStateStatsStruct' options.refNeuronOverride flagstr '.mat'],'-struct','wbStateStatsStruct');
    
if options.plotFlag
    export_fig(['wbStateStatsTraces-' options.dataGroupName options.refNeuronOverride '.pdf'],'-nocrop');    
end

end %main