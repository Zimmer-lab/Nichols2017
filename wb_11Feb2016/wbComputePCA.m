function out_struct=wbComputePCA(wbstructOrFolderOrTraces,options)
%wbpcastruct=WBCOMPUTEPCA(wbstruct,options)
%options defaults:
%
%
%options.dimRedType='PCA';  %or NMF
%options.range: 1:length(wbstruct.simple.tv); %analysis range vector, default full range
%options.rangeMask=[];   %a binary mask the same size as a single trace to zero out trace sections
%options.neuronSubset=[];
%
%options.fieldName='deltaFOverF_bc'; %which field of wbstruct.simple to use
%options.extraExclusionList=[];
%options.offsetFlag=false;   %offsetPCA method
%options.numOffsetSteps=1;
%options.computeVAFOfPreNorm=true;
%options.numReconComps=3;  %number of components for reconstruction
%
%options.numComponentsToDrop=0;
%options.dropCriterion='rms';
%
%options.useCorrelationsFlag=false; %i.e. use covariance instead
%options.preNormalizationType='none';
%
%options.derivFlag=false;  
%options.derivRegFlag=true;
%options.usePrecomputedDerivs=true;
%
%options.preSmoothFlag=false;   %for plotting, not for computation
%options.preSmoothingWindow=10;  %for plotting, not for computation
%
%SAVE OPTIONS
%options.saveFlag=true;  %save wbpcastruct.mat and wbpcastruct-<details>.mat
%options.alternateSaveFolder=[];
%
%PLOT OPTIONS
%options.plotFlag=true;  %launch wbPlotPCA afterward
%options.flagstrOverride=[];  %add flagstr here to override defaults


if nargin<2
    options=[];
end


if nargin<1
    wbstructOrFolderOrTraces=pwd;
end

if ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF_bc';
end

if ischar(wbstructOrFolderOrTraces)
    dataFolder=wbstructOrFolderOrTraces;
    wbstruct=wbload(dataFolder,false);
    WBMODE=true;
    
elseif isnumeric(wbstructOrFolderOrTraces)
    
    %create fictional struct
    pretraces0=wbstructOrFolderOrTraces;
    pretraces1=wbstructOrFolderOrTraces;
    dataFolder=pwd;
    numN=size(wbstructOrFolderOrTraces,2);
    numT=size(wbstructOrFolderOrTraces,1);
    WBMODE=false;
    
else
    dataFolder=pwd;
    wbstruct=wbstructOrFolderOrTraces;
    WBMODE=true;
end

if ~isfield(options,'numComponentsToDrop') || isempty(options.numComponentsToDrop)
    options.numComponentsToDrop=0;
end

if ~isfield(options,'dropCriterion') || isempty(options.dropCriterion)
    options.dropCriterion='rms';
end

if ~isfield(options,'dimRedType')
    options.dimRedType='PCA';
end

if ~isfield(options,'numComps')
    options.numComps=20;  %this has no meaning for PCA or OPCA
end

if ~isfield(options,'derivRegFlag')
    options.derivRegFlag=true;
end

if ~isfield(options,'usePrecomputedDerivs')
    options.usePrecomputedDerivs=true;
end
 
if ~isfield(options,'rangeMask')
    options.rangeMask=[];
end

if ~isfield(options,'neuronSubset')
    options.neuronSubset=[];
end

if ~isfield(options,'extraExclusionList')
    
    out_struct.exclusionList=[]; 
    
else
    
    if iscell(options.extraExclusionList)  && WBMODE==true   

        for nn=1:length(options.extraExclusionList)   

            [~, ~, simpleNeuronsToExclude(nn)] = wbgettrace(options.extraExclusionList{nn},wbstruct);
        end
        out_struct.exclusionList=simpleNeuronsToExclude(~isnan(simpleNeuronsToExclude));
    else
        out_struct.exclusionList=options.extraExclusionList;
    end
end

if ~isfield(options,'derivFlag')
   options.derivFlag=true;
end

if ~isfield(options,'useCorrelationsFlag')   %obsolete
   options.useCorrelationsFlag=false;
end

if ~isfield(options,'preNormalizationType')
    
    if options.useCorrelationsFlag
       options.preNormalizationType='rms';
    else
       options.preNormalizationType='none';
    end
end

if ~isfield(options,'numOffsetSteps');
   options.numOffsetSteps=1;
end

if ~isfield(options,'computeVAFOfPreNorm');
   options.computeVAFOfPreNorm=false;
end

if ~isfield(options,'numReconComps');
    options.numReconComps=3;
end

if ~isfield(options,'preSmoothFlag')
    options.preSmoothFlag=false;
end

if ~isfield(options,'preSmoothingWindow')
   options.preSmoothingWindow=10;
end



%% plot options

if ~isfield(options,'plotFlag')
   options.plotFlag=true;
end 

if ~isfield(options,'refNeuron')
   options.refNeuron='AVAL';
end 

if ~isfield(options,'plotNumComps')
    options.plotNumComps=10;
end

%% save options

if ~isfield(options,'saveFlag')
   options.saveFlag=true;
end

if ~isfield(options,'alternateSaveFolder')
    options.alternateSaveFolder=[];
end

if ~isfield(options,'flagstrOverride')
    options.flagstrOverride=[];
end

%%interactive prompts
if nargin<1   
    reply = input('[S]tandard or [d]eriv:','s');
    if strcmp(reply,'d')
         disp('doing PCA on derivatives.');
         options.derivFlag=true;
    end

    if options.derivFlag
        reply = input('[R]egularized deriv. or [t]raditional:','s');
        
        if strcmp(reply,'t');
            disp('using traditional deriv (pre-smoothed differencing).');
            options.derivRegFlag=false;
        else
            
            reply = input('Use [P]recomputed reg. deriv. or [r]ecompute:','s');
            if strcmp(reply,'r')
                options.usePrecomputedDerivs=false;
            else
                options.usePrecomputedDerivs=true;
            end
     
        end
        
    end
   
    reply = input('Use [C]ovariance or co[r]relation:','s');
    if strcmp(reply,'r')
         disp('doing PCA on correlation.');
         options.useCorrelationsFlag=true;
         options.preNormalizationType='rms';
    end
    
    reply = input('Use [S]tandard or [o]ffset estimator:','s');
    if strcmp(reply,'o')
         disp('doing offset PCA.');
         options.dimRedType='OPCA';
         
    end  
        
    wbstruct=wbload([],false);
    
end

%set up flagstr
flagstr=[];
if (options.derivFlag) flagstr=[flagstr '-deriv']; else flagstr=[flagstr '-nond']; end  %this must be the first flag for proper parsing by wbPlotPCADouble (tbd)
if (options.preSmoothFlag) flagstr=[flagstr '-presm']; end
flagstr=[flagstr '-' options.dimRedType];
if options.numOffsetSteps>1 && strcmp(options.dimRedType,'OPCA')
    flagstr=[flagstr 'OPCA' num2str(options.numOffsetSteps)];
end

%set range
if ~isfield(options,'range') || isempty(options.range)  %analysis range
    
   if WBMODE
       options.range=1:length(wbstruct.simple.tv);
   else
       options.range=1:size(pretraces1,1);
   end
   
else
    flagstr=[flagstr '-[' num2str(options.range(1))  '-' num2str(options.range(end)) ']' ];
end

if WBMODE  %otherwise ignore all derivative flags
     
    numN=wbstruct.simple.nn;
    numT=length(wbstruct.simple.tv);
    
    %%load traces, range select, denan, detrend
    pretraces0=wbstruct.simple.(options.fieldName)(options.range,:);
    pretraces0(isnan(pretraces0(:)))=0;
    pretraces0=detrend(pretraces0,'linear');
    
    pretraces0FullRange=wbstruct.simple.(options.fieldName);
    pretraces0FullRange(isnan(pretraces0FullRange(:)))=0;
    pretraces0FullRange=detrend(pretraces0FullRange,'linear');

    %compute derivative (dPCA) 
    if options.derivRegFlag
        if options.usePrecomputedDerivs
             if isfield(wbstruct.simple,'derivs')
                 pretracesD=wbstruct.simple.derivs.traces(options.range,:);
                 pretracesDFullRange=wbstruct.simple.derivs.traces;

             else
                 disp('No precomputed derivs found in wbstruct.  Will recompute.');
                 pretracesD=derivReg(pretraces0);
                 pretracesDFullRange=derivReg(pretraces0FullRange);

             end          
        else
             pretracesD=derivReg(pretraces0);   
             pretracesDFullRange=derivReg(pretraces0FullRange);

        end        
    else
        if options.preSmoothFlag
            pretracesD=deriv(fastsmooth(pretraces0,options.preSmoothingWindow,3,1));
            pretracesDFullRange=deriv(fastsmooth(pretraces0FullRange,options.preSmoothingWindow,3,1));
            
        else
            pretracesD=deriv(pretraces0);
            pretracesDFullRange=deriv(pretraces0FullRange);
        end
    end

    if options.derivFlag %use deriv
        pretraces1=pretracesD;
        pretraces1FullRange=pretracesDFullRange;

    else
        pretraces1=pretraces0;  %non-deriv traces
        pretraces1FullRange=pretraces0FullRange;
    end
   
    
end

%presmooth
if options.preSmoothFlag && ~options.derivFlag   %derivs already got smoothed
    pretraces1=fastsmooth(pretraces1,options.preSmoothingWindow,3,1);
    pretraces1FullRange=fastsmooth(pretraces1FullRange,options.preSmoothingWindow,3,1);
end

%compute normalization
if strcmpi(options.preNormalizationType,'peak')

    traces=pretraces1.*repmat(1./max(abs(pretraces0),[],1),size(pretraces1,1),1); 
    tracesFullRange=pretraces1FullRange.*repmat(1./max(abs(pretraces0FullRange),[],1),size(pretraces1FullRange,1),1); 
    flagstr=[flagstr '-normPeak'];

elseif strcmpi(options.preNormalizationType,'peakDeriv')

    traces=pretraces1.*repmat(1./max(abs(pretracesD),[],1),size(pretraces1,1),1);                
    flagstr=[flagstr '-normPeakD'];

elseif strcmpi(options.preNormalizationType,'rms')   
   
  %  [pretraces,rmsvals]=normalize(wbstruct.simple.(options.fieldName)(options.range,:),-3);
     [~,rmsvals]=normalize(pretraces0,-3);
         
     traces=pretraces1.*repmat(1./rmsvals,size(pretraces1,1),1);

 %   traces=pretraces1.*repmat(1./rms(pretraces0),size(pretraces1,1),1);
     flagstr=[flagstr '-normRMS'];  


elseif strcmpi(options.preNormalizationType,'rmsDeriv')

    traces=pretraces1.*repmat(1./rms(pretracesD),size(pretraces1,1),1);                
    flagstr=[flagstr '-normRMSD'];  
    
elseif strcmp(options.preNormalizationType,'maxsnrDeriv')
    
    traces=snrmaximize(pretraces1);  %from WhiteNoise
    flagstr=[flagstr '-normMaxSNRD'];

elseif strcmp(options.preNormalizationType,'maxsnr')
    
    [~, alphas]=snrmaximize(pretraces0);  %from WhiteNoise
    [~,rmsvals]=normalize(pretraces0,-3);
    traces=pretraces1.*repmat(1./rmsvals,size(pretraces1,1),1).*repmat(alphas',size(pretraces1,1),1);
    flagstr=[flagstr '-normMaxSNR'];
    
else % no pre-normalization

    traces=pretraces1;
    tracesFullRange=pretraces1FullRange;
    flagstr=[flagstr '-normNONE']; 

end

if (options.numComponentsToDrop>0) 
    flagstr=[flagstr '-DROP' num2str(options.numComponentsToDrop)]; 
end

referenceIndices=1:size(traces,2);

if WBMODE
 
    %range mask traces
    if ~isempty(options.rangeMask)      
        traces=traces.*repmat(options.rangeMask,1,size(traces,2));            
    end
                
    
    %WB specific: exclude neurons that are marked for exclusion
    if isfield(out_struct,'exclusionList')

        fprintf('%s','excluding');
        if isfield(options,'extraExclusionList')
            for i=1:length(options.extraExclusionList)
                fprintf(' %s',options.extraExclusionList{i});
            end
        end
        fprintf('.\n');

    end

    thisExclusionListLogical=false(1,size(traces,2));

    %WB specific: exclude neurons that aren't in neuronSubset

    if ~isempty(options.neuronSubset)
        [~, goodIndices]=wbGetTraces(wbstruct,true,[],options.neuronSubset);
        thisExclusionListLogical=true(1,size(traces,2));
        thisExclusionListLogical(goodIndices)=false;
    end

    thisExclusionListLogical(out_struct.exclusionList)=true;

    %WB specific: drop low rms components
    if options.numComponentsToDrop>0
        
        tracesExcluded=traces(:,~thisExclusionListLogical);
        pretraces0Excluded=pretraces0(:,~thisExclusionListLogical);
        
        tracesUnExcludedIndices=find(~thisExclusionListLogical);
        sortOptions=[];
        
        if strcmp(options.dropCriterion,'rmsd') && options.derivFlag
           [~,tracesExcludedSortIndex]=wbSortTraces(tracesExcluded,'rms',[],[],sortOptions);
        else
           [~,tracesExcludedSortIndex]=wbSortTraces(pretraces0Excluded,'rms',[],[],sortOptions);   
        end
            
        numTracesExcluded=size(tracesExcluded,2);
        
        excludedIndicesToDrop= tracesExcludedSortIndex(numTracesExcluded-options.numComponentsToDrop+1:numTracesExcluded);
        
        indicesToDrop=tracesUnExcludedIndices(excludedIndicesToDrop);
        
        
        thisExclusionListLogical(indicesToDrop)=true;
        
    end
 

    %remove excluded traces
    traces(:,thisExclusionListLogical)=[];
    tracesFullRange(:,thisExclusionListLogical)=[];
    
    numN=size(traces,2);
    referenceIndices(thisExclusionListLogical)=[];
    
    %for reference
    pretraces0(:,thisExclusionListLogical)=[];
    pretraces1(:,thisExclusionListLogical)=[];

    
    %write out IDs
    out_struct.neuronIDs=wbListIDs(wbstruct,true,find(~thisExclusionListLogical));


else  %TRACEMODE
    
    out_struct.neuronIDs=options.neuronSubset;
    
end


%zero center traces
traces=detrend(traces,'constant');


%compute!

tic

if strcmpi(options.dimRedType,'OPCA' )
    [pcs.COEFF,pcs.LATENT,pcs.EXPLAINED] = pcacov(covOffset(traces,options.numOffsetSteps));  %across time
    
%do-it-yourself
%
%     [pcs.COEFF,pcs.LATENT]=eig(covOffset(traces,options.numOffsetSteps));
%     pcs.LATENT=diag(pcs.LATENT);
%     pcs.LATENT=pcs.LATENT(end:-1:1);
%     pcs.COEFF=pcs.COEFF(:,end:-1:1);
%     pcs.EXPLAINED=pcs.LATENT*100/sum(pcs.LATENT);

    pcs.PC=zeros(length(traces(:,1)),length(pcs.EXPLAINED));
    
    %make PCs from projections
    for j=1:length(pcs.EXPLAINED)
         for i=1:length(pcs.EXPLAINED)
            pcs.PC(:,j)=  pcs.PC(:,j) + pcs.COEFF(i,j)*traces(:,i);
         end
    end
    

    out_struct.covMat=covOffset(traces); 
    out_struct.pcs=pcs.PC;
    out_struct.coeffs=pcs.COEFF;
    out_struct.varianceExplained=pcs.EXPLAINED;
    
elseif strcmpi(options.dimRedType,'NMF' )
    
    for i=1:size(traces,2);
        traces(:,i)=traces(:,i)-min(traces(:,i));
    end
    [out_struct.pcs,out_struct.coeffs] = nnmf(traces,options.numComps,'replicates',100,'alg','als'); %,'alg','mult'
    out_struct.varianceExplained=zeros(20,1);
    
    
elseif strncmpi(options.dimRedType,'connectome',10)  %do PCA using cov matrix built from connectome and not time series data
    
    connectomeStruct=coGetConnectomeSubset(out_struct.neuronIDs,'default');
    
    if strcmpi(options.dimRedType(11:13),'gap')
        disp('gap')
        adjMat=connectomeStruct.gapJunctionOutNormedMatrix;
    elseif  strcmpi(options.dimRedType(11:13),'syn')
        adjMat=connectomeStruct.synapseOutNormedMatrix+connectomeStruct.synapseOutNormedMatrix';
    else %both
        adjMat=connectomeStruct.gapJunctionOutNormedMatrix+(connectomeStruct.synapseOutNormedMatrix+connectomeStruct.synapseOutNormedMatrix')/2;
    end
        
    [pcs.COEFF,pcs.LATENT,pcs.EXPLAINED] = pcacov(adjMat);  %across time

    pcs.PC=zeros(length(traces(:,1)),length(pcs.EXPLAINED));
    
    
    %make PCs from projections
    for j=1:length(pcs.EXPLAINED)
         for i=1:length(pcs.EXPLAINED)
            pcs.PC(:,j)=  pcs.PC(:,j) + pcs.COEFF(i,j)*traces(:,i);
         end
    end
    
    out_struct.covMat=adjMat; 
    out_struct.pcs=pcs.PC;
    out_struct.coeffs=pcs.COEFF;
    out_struct.varianceExplained=pcs.EXPLAINED;
    
    
else %regular PCA

    [pcs.PCCOEFF_D1, pcs.PC_D1, pcs.LATENT_D1, pcs.TSQUARED_D1, pcs.EXPLAINED_D1, pcs.MU_D1] = pca(traces);  %across time
%   [pcs.PCCOEFF_D2, pcs.PC_D2, pcs.LATENT_D2, pcs.TSQUARED_D2, pcs.EXPLAINED_D2, pcs.MU_D2] = pca(traces'); %across neuron
%   [pcs.PCCOEFF_D3, pcs.PC_D3, pcs.LATENT_D3, pcs.TSQUARED_D3, pcs.EXPLAINED_D3, pcs.MU_D3] = pca(traces','Economy',false); 
  
    out_struct.covMat=cov(traces);
    out_struct.pcs=pcs.PC_D1;
    out_struct.coeffs=pcs.PCCOEFF_D1;
    out_struct.varianceExplained=pcs.EXPLAINED_D1;
end
toc


out_struct.traces=traces;
out_struct.tracesOrig=pretraces0;
out_struct.tracesPreNorm=pretraces1;

%make full range temporal PCs from projections
out_struct.pcsFullRange=zeros(length(wbstruct.simple.tv),length(out_struct.varianceExplained));
for j=1:length(out_struct.varianceExplained)
     for i=1:length(out_struct.varianceExplained)
        out_struct.pcsFullRange(:,j) = out_struct.pcsFullRange(:,j)  + out_struct.coeffs(i,j)*tracesFullRange(:,i);
     end
end



% roll your own PCA

% tic
%  [pcs_m2.COEFF,pcs_m2.LATENT,pcs_m2.EXPLAINED] = pcacov(cov(traces));  %across time
%  
%  pcs_m2.PC=zeros(length(traces(:,1)),length(pcs_m2.EXPLAINED));
%  for j=1:length(pcs_m2.EXPLAINED)
%      
%      for i=1:length(pcs_m2.EXPLAINED)
%         pcs_m2.PC(:,j)=  pcs_m2.PC(:,j) + pcs_m2.COEFF(i,j)*traces(:,i);
%      end
%  
%  end
% toc
%figure;plot(pcs_m2.PC(:,1));hold on;plot(pcs_m2.PC(:,2)+1,'r');


%assignin('base','pcs',pcs);

%assignin('base','pcms',pcs_m2)

%deprecated princomp matlab function- this is totally equivalent so don't bother,
%just here for reference
%[a.pcvectors1 a(tr).pcscores1]=princomp(a);
%[a.pcvectors2 a(tr).pcscores2]=princomp(a');

%this is the same as looking at the coeffs.
% for t=1:numT
% %     %project traces onto first pcs  (do i need to explicitly norm pc's?) 
%      hts.PCproj(t,1)=  dot(traces(t,:),hts.PC_D2(:,1));
%      hts.PCproj(t,2)=  dot(traces(t,:),hts.PC_D2(:,2));    
% end
% 


%save output struct

out_struct.dimRedType=options.dimRedType;
out_struct.referenceIndices=referenceIndices;
out_struct.dateRan=datestr(now);
out_struct.options=options;
out_struct.flagstr=flagstr;


if options.computeVAFOfPreNorm && WBMODE  %recompute VAFs on pre-normed dataset
    reconOptions.numComps=options.numReconComps;
    reconOptions.plotFlag=false;

    cumVarEx=wbReconstructDataset(wbstruct,out_struct,reconOptions);

    out_struct.varianceExplainedOfPreNorm=sort([cumVarEx(1); diff(cumVarEx)'],'descend');
end

if options.saveFlag
    if ~isempty(options.alternateSaveFolder)
        saveFolder=options.alternateSaveFolder;
    else
        if WBMODE
           saveFolder=[dataFolder filesep 'Quant'] ;
        else
           saveFolder=dataFolder;
        end
    end
    save([saveFolder filesep 'wbPCAstruct.mat'],'-struct','out_struct');
    save([saveFolder filesep 'wbPCAstruct' flagstr '-' strrep(strrep(datestr(now),':','-'),' ','-') '.mat'],'-struct','out_struct');
end


if ~WBMODE %populate fictional wbstruct for sending to wbPlotPCA
    wbstruct.tv=1:size(pretraces1,1);
    wbstruct.trialname='joint';
    wbstruct.displayname='joint';
    wbstruct.simple.derivs.traces=pretraces1;
    out_struct.options.derivFlag=options.derivFlag;
    if ~isempty(options.flagstrOverride)
        out_struct.flagstr=options.flagstrOverride;
    end
end


if options.plotFlag

    plotOptions.plotNumComps=options.plotNumComps;
    
    
    plotOptions.plotSplitFigures=true;
    plotOptions.lineWidth=2;
    plotOptions.stimulusPlotSyle='solid';
    plotOptions.VAFYLim=100;

    %PLOT MULTIPLE OVERLAYS
    %plotOptions.timeColoringOverlay{1}=(wbFourStateTraceAnalysis(wbstruct,'useSaved','SMB')==2);  %2 is "rise state"
    %plotOptions.timeColoringOverlay{2}=(wbFourStateTraceAnalysis(wbstruct,'useSaved','RIVL')==2);
    %plotOptions.timeColoringOverlayColor{1}='r';
    %plotOptions.timeColoringOverlayColor{2}='b';
    %plotOptions.timeColoringOverlayLegend={'SMB','RIVL'};
    plotOptions.timeColoringShiftBalls=true;  %shift balls so overlaps can be seen.


    %GHOST TRAJECTORY (GRAY LINE FOR WHOLE TRACE)
    plotOptions.plotGhostTrajectory=false;

    if WBMODE

        %PLOT FOUR STATE COLORING 
        plotOptions.timeColoring=wbFourStateTraceAnalysis(wbstruct,'useSaved',options.refNeuron);  %use pre-saved thresholds
    
    else
        
        if isfield(options,'timeColoring')
            plotOptions.timeColoring=options.timeColoring;
        end
        
    end


    plotOptions.smoothFlag=true;  %smooth derivs after computation
    plotOptions.smoothingWindow=3;

    plotOptions.plotFlag=true;
    plotOptions.plotPCExclusions=[]; %add PC numbers to exclude from plotting.  3D plots will use top 3 non-excluded components
    plotOptions.savePDFFlag=true;

    plotOptions.combinePDFFlag=true;


    %plotOptions.savePDFCopyDirectory=['/Users/' thisuser '/Desktop/Dropbox/SaulHarrisTinaManuel/Catchall'];
%    mkdir(options.savePDFCopyDirectory);

    plotOptions.phasePlot3DMainColor=[0.5 0.5 0.5];
    plotOptions.phasePlot3DView=[-15 16];
    plotOptions.phasePlot3DFlipZ=false;
    %options.phasePlot3DLimits=[-0.1 0.15 -0.1  0.1 -0.04 0.06];
    plotOptions.plotTimeRange=1:length(wbstruct.tv);
    plotOptions.plotTimeSubRange=options.range;

    %pre-stimulus range plot
    %options.plotTimeRange=360:1068;  %pre stimulus period minus first 360 frames, 1069:2132 would be post-stimulus range
    wbPlotPCA(wbstruct,out_struct,plotOptions);
    
    
end
 
end
