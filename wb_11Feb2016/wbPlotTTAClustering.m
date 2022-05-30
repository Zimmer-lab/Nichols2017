function [outStruct,thisFigureHandle]=wbPlotTTAClustering(TTAStructFileName,options)
%wbTTACluster(TTAStructFileName,options)
%cluster TTA data
%
%
%for multi-trial data, one neuronSubset will be used across all datasets
%

%% prelims 
flagstr=[];

if nargin<2
    options=[];
end

if ~isfield(options,'useHints')
    options.useHints=true;
end

if ~isfield(options,'multiTrialFlag')
    options.multiTrialFlag=true;
end 

if ~isfield(options,'multiTrialDir')
    options.multiTrialDir=pwd;
end

if options.multiTrialFlag
    folderList=listfolders(options.multiTrialDir,true);   %this is a multi-dataset parent folder
end

if ~isfield(options,'interactiveMode')
    options.interactiveMode=false;
end

if ~isfield(options,'saveDirectory')
    if exist('Quant','dir')
        options.saveDirectory=[pwd filesep 'Quant'];
    else
        options.saveDirectory=pwd;
    end
end

if ~isfield(options,'showUnclusteredMatrix')
    options.showUnclusteredMatrix=false;
end

if ~isfield(options,'saveFlag')
    if  options.interactiveMode
        options.saveFlag=false;
    else
        options.saveFlag=true;
    end
end

if ~isfield(options,'originatingFigureHandle')
    options.originatingFigureHandle=[];
end

if ~isfield(options,'existingFigureHandle')
    options.existingFigureHandle=[];
end

if isempty(options.existingFigureHandle)
    firstLaunchFlag=true;
else
    firstLaunchFlag=false;
end

if ~isfield(options,'transitionTypes')
    options.transitionTypes='SignedAllRises';
end

if nargin<1 || isempty(TTAStructFileName)
    
    
    if strcmpi(options.transitionTypes,'SignedAllFalls') && exist([pwd filesep 'Quant' filesep 'wbTTAFallStruct.mat'],'file')  && options.multiTrialFlag==false
        
        TTAStructFileName=[pwd filesep 'Quant' filesep 'wbTTAFallStruct.mat'];
        TTAStruct{1}=load(TTAStructFileName); 
        disp('wbTTACluster> wbTTAFallStruct.mat loaded.');
        
    elseif strcmpi(options.transitionTypes,'SignedAllRises') && exist([pwd filesep 'Quant' filesep 'wbTTAStruct.mat'],'file') && options.multiTrialFlag==false
    
        TTAStructFileName=[pwd filesep 'Quant' filesep 'wbTTAStruct.mat'];
        TTAStruct{1}=load(TTAStructFileName); 
        disp('wbTTACluster> wbTTAStruct.mat loaded.');
        
    else  %multiStruct
        
        disp('wbTTACluster> multistruct.');
        options.multiTrialDir
        folders=listfolders(options.multiTrialDir,true)
        for d=1:numel(folders)
            
            if strcmpi(options.transitionTypes,'SignedAllFalls')
                
                TTAStructFileName=[folders{d} filesep 'Quant' filesep 'wbTTAFallStruct.mat'];
                TTAStruct{d}=load(TTAStructFileName);
        
            else
                
                TTAStructFileName=[folders{d} filesep 'Quant' filesep 'wbTTAStruct.mat'];
                TTAStruct{d}=load(TTAStructFileName);                
                
                
            end
            
        end

        if ~isfield(options,'neuronSubset')
            options.neuronSubset=wbListIDsInCommon(folders,'intersection');
        end
        
    end
            
else
    
   TTAStruct{1}=load(TTAStructFileName); 
    
end

%SET multiTrialFlag
if numel(TTAStruct)>1
    multiTrialFlag=true;
    flagstr=[flagstr '-multitrial'];
else
    multiTrialFlag=false;
end


if ~isfield(options,'wbDir');
    

    if exist([pwd filesep 'Quant'],'dir') && options.multiTrialFlag==false %this is a single dataset folder
        
        options.wbDir=pwd;
        
    else
        
        options.wbDir=folderList{1};
        disp(['wbTTACluster> Using ' folderList{1} ' as reference wb folder']);
        
    end
           
end


if ~isfield(options,'refWBstruct')
    
    refWBstruct=wbload(options.wbDir,false);
    if isempty(refWBstruct) 
        refWBstruct=wbload([],false);
    end
else
    refWBstruct=options.refWBstruct;   
end


if ~isfield(options,'neuronSubset')
    
    options.neuronSubset=wbListIDs(refWBstruct);   %will already be loaded if multi
end



if ~isfield(options,'activeNeuronFlags');
    options.activeNeuronFlags=[];
end

if ~isfield(options,'inPhaseNeuronFlags')
    options.inPhaseNeuronFlags=[];
end

if ~isfield(options,'neuronExclusions')
    options.neuronExclusions={};
end

if ~isfield(options,'refNeuron') || isempty(options.refNeuron)
    options.refNeuron={'AVAL'};    %default if no refNeuron in hints
    if options.useHints 
        
        if multiTrialFlag

            for d=1:numel(folderList)
                
                if exist([folderList{d} filesep 'Quant' filesep 'wbhints.mat'],'file')

                    hints{d}=load([folderList{d} filesep 'Quant' filesep 'wbhints.mat']);
                    if isfield(hints{d},'stateRefNeuron') && ~isempty(hints{d}.stateRefNeuron)
                        options.refNeuron{d}=hints{d}.stateRefNeuron;
                        disp(['wbTTACluster> using wbhints.mat file:  state reference neuron=' options.refNeuron{d}]);
                    end        

                end

            end

        else

            if exist(['Quant' filesep 'wbhints.mat'],'file')

                hints=wbHints; %load wbhints.mat
                if isfield(hints,'stateRefNeuron') && ~isempty(hints.stateRefNeuron)
                    options.refNeuron={hints.stateRefNeuron};
                    disp(['wbTTACluster> using wbhints.mat file:  state reference neuron=' options.refNeuron]);
                end        

            end

        end
        
    end
      
elseif ischar(options.refNeuron)
    options.refNeuron={options.refNeuron};
end

if ~isfield(options,'plotFlag')
    options.plotFlag=false;
end

if ~isfield(options,'subPlotFlag')
    options.subPlotFlag=false;
end


if ~isfield(options,'rotatePlot')
    options.rotatePlot=false;
end

if ~isfield(options,'savePDFFlag')
    options.savePDFFlag=true;
end



%%globals
 valuesBinary=[];
 valuesSign=[];
 inputValues=[];
 valuesForPlotting=[];
 numClusters=[];
 valuesSupplement=[];
 datasetMembership=[];
 
handles=[];
algorithmStringList={'kmeans','kmeansTwoStage','hierarchical','preRunLength'};
maxClusterStringList={'1','2','3','4','5','6','7','8'};
distanceMeasureStringList={'cityblock','sqeuclidean','cosine'};
quantizationStringList={'none','binary','trinary','precluster'};
        
OOBRvalStartingVal=10;
distanceMeasureStartingValue=1;
quantizationStartingValue=1;

quantization=quantizationStartingValue;
cutoffTime1=7;
cutoffTime2=7;
OOBRval=OOBRvalStartingVal;



%remove excluded neurons from clustering input
for i=1:length(options.neuronExclusions)
     options.neuronSubset(find(strcmpi(options.neuronSubset,options.neuronExclusions{i})))=[];
end
    
%% compile input data points in values (dxn)

GetInputData;



%% plots
%NEED TO REMOVE dependencies on .compiled
     
        if ~options.subPlotFlag
            figure('Position',[0 0 1200 800]);
        end
     
        cLim=[-7 7];
        cMap=jet; %bipolar(201,0.9);
        
        if options.showUnclusteredMatrix
            
            subtightplot(2,1,1,[0.1 .05],[.1 .1],[.05 .02]);

            RenderMatrix(values(meanSortIndex,:),cLim,casedLabels(meanSortIndex),cMap);
     %       set(gca,'XTick',1:length(TTAStruct.compiled.datasetNumber{1}));
     %       set(gca,'XTickLabel',TTAStruct.compiled.datasetNumber{1});
     %       trialNames= [ char([TTAStruct.runInfo.dataSets(:)]')' ;repmat('  ',length(TTAStruct.runInfo.dataSets),1)' ];

    %        title(['unclustered: ' trialNames(:)' ]);
            xlabel('dataset');
        
            subtightplot(2,1,2,[0.1 .05],[.1 .1],[.05 .02]);

        else
            if ~options.subPlotFlag
                subtightplot(2,1,2,[0.1 .05],[.1 .1],[.05 .02]);
            end
        end
        
        
        sortIndex=1:size(values,2);
        
        RenderMatrix(values(meanSortIndex,sortIndex),cLim,casedLabels(meanSortIndex),cMap);
  %      set(gca,'XTick',1:length(TTAStruct.compiled.datasetNumber{1}));
        
        
        
        %dataset and transition number
%         for i=1:length(sortIndex)
%             
%             xTL{i}= [ num2str(TTAStruct.compiled.datasetNumber{1}(sortIndex(i))) ',' num2str(TTAStruct.compiled.transitionNumbers{1}(sortIndex(i)))  ];
%         end
            
        %ylabel([num2str(dataSet(rr)) '#' num2str(transitionList(rr)) ' -> C' num2str(clusterLabels(rr))]);

        
%         set(gca,'XTickLabel',xTL);
%         rotateXLabelsImage(gca,90);

%        title(['clustered measure: ' options.distanceMeasure ]);
%        xlabel('dataset');

        RenderMatrixColorbar('Middle','Left','Horizontal',cLim(1):cLim(2),cMap);
        xlabel('time (s)');

        axes('Position',[.05 .04 .93 .02]);
        RenderMatrix(outStruct.clusterMembership(sortIndex)');
        set(gca,'XTick',1:length(outStruct.clusterMembership'));
        set(gca,'XTickLabel',outStruct.clusterMembership(sortIndex)');
        xlabel(['clusters (max' options.maxClusters  ' )']);
        
        if options.rotatePlot
            view([90 90]);
        end
        
        if options.savePDFFlag
            export_fig(['TTACluster-' options.transitionTypes '.pdf']);
        end
        
        %%compile heatmaps
%         HPTTAoptions.clusterLabels=outStruct.clusterMembership';
%         HPTTAoptions.sorting=sortIndex;
%         HPTTAoptions.neuronSubset=casedLabels(meanSortIndex);
%         HPTTAoptions.neuronSigns=options.neuronSigns;
%         wbHeatPlotTTA(options.refNeuron,listfolders(pwd),HPTTAoptions);



 %END MAIN
 
 
 
 
 
 
 
%% subfunctions
 
function GetInputData
    
size(options.inPhaseNeuronFlags)

            [casedLabelsAll options.neuronSigns]=wbSetLabelCaseByNeuronSign(options.neuronSubset,double(options.inPhaseNeuronFlags)-0.5,refWBstruct,[],options);
size(options.neuronSigns)
               
            if isempty(options.activeNeuronFlags)       
                options.activeNeuronFlags=true(length(options.neuronSubset),1);
            end

            if isempty(options.inPhaseNeuronFlags)
                options.inPhaseNeuronFlags=options.neuronSigns>0;
            end

        
            if sum(options.activeNeuronFlags)>0
                 values=[];
                 valuesSupplement=[];
                 datasetMembership=[];

                 for d=1:numel(TTAStruct)
                     
                        neuronLabel1=options.refNeuron{d};
                        
                        n1=find(strcmpi(TTAStruct{d}.neuronLabels,neuronLabel1));

                        neuronLabel2=options.neuronSubset(options.activeNeuronFlags);


                        valuesSubMat=zeros(length(neuronLabel2), length( TTAStruct{d}.delayDistributionMatrix{1,n1}  ));
                        
                        
                        for kk=1:length(neuronLabel2)

                            n2=find(strcmpi(TTAStruct{d}.neuronLabels,neuronLabel2{kk}));
                            
                            
%                             neuronLabel2{kk}
%  size(TTAStruct{d}.delayDistributionMatrix)                           
%                             n2
%                             n1
%                             neuronLabel1
                            
                            if isempty(n2)
                                if isfield(hints{d},neuronLabel2{kk})
                                    n2=find(strcmpi(TTAStruct{d}.neuronLabels,hints{d}.(neuronLabel2{kk})));
                                end
                            end
                            
                            if isempty(n2)
                                 n2=find(strncmpi(TTAStruct{d}.neuronLabels,neuronLabel2{kk},length(neuronLabel2{kk})),1);
                            end

(options.inPhaseNeuronFlags)'
(TTAStruct{d}.neuronSigns>0)'
                            if options.inPhaseNeuronFlags(n2)==(TTAStruct{d}.neuronSigns(n2)>0)...                                   
                                
                                valuesSubMat(kk,:)=InBounds(TTAStruct{d}.delayDistributionMatrix{n2,n1}/TTAStruct{d}.fps,-cutoffTime1,cutoffTime2,true);  %write nans for out of bounds times
                            else
                                valuesSubMat(kk,:)=InBounds(TTAStruct{d}.delayDistributionMatrixNEG{n2,n1}/TTAStruct{d}.fps,-cutoffTime1,cutoffTime2,true);  %write nans for out of bounds times

                            end
                        end
                        
                        values=[values, valuesSubMat];
  
                        valuesSupplement=[valuesSupplement, TTAStruct{d}.refNeuronPreRunLengths{n1}];
                        
                        datasetMembership=[datasetMembership, d*ones(1,length(TTAStruct{d}.refNeuronPreRunLengths{n1}))];
            
                 end
                 
disp('wbTTACluster>  prerunlengths:')
valuesSupplement
base('prl',valuesSupplement)

                valuesBinary=zeros(size(values));
                valuesBinary(isnan(values))=1;

                valuesSign=sign(values);
                valuesSign(isnan(values))=0;

                if quantization==1  %none

                   inputValues=values;
                   inputValues(isnan(values))=OOBRval;

                elseif quantization==2  %binary

                   inputValues=valuesBinary;

                elseif  quantization==3  %trinary

                   inputValues=valuesSign;

                elseif quantization==4  %pre-cluster neurons
                    maxRange=[cutoffTime1 cutoffTime2];
                    minSpread=5;

                    inputValues=AssignToCluster1D(values,minSpread,maxRange);

                end

                if quantization==1
                    valuesForPlotting=values;
                else
                    valuesForPlotting=inputValues;
                end

                means=nanmean(inputValues,2);
                [meansSorted,meanSortIndex]=sort(means);

                casedLabels=casedLabelsAll(options.activeNeuronFlags);

            
            end
        
        
        outStruct.inputValues=inputValues;
        outStruct.inputValuesSupp=valuesSupplement;
        outStruct.inputLabels=casedLabels;
        outStruct.inputActiveNeurons=options.activeNeuronFlags;
        outStruct.datasetMembership=datasetMembership;
        
    end


    function [membership,centers]=SimpleCutoff(inputvals,cutoff)
        
        membership=2*ones(size(inputvals));
        membership(inputvals<cutoff)=1;
        centers(1)=mean(inputvals(membership==1));
        centers(2)=mean(inputvals(membership==2));
        
    end

    function InteractivePlotResults(outStruct)
        
        figure(handles.mainFig);
        cLim=[floor(-cutoffTime1) ceil(cutoffTime2)];
        
        if get(handles.quantizationPopup,'Value')==2 %binary
            cMap=[0 0 0;1 1 1];
            cLim=[0 1];
            
        elseif get(handles.quantizationPopup,'Value')==3 %trinary
            cMap=[1 0 0;0 1 0;0 0 1];
            cLim=[-1 1];
        elseif  get(handles.quantizationPopup,'Value')==4 %precluster
            cMap=[1 0 0;0 1 0;0 0 1];
            cLim=[0 2];

        else
            cMap=jet; %bipolar(201,0.9);
            cLim=[floor(-cutoffTime1) ceil(cutoffTime2)];
            
        end
        
        KillHandle('topAxes',handles);
        handles.topAxes=subtightplot(2,1,1,[0.1 .05],[.1 .1],[.06 .02]);
        RenderMatrix(valuesForPlotting(meanSortIndex,:),cLim,casedLabels(meanSortIndex),cMap,[],[],handles.topAxes);
        
        set(gca,'XTick',1:size(inputValues,2));

        if multiTrialFlag
            set(gca,'XTickLabel',datasetMembership);
        %    trialNames= [ char([TTAStruct.runInfo.dataSets(:)]')' ;repmat('  ',length(TTAStruct.runInfo.dataSets),1)' ];
           trialNames=[];
            xlabel('dataset');

        else
            set(gca,'XTickLabel',1:size(inputValues,2));
                        
            trialNames=wbMakeShortTrialname(refWBstruct.trialname);
            xlabel('transition#');

        end
        
        title(['unclustered: ' trialNames(:)' ]);
        
        KillHandle('middleAxes',handles);
        handles.middleAxes=subtightplot(2,1,2,[0.1 .05],[.1 .1],[.06 .02]);
        RenderMatrix(valuesForPlotting(meanSortIndex,sortIndex),cLim,casedLabels(meanSortIndex),cMap,[],[],handles.middleAxes);
      
        set(gca,'XTick',1:size(inputValues,2));
        
        if multiTrialFlag
            set(gca,'XTickLabel',datasetMembership(sortIndex));
            xlabel('dataset');
        else
            set(gca,'XTickLabel',sortIndex);
        end
        
        title(['clustered params: ' options.distanceMeasure ', ' options.quantization]);
        
        KillHandle('colorbaraxes',handles);
        handles.colorbaraxes=RenderMatrixColorbar('Middle','Left','Horizontal',cLim(1):cLim(2),cMap);
        xlabel('time (s)');

        
        KillHandle('lowerAxes',handles);
        handles.lowerAxes=axes('Position',[.06 .04 .92 .02]);
        RenderMatrix(outStruct.clusterMembership(sortIndex)',[],[],[],[],[],handles.lowerAxes);
        set(handles.lowerAxes,'XTick',1:length(outStruct.clusterMembership'));
        set(handles.lowerAxes,'XTickLabel',outStruct.clusterMembership(sortIndex)');
        xlabel(['cluster#']);
        hold on;
        

    end

    function LoadClustering
        
        if exist([currentFolderFullPath filesep 'Quant' filesep 'wbClusterRiseStruct.mat'],'file')
            disp('wbPhasePlot3D> loading existing cluster struct.');
            clusterRiseStruct=load([currentFolderFullPath filesep 'Quant' filesep 'wbClusterRiseStruct.mat']);
           
        end
        
        if exist([currentFolderFullPath filesep 'Quant' filesep 'wbClusterFallStruct.mat'],'file')
            
            clusterFallStruct=load([currentFolderFullPath filesep 'Quant' filesep 'wbClusterFallStruct.mat']);
           

        end
        

        
    end


    
end

