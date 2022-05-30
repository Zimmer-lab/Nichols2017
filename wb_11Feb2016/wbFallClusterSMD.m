function wbFallClusterSMD(folder,windowRange)

    if nargin<1
       folder=pwd;
    end
    
    if nargin<2
        windowRange=[-10 30];
    end

    options=[];
    
    if ~isfield(options,'useHints')
        options.useHints=true;
    end


    if ~isfield(options,'fieldName')
        options.fieldName='deltaFOverF_bc';
    end


    if ~isfield(options,'refNeuron')
        options.refNeuron='AVAL';    %default if no refNeuron in hints
        if options.useHints && exist(['Quant' filesep 'wbhints.mat'],'file')
            hints=load(['Quant' filesep 'wbhints.mat']);
            if isfield(hints,'stateRefNeuron') && ~isempty(hints.stateRefNeuron)
                options.refNeuron=hints.stateRefNeuron;
            disp(['wbFallClusterSMD> using wbhints.mat file:  state reference neuron=' options.refNeuron]);
            end
        end
    end

    
    
    
    
    
    if exist([folder filesep 'Quant' filesep 'wbClusterFallStruct.mat'],'file')         
        CFS=load([folder filesep 'Quant' filesep 'wbClusterFallStruct.mat']);        
    end
    


        
        TT=load([folder filesep 'Quant' filesep 'wbTTAFallStruct.mat']);
        
        
        refNum=find(strcmpi(TT.neuronLabels,options.refNeuron));
        
        SMDNum=find(strncmpi(TT.neuronLabels,'SMD',3),1)
        
        if isempty(SMDNum)  %no SMD so use SMB instead
            
            SMBNum=find(strncmpi(TT.neuronLabels,'SMB',3),1)
            delays=TT.delayDistributionMatrixNEG{SMBNum,refNum}

            SMDclusterMembership=ones(length(delays),1);

            for i=1:length(SMDclusterMembership)
                if  delays(i)>windowRange(1) && delays(i)<windowRange(2)

                    SMDclusterMembership(i)=2;
                end

            end       
            
        else
        
            delays=TT.delayDistributionMatrixNEG{SMDNum,refNum};


            SMDclusterMembership=2*ones(length(delays),1);

            for i=1:length(SMDclusterMembership)
                if  delays(i)>windowRange(1) && delays(i)<windowRange(2)

                    SMDclusterMembership(i)=1;
                end

            end
        
        end
        
   
        delays'
SMDclusterMembership'
    
    CFS.SMD.clusterMembership=SMDclusterMembership;
    CFS.SMD.windowRange=windowRange;

    save([folder filesep 'Quant' filesep 'wbClusterFallStruct.mat'],'-struct','CFS');
    
    
    
end