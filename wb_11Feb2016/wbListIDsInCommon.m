function [overlapNeurons overlapGlobalNeuronNumbers]=wbListIDsInCommon(wbstructFileNameCellOrStructArray,logicalOperation,relaxClasses)

includeUnlabeledFlag=false;

if nargin<1 || isempty(wbstructFileNameCellOrStructArray)
    wbstructFileNameCellOrStructArray=listfolders(pwd);
end

if nargin<2 || isempty(logicalOperation)
    logicalOperation='intersection';
end 

if nargin<3 
    relaxClasses={'SMDV','SMB'};
elseif ischar(relaxClasses)
    relaxClasses={relaxClasses};
end


for i=1:length(wbstructFileNameCellOrStructArray)

    if isstruct(wbstructFileNameCellOrStructArray{i})
        
        wbstruct=wbstructFileNameCellOrStructArray{i};
        
    else
        wbstruct=wbload(wbstructFileNameCellOrStructArray{i},false);
    end
    
    [neuronString{i} neuronNumber{i}]=wbListIDs(wbstruct,includeUnlabeledFlag);


    if i==1
        overlapNeurons=neuronString{1};
    else

        if strcmpi(logicalOperation,'intersection')
            
           if isempty(relaxClasses)
               
               overlapNeurons= overlapNeurons( ismember(overlapNeurons,neuronString{i}));
               
           else
               newOverlapNeurons={};
               for j=1:length(overlapNeurons)
                   thisOverlapNeuron=overlapNeurons{j};

                   if InClass(thisOverlapNeuron,relaxClasses)
                       checkNeuron=relaxClasses{InClass(thisOverlapNeuron,relaxClasses)};
                   else
                       checkNeuron=thisOverlapNeuron;
                   end


                   if sum(strncmpi(checkNeuron,neuronString{i},length(checkNeuron)))
                       
                        newOverlapNeurons=[newOverlapNeurons checkNeuron];
                   end
               end
               overlapNeurons=unique(newOverlapNeurons);
               
           end
           
        else %'union'
            
            overlapNeurons = unique([overlapNeurons neuronString{i}]);
        end

    end
end

allNeurons = LoadGlobalNeuronIDs;
overlapGlobalNeuronNumbers=find(ismember(allNeurons,overlapNeurons));



end


function classNum=InClass(neuron,classes)
        
      for i=1:length(classes)
            if sum(strncmpi(neuron,classes{i},length(classes{i})))
                classNum=i;
                return;
            end
      end
      classNum=0;
end