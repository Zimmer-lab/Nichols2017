function wbCompileTTAFullMatrix(rootFolder,options)

if nargin<1
    rootFolder=pwd;
end

if nargin<2
    options=[];
end


if ~isfield(options,'useOnlyIDedNeurons')
    options.useOnlyIDedNeurons=true;
end

if ~isfield(options,'transitionTypes')
    options.transitionTypes='SignedAllRises';
end 

if ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF';
end 

if ~isfield(options,'timeWindowSize')
    options.timeWindowSize=40;
end 

dataFolders=listfolders(rootFolder);

%initialize global neuron data struct
nIDs=LoadGlobalNeuronIDs;

for i=1:length(nIDs)
    for j=1:length(nIDs)
          neuronData(i,j).TTAtraces=[];
          neuronData(i,j).TTAtracesTV=[];
          neuronData(i,j).delayDistributions=[];
          neuronData(i,j).trialNames=[];
          neuronData(i,j).neuronPre=nIDs{i};
          neuronData(i,j).neuronPost=nIDs{j};
          neuronData(i,j).numTransitionsInTrial=[];
    end
end


for i=1:length(dataFolders) 

    cd([rootFolder filesep dataFolders{i}]);
    wbstruct=wbload([rootFolder filesep dataFolders{i}],false);
    disp(['processing ' wbMakeShortTrialname(wbstruct.trialname)]);
      
    thisTTAstruct=wbComputeTTAFullMatrix(wbstruct,options);
    thisIDlist=wbListIDs(wbstruct);
    
    for m=1:length(thisTTAstruct.neuronIndexSubset)
        for n=1:length(thisTTAstruct.neuronIndexSubset)
            
                ID_pre=wbstruct.simple.ID{thisTTAstruct.neuronIndexSubset(m)}(1);
                ID_post=wbstruct.simple.ID{thisTTAstruct.neuronIndexSubset(n)}(1);

                thisMasterNum_pre=find(strcmp(nIDs,ID_pre));
                thisMasterNum_post=find(strcmp(nIDs,ID_post));
                
                thisDDM=thisTTAstruct.delayDistributionMatrix{m,n}/thisTTAstruct.fps; 
                thisTM=thisTTAstruct.traceMatrix{m,n};
                thisTV=thisTTAstruct.traceTV{m,n};
                thisNumTransitions=length(thisDDM);
                neuronData(thisMasterNum_pre,thisMasterNum_post).TTAtraces=[neuronData(thisMasterNum_pre,thisMasterNum_post).TTAtraces  {thisTM}];
                neuronData(thisMasterNum_pre,thisMasterNum_post).TTAtracesTV=[neuronData(thisMasterNum_pre,thisMasterNum_post).TTAtracesTV  {thisTV}];

                neuronData(thisMasterNum_pre,thisMasterNum_post).delayDistributions=[neuronData(thisMasterNum_pre,thisMasterNum_post).delayDistributions; thisDDM];
                neuronData(thisMasterNum_pre,thisMasterNum_post).trialNames=[neuronData(thisMasterNum_pre,thisMasterNum_post).trialNames {wbMakeShortTrialname(wbstruct.trialname)}];
                neuronData(thisMasterNum_pre,thisMasterNum_post).numTransitionsInTrial=[neuronData(thisMasterNum_pre,thisMasterNum_post).numTransitionsInTrial thisNumTransitions];
        end
    end
    
end

runInfo.dataFolders=dataFolders;
runInfo.options=options;
runInfo.dataRan=datestr(now);
cd(rootFolder);
save([rootFolder filesep 'GlobalTTAFullMatrix-' options.transitionTypes  '.mat'],'neuronData','runInfo');

