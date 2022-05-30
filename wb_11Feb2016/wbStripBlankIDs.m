function neuronStringArray_out=wbStripBlankIDs(neuronStringArray)

    neuronStringArray_out=neuronStringArray(~strcmp(neuronStringArray,'---'));
    
end