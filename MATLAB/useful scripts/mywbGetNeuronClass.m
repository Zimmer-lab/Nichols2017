
function [NeuronATraces, NeuronATracesDeriv] = mywbGetNeuronClass(NeuronA,Opts)



FolderList = mywbGetDataFolders;

NumDataSets = length(FolderList);

    
    
    load('Quant/wbstruct.mat','tv');
    
    load('Quant/wbstruct.mat','simple');
    
    
    
    [NeuronList, ~] = wbListIDs;
    
    NumNeurons = length(NeuronList);
    
    
    NeuronAIndx = mywbFindNeuron(NeuronA);
    
    
    NeuronATracecs = [];
    
    
    NeuronATraces = simple.deltaFOverF(:,NeuronAIndx);
  
    NeuronATracesDeriv = simple.derivs.traces(:,NeuronAIndx);
    
%     for ii = 1:length(NeuronAIndx);
%         
%         
%         NeuronATraces(:,ii) = wbgettrace(simple.nOrig(NeuronAIndx(ii)));
%         
%         
%         
%         
%     end
    
    
    if Opts.PlotFlag ==1;
        
        FigA = figure;
        
        
        for ii = 1:length(NeuronAIndx);
            
            
            
            subplot(length(NeuronAIndx),1,ii);
            
            plot(tv,NeuronATraces(:,ii))
            
        end
        
        FigB = figure;
        
        
        for ii = 1:length(NeuronAIndx);
            
            
            
            subplot(length(NeuronAIndx),1,ii);
            
            plot(tv,NeuronATracesDeriv(:,ii))
            
        end
        
        
    end
    
    
    
    