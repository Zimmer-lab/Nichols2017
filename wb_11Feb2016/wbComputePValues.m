function pValueStruct=wbComputePValues(wbDir,options)

if nargin<2
    options=[];
end

if nargin<1
    wbDir={pwd};
end

if ~iscell(wbDir)
    wbDir={wbDir};
end

if ~isfield(options,'transitionType')
    options.transitionType='both';
end

if strcmpi(options.transitionType,'rise')
    tnChoice=1;
elseif strcmpi(options.transitionType,'fall')
    tnChoice=2;
else  %both
    tnChoice=[1 2];
end

if ~isfield(options,'phaseRange')
    options.phaseRange=[0 1];
end
    
if ~isfield(options,'phaseOffset')
    options.phaseOffset=0;
end
    

if ~isfield(options,'includeDerivsFlag')
    options.includeDerivsFlag=false;
end

if ~isfield(options,'derivsOnlyFlag');
    options.derivsOnlyFlag=false;

end

if ~isfield(options,'usePCAStruct');
    options.usePCAStruct=true;
end

if ~isfield(options,'recomputePCA');
    options.recomputePCA=false;
end

if ~isfield(options,'recomputePCAOptions');
    options.recomputePCAOptions=[];
end

if ~isfield(options,'postSmoothPCAWindow');
    options.postSmoothPCAWindow=3;
end


if ~isfield(options,'pcSelection')
    options.pcSelection={1:3}; %{1,1:2,1:3,1:10,1:20} %,1:2,1,2,3};
end
        
if ~isfield(options,'timeWarpRangePerPoint');
    options.timeWarpRangePerPoint=.0032;
end

if ~isfield(options,'timeWarpStepSize');
    options.timeWarpFrameStepSize=.025;
end

if ~isfield(options,'derivStrength')
    options.derivStrength=50;
end

if ~isfield(options,'plotFlag')
    options.plotFlag=true;
end

if ~isfield(options,'plotLogScale')
    options.plotLogScale=true;
end

if ~isfield(options,'subPlotFlag')
    options.subPlotFlag=false;
end

if ~isfield(options,'neuronSelection')
    options.neuronSelection=[];
end

if ~isfield(options,'plotColorPhases')
    options.plotColorPhases=true;
end


if ~isfield(options,'bootstrap')
    options.bootstrap=[];
end

if ~isfield(options.bootstrap,'numIterations')
    options.bootstrap.numIterations=10000;
end


%% P-value Vs Time


flagstr=[];

trajTypes={'Rise','Fall'};


if options.includeDerivsFlag
   flagstr=[flagstr '-derivsAdded'];
end

if options.derivsOnlyFlag
   flagstr=[flagstr '-derivsOnly'];
end


flagstr=[flagstr '-ds' num2str(options.derivStrength)];

for tn=tnChoice

    for d=1:length(wbDir)

        cd(wbDir{d});
        cS.Rise=load('Quant/wbClusterRiseStruct.mat');
        cS.Fall=load('Quant/wbClusterFallStruct.mat');
        tS=load('Quant/wbTrajStruct.mat');
        trialname{d}=tS.trialname{1};


        tvec{d}=(options.phaseRange(1)+options.phaseOffset) : options.timeWarpStepSize  : (options.phaseRange(2)+options.phaseOffset);

        if ~isempty(options.neuronSelection)
            wbstruct=wbload(wbDir{d},false);
        end

        if options.usePCAStruct


            if options.recomputePCA

                CPoptions=options.recomputePCAOptions;
                CPoptions.saveFlag=false;  
                CPoptions.plotFlag=false;
                pcaS=wbComputePCA(wbDir{d},CPoptions);
            else

                pcaS=wbLoadPCA(wbDir{d},false);
            end
        end




        for i=1:numel(options.neuronSelection)
            neuronTraces(:,i)=wbgettrace(options.neuronSelection{i},wbstruct);
        end

        TWFrames=tS.(['TW' trajTypes{tn} 'Frames']){1};


        PCvec=options.pcSelection;

        p=1;
        for pc=1:numel(PCvec)
            PCvec{pc}
            k=1;
            for t=tvec{d}
                t
                range=(t*length(tS.tv{1})):((t+options.timeWarpRangePerPoint)*length(tS.tv{1})-1);

                if options.usePCAStruct
                    phase1=t;
                    phase2=t+options.timeWarpRangePerPoint;
                    [inputValues nanFlag]=GetTimeWarpTrajectories(fastsmooth(pcaS.pcs,options.postSmoothPCAWindow,3,1),[phase1 phase2],TWFrames,PCvec{pc});         

                elseif ~isempty(options.neuronSelection)
                    disp('neurons')
                    phase1=t;
                    phase2=t+options.timeWarpRangePerPoint;
                    [inputValues nanFlag]=GetTimeWarpTrajectories(neuronTraces,[phase1 phase2],TWFrames);   
                else  %should deprecate this option since it is redundant with pcs
                    inputValues=tS.(['trajFull' trajTypes{tn} 'XYZ']){1}(range,PCvec{pc},:);
                    %nanFlag=false(1,size(inputValues,3));
                end

                derivInputValues=zeros(size(inputValues));
                for z=1:size(inputValues,3);
                    if size(inputValues,1)==1
                        derivInputValues(:,:,z)=zeros(size(inputValues(:,:,z)));
                    else
                        derivInputValues(:,:,z)=options.derivStrength*options.timeWarpRangePerPoint*length(tS.tv{1})*deriv(inputValues(:,:,z));
                    end
                end

                if options.includeDerivsFlag
                    inputValues=[double(~options.derivsOnlyFlag)*inputValues , derivInputValues];
                end
                Boptions.altBootstrapInputValues=inputValues;
                Boptions.altBootstrapDistanceMeasure='euclidean';
                Boptions.altBootstrapNan=nanFlag;  %tS.(['nan' trajTypes{tn}]){1}; %  
                Boptions.bootstrapFlag=true;
                Boptions.bootstrapNumIterations=options.bootstrap.numIterations;
                Boptions.plotFlag=false;
                AltStats=wbClusterBootstrap(cS.(trajTypes{tn}),Boptions);
                pValue{d}.(trajTypes{tn}){p}(k)=AltStats.pValue;

                k=k+1;


            end
            p=p+1;
        end

    end

end

pValueStruct.trialname=trialname;
pValueStruct.pValue=pValue;
pValueStruct.flagstr=flagstr;
pValueStruct.options=options;
pValueStruct.wbDir=wbDir;
pValueStruct.tvec=tvec;

%%plot  
if options.plotFlag
    try
       wbPlotPValues(pValueStruct);
    catch me
    end
end

 



    %local subfuncs
    function [trajectories,nanFlag]=GetTimeWarpTrajectories(traces,phaseRange,TWFrames,subsetIndices)
        if nargin<4 || isempty(subsetIndices)
            subsetIndices=1:size(traces,2);
        end
        len=size(TWFrames,1);
        numTrajs=size(TWFrames,2);
        numFullCycleShifts=floor(phaseRange(1));
        localPhase1=phaseRange(1)-floor(phaseRange(1));
        localPhase2=phaseRange(2)-floor(phaseRange(1));
        
        pr1=floor(localPhase1*len)+1;
        pr2=min([len ceil(localPhase2*len)]);
        trajectories=nan(length(pr1:pr2),length(subsetIndices),numTrajs);
        nanFlag=false(1,numTrajs);
        for nc=1:numTrajs
            for i=subsetIndices
                if nc+numFullCycleShifts<1 || nc+numFullCycleShifts>numTrajs
                    trajectories(:,i,nc)=nan(length(pr1:pr2),1);
                    nanFlag(nc)=true;
                else                
                    trajectories(:,i,nc)=interp1(1:len,traces(:,i),TWFrames(pr1:pr2,min([max([1 nc+numFullCycleShifts]) numTrajs]) )   );
                    nanFlag(nc)=isnan(   trajectories(1,i,nc) );
                end
            end
            
            
        end
        
    end

end