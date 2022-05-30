%%

NeuronA = 'URX';


Opts.PlotFlag = 0;

%%

MainDir = pwd;

FolderList = mywbGetDataFolders;

NumDataSets = length(FolderList);



for i = 1:NumDataSets
    
    cd(FolderList{i})
    
    [NeuronTracesAcc(i).NeuronATraces, NeuronTracesAcc(i).NeuronATracesDeriv] = mywbGetNeuronClass(NeuronA,Opts);
    
    %NeuronTracesAcc(i).NeuronBTraces = mywbGetNeuronClass(NeuronB,Opts);
    
    
    cd(MainDir)
    
end
