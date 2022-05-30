function outputStruct=wbComputeRelationMatrices(wbstruct,options)

if nargin<1 || isempty(wbstruct)
    [wbstruct, wbstructFileName] = wbload([],false);
end

if nargin<2
    options=[];
end

%%options
if ~isfield(options,'saveDir')
    options.saveDir=[pwd filesep 'Quant'];
end

if ~isfield(options,'derivFlag')
    options.derivFlag=true;
end
%%end options

relationTypes=wbComputeRelationMatrix('?');  %get all relation types

for j=0:double(options.derivFlag)
    
    if j
        if ~isfield(wbstruct,'simple')
            wbMakeSimpleStruct(wbstructFileName);
            wbstruct=wbload(wbstructFileName,false);
        end    
        if ~isfield(wbstruct.simple,'derivs')
            wbAddDerivs(wbstructFileName);
            wbstruct=wbload(wbstructFileName,false);
        end
        traces=wbstruct.simple.derivs.traces;
    else
        traces=wbGetTraces(wbstruct);
    end
    
    for i=1:length(relationTypes)

        if j
            thisRelationType=[relationTypes{i} 'd'];
        else
            thisRelationType=relationTypes{i};
        end

        outputStruct.(thisRelationType)=wbComputeRelationMatrix(traces,relationTypes{i},options);

    end

end

save([options.saveDir filesep 'wbmatrixstruct.mat'],'-struct','outputStruct');
save([options.saveDir filesep 'wbmatrixstruct-' FriendlyDateStr '.mat'],'-struct','outputStruct');


