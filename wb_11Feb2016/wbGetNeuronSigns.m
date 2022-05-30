function neuronSigns=wbGetNeuronSigns(neuronLabels,wbDir,wbstruct,pc,options)

    if nargin<5
        options=[];
    end
    
    if nargin<2
        wbDir=[];
    end
    
    if nargin<3 || isempty(wbstruct)
        wbstruct=wbload(wbDir,false);
    end    

    if ~isfield(options,'useGlobalSigns')
        options.useGlobalSigns=true;
    end
    
    if ( nargin<4 || isempty(pc) )  && ~options.useGlobalSigns
        pc=wbLoadPCA(wbDir);
    end
    
    if ~isfield(options,'traceFieldName')
        options.traceFieldName='deltaFOverF_bc';
    end
       
    if ~isfield(options,'numTopComps')
        options.numTopComps=3;
    end
    

    %old way
    %SToptions.refWBStruct=wbstruct;
    %SToptions.refPCAStruct=pc;    
    %[~, ~, loading]=wbSortTraces(wbstruct.simple.(options.traceFieldName),'signed_pcaloading1',[],[],SToptions);
    %[~,traceIndices]=wbGetTraces(wbstruct,[],options.traceFieldName,neuronLabels);
    %neuronCoeffs=loading(traceIndices);
        
    %load global neuron property maps
    globalMaps=wbMakeGlobalMaps;
    
    neuronSigns=ones(numel(neuronLabels),1);
         
    if options.useGlobalSigns
    
        globalLabels=LoadGlobalNeuronIDs;
        
        for j=1:numel(neuronLabels)

             k=find(strcmp(globalLabels,neuronLabels{j}),1);

             if isempty(k)

                 disp('no neuron Found.  there must be a bug.')
                 
             else

                 neuronSigns(j)=globalMaps.Sign(neuronLabels{j})


             end
        end
        
    else
    
    
        %new way
        
        %assign to PC
        whichPC=numel(neuronLabels);


        for j=1:numel(neuronLabels)

             k=find(strcmp(pc.neuronIDs,neuronLabels{j}),1);

             if isempty(k)

                 coeffSign(j)=1;
                 whichPC(j)=1;

             else

                 [~, whichPC(j)]=max((sqrt(pc.varianceExplained(1:options.numTopComps)')).*abs(pc.coeffs(k,1:options.numTopComps)));
                 coeffSign(j)=sign(pc.coeffs(k,whichPC(j)));

             end
        end

        neuronSigns(whichPC==1 & coeffSign<0)=-1;
      
    end
   
    
end