function wbCompileTTA(rootFolder,options)

if nargin<1
    rootFolder=pwd;
end

if nargin<2
    options=[];
end

if ~isfield(options,'useHints')
    options.useHints=true;
end

if ~isfield(options,'addClusterData')
    options.addClusterData=true;
end

if ~isfield(options,'neuronSubset')
    options.neuronSubset=[];
end
    
if ~isfield(options,'refNeuronOverride')   %override wbhints refneurons
    options.refNeuronOverride=[];
end 

if ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF';
end 

if ~isfield(options,'delayCutoff')
    options.delayCutoff=10;
end 

if ~isfield(options,'transitionTypes')
    options.transitionTypes={'SignedAllRises','SignedAllFalls'};
end 




if ischar(options.transitionTypes)
    options.transitionTypes={options.transitionTypes};
end


% if ~isfield(options,'FSAParams')
%     posThresh=.05;
%     negThresh=-.3;
%     threshType='rel';
%     transitionTypes=[1:8];
%     options.FSAParams={posThresh,negThresh,threshType};
% end


dataFolders=listfolders(rootFolder);

%initialize global neuron data struct
nIDs=LoadGlobalNeuronIDs;
globalMap=wbMakeGlobalMaps;

for d=1:length(dataFolders)  
    cd([rootFolder filesep dataFolders{d}]);
    wbstruct{d}=wbload([rootFolder filesep dataFolders{d}],false);
    runInfo.dataSets{d}=wbMakeShortTrialname(wbstruct{d}.trialname);
    wbhints{d}=wbHints;
    
    
     if options.addClusterData
         wbClusterRiseStruct{d}=load([rootFolder filesep dataFolders{d} filesep 'Quant' filesep 'wbClusterRiseStruct.mat']);
         wbClusterFallStruct{d}=load([rootFolder filesep dataFolders{d} filesep 'Quant' filesep 'wbClusterFallStruct.mat']);
     end
         
            
end
% 
% base('crs',wbClusterRiseStruct);
% base('cfs',wbClusterFallStruct);


for j=1:numel(options.transitionTypes)

    clear globalNeuronData;
    clear compiled;
    compiled.neuronsInCommon=wbListIDsInCommon(wbstruct);
    
    for i=1:length(nIDs)
      globalNeuronData(i).neuron=nIDs{i};
      
      %neuronData(i).TTAtraces=[];
      globalNeuronData(i).delayDistributions=[];
      globalNeuronData(i).trialNames=[];
      

      if options.addClusterData
          globalNeuronData(i).clusterRiseMembership=[];
          globalNeuronData(i).clusterFallMembership=[];
      end
          

    end

    
    
    for d=1:length(dataFolders) 

        TTAoptions=options;
        TTAoptions.useGlobalSigns=true;
        TTAoptions.transitionTypes=options.transitionTypes{j};
        
        if isempty(options.refNeuronOverride)
            TTAoptions.refNeuron=wbhints{d}.stateRefNeuron;
        else
            TTAoptions.refNeuron=options.refNeuronOverride;
        end
        
%       disp(['processing ' runInfo.dataSets{i}]);
%       TTAstruct=wbComputeTTA(wbstruct{i},TTAoptions);

        if strcmp(options.transitionTypes{j},'SignedAllRises')
            TTAstruct=load([rootFolder filesep dataFolders{d} filesep 'Quant' filesep 'wbTTARiseStruct.mat']);
        else
            TTAstruct=load([rootFolder filesep dataFolders{d} filesep 'Quant' filesep 'wbTTAFallStruct.mat']);
        end
        
        thisClusterRiseMembership=wbClusterRiseStruct{d}.clusterMembership;
        thisClusterFallMembership=wbClusterFallStruct{d}.clusterMembership;


        refNeuronNum=find(strcmp(TTAoptions.refNeuron,TTAstruct.neuronLabels));
        
        for n=1:size(TTAstruct.delayDistributionMatrix,2)


                ID=TTAstruct.neuronLabels{n};

                thisMasterNumber=find(strcmpi(nIDs,ID));

                %neuronData(thisMasterNumber).TTAtraces=[neuronData(thisMasterNumber).TTAtraces  {TTAtraces(:,:,n)}];
                
                %globalNeuronData(thisMasterNumber).delayDistributions=[globalNeuronData(thisMasterNumber).delayDistributions {TTAstruct.delays(:,n)}];
                
                globalNeuronData(thisMasterNumber).delayDistributions=[globalNeuronData(thisMasterNumber).delayDistributions {TTAstruct.delayDistributionMatrix{n,refNeuronNum}/wbstruct{d}.fps}];

                globalNeuronData(thisMasterNumber).trialNames=[globalNeuronData(thisMasterNumber).trialNames {wbMakeShortTrialname(wbstruct{d}.trialname)}];
                globalNeuronData(thisMasterNumber).ID=ID;
                
                if options.addClusterData                    
                    
                     globalNeuronData(thisMasterNumber).clusterRiseMembership=[globalNeuronData(thisMasterNumber).clusterRiseMembership {thisClusterRiseMembership}];
                     globalNeuronData(thisMasterNumber).clusterFallMembership=[globalNeuronData(thisMasterNumber).clusterFallMembership {thisClusterFallMembership}];
                end
                    
                    
        end


    end

    
    k=1;
    
    base('gnd',globalNeuronData)
    
    for n=1:302 
        if ~isempty(globalNeuronData(n).delayDistributions)
            
            if (globalMap.Sign(globalNeuronData(n).ID))<0
                signchar='-';
            else
                signchar='+';
            end
            
            compiled.labels{k}=[globalNeuronData(n).ID  signchar];

            compiled.delays{k}=cellapse(globalNeuronData(n).delayDistributions);
 

            compiled.datasetNumber{k}=[];
            compiled.transitionNumbers{k}=[];
            if options.addClusterData
                compiled.clusterRiseMembership{k}=cellapse(globalNeuronData(n).clusterRiseMembership);
                compiled.clusterFallMembership{k}=cellapse(globalNeuronData(n).clusterFallMembership);
            end
            

            for j=1:length(globalNeuronData(n).delayDistributions)
                  datasetIndex=find(strcmpi(runInfo.dataSets,globalNeuronData(n).trialNames{j}  )); 
                  compiled.datasetNumber{k}=[compiled.datasetNumber{k}   datasetIndex*ones(1,length(globalNeuronData(n).delayDistributions{j})) ]; 
                  compiled.transitionNumbers{k}=[compiled.transitionNumbers{k}   1:length(globalNeuronData(n).delayDistributions{j})];
            end



            k=k+1;
        end
    end

    gaussFitOptions.range=[-TTAoptions.delayCutoff TTAoptions.delayCutoff];
    gaussFitOptions.fitMethod='em';
    compiled.gaussianFitData=wbGaussFit(compiled.delays,gaussFitOptions);

    runInfo.options=TTAoptions;
    runInfo.dataRan=datestr(now);

    cd(rootFolder);
    save([rootFolder filesep 'GlobalTTA-' options.transitionTypes{j} options.refNeuronOverride '.mat'],'compiled','globalNeuronData','runInfo');

    disp(['wbCompileTTA>' rootFolder filesep 'GlobalTTA-' options.transitionTypes{j} options.refNeuronOverride '.mat saved.']);
    
end
