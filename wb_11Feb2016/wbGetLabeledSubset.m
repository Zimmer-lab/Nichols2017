function wbSimpleStruct=wbGetLabeledSubset(wbstruct,neuronSubset)
%wbSimpleStruct=wbGetLabeledSubset(wbstruct)
%grab neuron traces for all or a subset of neurons with IDs
%attach connectome
%
%For Sato and Taro

    if nargin<2
        neuronSubset=[];
    end

    if nargin<1
        wbstruct=wbload([],false);
    end
    
    if isempty(neuronSubset)
        [subset_neuronStrings subset_SimpleNeuronNumbers]=wbListIDs(wbstruct);
    else
        subset_neuronStrings=neuronSubset;
        [~,subset_SimpleNeuronNumbers]=wbGetTraces(wbstruct,true,[],neuronSubset);
    end
 

        
    wbSimpleStruct.nn=length(subset_SimpleNeuronNumbers);
    wbSimpleStruct.neuronNames=subset_neuronStrings;
    wbSimpleStruct.synapseMatrix=zeros(length(subset_SimpleNeuronNumbers));
    wbSimpleStruct.gapJunctionMatrix=zeros(length(subset_SimpleNeuronNumbers));
    
    wbSimpleStruct.neuronTraces=wbstruct.simple.deltaFOverF(:,subset_SimpleNeuronNumbers);

    wbSimpleStruct.fps=wbstruct.fps;
    wbSimpleStruct.timeVector=wbstruct.tv;



    for i=1:wbSimpleStruct.nn
    
          fno=coFindNeighbors(wbSimpleStruct.neuronNames{i});  %function from git/connectome
    
          if isfield(fno,'downNeighbor')
              for j=1:length(fno.downNeighbor)
                  if ismember(fno.downNeighbor{j},wbSimpleStruct.neuronNames)   
                      downNumber=find(ismember(subset_neuronStrings,fno.downNeighbor{j}));
                      wbSimpleStruct.synapseMatrix(i,downNumber)=fno.downStrength(j);
                  end
              end
          else
              disp('no downNeighbor field found.')
          end
         
              
          if isfield(fno,'gapNeighbor')
              for j=1:length(fno.gapNeighbor)              
                  if ismember(fno.gapNeighbor{j},wbSimpleStruct.neuronNames)   
                      gapNumber=find(ismember(subset_neuronStrings,fno.gapNeighbor{j}));
                      wbSimpleStruct.gapJunctionMatrix(i,gapNumber)=fno.gapStrength(j);
                  end
              end
          else
              disp('no gapNeighbor field found.')
          end
          
    end
    
    
wbSimpleStruct.neuronNames
    
    wbSimpleStruct.stimulusTrace=wbgetstimcoloring(wbstruct);
    wbSimpleStruct.stimulusDescription=wbstruct.stimulus;
    wbSimpleStruct.dateRan=wbstruct.dateRan;
    
    
%    wbSimpleStruct.neuronNumbers=zeros(1,wbSimpleStruct.nn);
%     for i=1:wbSimpleStruct.nn
%         
%         wbSimpleStruct.neuronNumbers(i)=find();
%     end
    
%     wbSimpleStruct.fullSynapseMatrix=
%     wbSimpleStruct.fullGapJunctionMatrix=
%     
    
    shortTrialName=wbstruct.trialname(1:strfind(wbstruct.trialname,'_')-1);     
    save(['wbSimpleStruct-' shortTrialName],'-struct','wbSimpleStruct');

    
    wbAddGlobalNeuronNumbers(['wbSimpleStruct-' shortTrialName '.mat'])
end