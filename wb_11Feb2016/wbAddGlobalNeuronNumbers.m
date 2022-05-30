function wbAddGlobalNeuronNumbers(simpleStructFilename)


ws=load(simpleStructFilename);
fn.neuronNames=LoadGlobalNeuronIDs;

for i=1:ws.nn
    
    
    ws.neuronGlobalNumber(i)=find(ismember(fn.neuronNames,ws.neuronNames{i}));
    
end


save(simpleStructFilename,'-struct','ws');