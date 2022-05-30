%% transitions stats


df={['/Users/' thisuser '/Desktop/Dropbox/saulharristinamanuel/analyzedwholebraindatasets/Stim/&forStimProb'],...
     ['/Users/' thisuser '/Desktop/Dropbox/saulharristinamanuel/analyzedwholebraindatasets/NoStim/&forStimProb']};


 
% refNeurons{1}={'AVAR','AVAL','AVAR','AVAL','AVAL',...
%                             'AVAL','AVAR','AVAL','AVAL','AVAL',...
%                             'AVAL','AVAL','AVAL','AVAL','AVAL','AVAR','AVAL'};
                        
refNeurons{1}={'AVAL',...
                            'AVAL','AVAR','AVAL','AVAL','AVAL',...
                            'AVAL','AVAL','AVAL','AVAL','AVAL','AVAR','AVAL'};
                        
refNeurons{2}={'AVAL','AVAL','AVAL','AVAR','AVAL',...
                            'AVAL','AVAL','AVAL','AVAL','AVAL',...
                            'AVAL','AVAL','AVAR'};
    
                        
for i=1:2
    cd(df{i})
    wbStateStats([],[],refNeurons{i});
end


for i=1:2
    cd(df{i});
    wbstructs{i}=wbload([],false);
end



refNeuron='AVAfast';
jointNeuron='SMDV';
refTransitionType='falls';
jointNeuronTransitionType='falls';  %rises


cutoffPre=5;
cutoffPost=5;

for i=1:2
    
    for j=1:length(wbstructs{i})
        [~,~,~,~,keyNeuron{i}{j}]=wbgettrace(jointNeuron,wbstructs{i}{j});
        validIndices{i}=~cellfun(@isempty,keyNeuron{i});
        
    end
       
    [transitionIndicesJoint{i},transitionTimesJoint{i}, traceColoringJoint{i},transitionIndicesJoint{i},transitionTimesNonJoint{i}, traceColoringNonJoint{i}]=wbGetJointTransitions(wbstructs{i}(validIndices{i}),...
        refNeurons{i}(validIndices{i}),refTransitionType,...
        refNeurons{i}(validIndices{i}),refTransitionType,...
        keyNeuron{i}(validIndices{i}),jointNeuronTransitionType,...
        cutoffPre,cutoffPost);
    
end


numJointStimTrials=sum(validIndices{1});
numJointControlTrials=sum(validIndices{2});

%%




%NEW SET
cd(['/Users/' thisuser '/Desktop/Dropbox/saulharristinamanuel/analyzedwholebraindatasets/NoStim/&forStimProb'])
nostim=load('wbStateStatsStruct');
cd(['/Users/' thisuser '/Desktop/Dropbox/saulharristinamanuel/analyzedwholebraindatasets/Stim/&forStimProb'])
stim=load('wbStateStatsStruct');


stim.transitionTimesAllTrials=cellapse(stim.transitionTimes(validIndices{1}));
nostim.transitionTimesAllTrials=cellapse(nostim.transitionTimes(validIndices{2}));

stim.transitionFallTimesAllTrials=cellapse(stim.transitionFallTimes(validIndices{1}));
nostim.transitionFallTimesAllTrials=cellapse(nostim.transitionFallTimes(validIndices{2}));

stim.transitionJointTimesAllTrials=cellapse(transitionTimesJoint{1});
nostim.transitionJointTimesAllTrials=cellapse(transitionTimesJoint{2});

stim.transitionNonJointTimesAllTrials=cellapse(transitionTimesNonJoint{1});
nostim.transitionNonJointTimesAllTrials=cellapse(transitionTimesNonJoint{2});

stim.transitionJointTimesAllTrials(isnan(stim.transitionJointTimesAllTrials))=[];
nostim.transitionJointTimesAllTrials(isnan(nostim.transitionJointTimesAllTrials))=[];

stim.transitionNonJointTimesAllTrials(isnan(stim.transitionNonJointTimesAllTrials))=[];
nostim.transitionNonJointTimesAllTrials(isnan(nostim.transitionNonJointTimesAllTrials))=[];




%binning parameters
totalTime=720; %seconds
stimStartTime=360;
stimEndTime=720;

dt=1/10; %common time base
segSize=30;  %stimulus segment size, seconds
stackSize=60; %seconds
probTimeBin=5; %seconds
numStacks_stim=6;  %sub-section during stimulus
numStacks_prestim=numStacks_stim-1;  %skip first stack

segCenter1=floor(segSize/2); 
numTotalStacks=floor(stimEndTime/stackSize);
binsPerStack=floor(stackSize/probTimeBin);

startingIndex_stim=1+floor(stimStartTime/probTimeBin);  %starting bin index for stimulus period
startingIndex_prestim=1+floor(stackSize/probTimeBin);  %starting bin index for stimulus period, skipping 1st stack


%plotting parameters
gap=[.04 .05];
marg_h=[.05 .05];
marg_w=[.06 .02];
nr=4;nc=4;


[stim_hist,stim_binTimes]=hist(stim.transitionTimesAllTrials,[segCenter1:segSize:(stackSize*(1+numTotalStacks))]);
[nostim_hist,nostim_binTimes]=hist(nostim.transitionTimesAllTrials,[segCenter1:segSize:(stackSize*(1+numTotalStacks))]);

[stim_fall_hist,stim_fall_binTimes]=hist(stim.transitionFallTimesAllTrials,[segCenter1:segSize:(stackSize*(1+numTotalStacks))]);
[nostim_fall_hist,nostim_fall_binTimes]=hist(nostim.transitionFallTimesAllTrials,[segCenter1:segSize:(stackSize*(1+numTotalStacks))]);

[stim_joint_hist,stim_joint_binTimes]=hist(stim.transitionJointTimesAllTrials,[segCenter1:segSize:(stackSize*(1+numTotalStacks))]);
[nostim_joint_hist,nostim_joint_binTimes]=hist(nostim.transitionJointTimesAllTrials,[segCenter1:segSize:(stackSize*(1+numTotalStacks))]);

[stim_nonjoint_hist,stim_nonjoint_binTimes]=hist(stim.transitionNonJointTimesAllTrials,[segCenter1:segSize:(stackSize*(1+numTotalStacks))]);
[nostim_nonjoint_hist,nostim_nonjoint_binTimes]=hist(nostim.transitionNonJointTimesAllTrials,[segCenter1:segSize:(stackSize*(1+numTotalStacks))]);




%compute state traces
commonTV=0:dt:totalTime;

for i=1:length(stim.traceColoring)   
    
   stim.upStateTrace=double(stim.traceColoring{i}==2);
   stim.upOrHiStateTrace=double(stim.traceColoring{i}==2 | stim.traceColoring{i}==3);
   stim.fallStateTrace=double(stim.traceColoring{i}==4);
   stim.fallOrLowStateTrace=double(stim.traceColoring{i}==1 | stim.traceColoring{i}==4);
      
   stim.upStateTraceCommonTimeBase(:,i)=interp1(stim.tv{i},stim.upStateTrace,commonTV,'nearest',0); 
   stim.upOrHiStateTraceCommonTimeBase(:,i)=interp1(stim.tv{i},stim.upOrHiStateTrace,commonTV,'nearest',0); 
   stim.fallStateTraceCommonTimeBase(:,i)=interp1(stim.tv{i},stim.fallStateTrace,commonTV,'nearest',0);
   stim.fallOrLowStateTraceCommonTimeBase(:,i)=interp1(stim.tv{i},stim.fallOrLowStateTrace,commonTV,'nearest',0); 
   
   

end

stim.tvValid=stim.tv(validIndices{1});

for d=1:length(traceColoringJoint{1}) 
      stim.jointStateTrace=traceColoringJoint{1}{d};     
      stim.jointStateTraceCommonTimeBase(:,d)=interp1(stim.tvValid{d},stim.jointStateTrace,commonTV,'nearest',0);

      stim.nonJointStateTrace=traceColoringNonJoint{1}{d};     
      stim.nonJointStateTraceCommonTimeBase(:,d)=interp1(stim.tvValid{d},stim.nonJointStateTrace,commonTV,'nearest',0);

end

disp('yo')

for i=1:length(nostim.traceColoring)
    
   nostim.upStateTrace=double(nostim.traceColoring{i}==2);
   nostim.upOrHiStateTrace=double(nostim.traceColoring{i}==2 | nostim.traceColoring{i}==3);
   nostim.fallStateTrace=double(nostim.traceColoring{i}==4);
   nostim.fallOrLowStateTrace=double(nostim.traceColoring{i}==1 | nostim.traceColoring{i}==4);


   nostim.upStateTraceCommonTimeBase(:,i)=interp1(nostim.tv{i},nostim.upStateTrace,commonTV,'nearest',0); 
   nostim.upOrHiStateTraceCommonTimeBase(:,i)=interp1(nostim.tv{i},nostim.upOrHiStateTrace,commonTV,'nearest',0);  
   nostim.fallStateTraceCommonTimeBase(:,i)=interp1(nostim.tv{i},nostim.fallStateTrace,commonTV,'nearest',0); 
   nostim.fallOrLowStateTraceCommonTimeBase(:,i)=interp1(nostim.tv{i},nostim.fallOrLowStateTrace,commonTV,'nearest',0);  


   
end

nostim.tvValid=nostim.tv(validIndices{2});

for d=1:length(traceColoringJoint{2}) 
      nostim.jointStateTrace=traceColoringJoint{2}{d};
      nostim.nonJointStateTrace=traceColoringNonJoint{2}{d};

      nostim.jointStateTraceCommonTimeBase(:,d)=interp1(nostim.tvValid{d},nostim.jointStateTrace,commonTV,'nearest',0);
      nostim.nonJointStateTraceCommonTimeBase(:,d)=interp1(nostim.tvValid{d},nostim.nonJointStateTrace,commonTV,'nearest',0);

end



%compute fine-binned state probabilities

probIndexBin=round(probTimeBin/dt);
numBins=floor(commonTV(end)/probTimeBin);
probTV=mtv(1:numBins,probTimeBin);
clear('upStateProb');
for i=1:numBins
    binIndexStart=1+(i-1)*probIndexBin;
    binIndexEnd= i*probIndexBin;
    area=length(binIndexStart:binIndexEnd)*length(stim.traceColoring);

    stim.upStateProb(i)=sum(sum(fixnan(stim.upStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    stim.upOrHiStateProb(i)=sum(sum(fixnan(stim.upOrHiStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    stim.fallStateProb(i)=sum(sum(fixnan(stim.fallStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    stim.fallOrLowStateProb(i)=sum(sum(fixnan(stim.fallOrLowStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;

    stim.jointStateProb(i)=sum(sum(fixnan(stim.jointStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    stim.nonJointStateProb(i)=sum(sum(fixnan(stim.nonJointStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    
    
    
    area=length(binIndexStart:binIndexEnd)*length(nostim.traceColoring);

    nostim.upStateProb(i)=sum(sum(fixnan(nostim.upStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    nostim.upOrHiStateProb(i)=sum(sum(fixnan(nostim.upOrHiStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    nostim.fallStateProb(i)=sum(sum(fixnan(nostim.fallStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    nostim.fallOrLowStateProb(i)=sum(sum(fixnan(nostim.fallOrLowStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
       
    nostim.jointStateProb(i)=sum(sum(fixnan(nostim.jointStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    nostim.nonJointStateProb(i)=sum(sum(fixnan(nostim.nonJointStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    
    
    
end


% stacked probability calculation

stim.stackedUpState=zeros(1,binsPerStack);
stim.stackedFallState=zeros(1,binsPerStack);
stim.stackedUpOrHiState=zeros(1,binsPerStack);
stim.stackedFallOrLowState=zeros(1,binsPerStack);
stim.stackedJointState=zeros(1,binsPerStack);
stim.stackedNonJointState=zeros(1,binsPerStack);

nostim.stackedUpState=zeros(1,binsPerStack);
nostim.stackedFallState=zeros(1,binsPerStack);
nostim.stackedUpOrHiState=zeros(1,binsPerStack);
nostim.stackedFallOrLowState=zeros(1,binsPerStack);
nostim.stackedJointState=zeros(1,binsPerStack);
nostim.stackedNonJointState=zeros(1,binsPerStack);


for i=1:numStacks_stim
    
  indexRng=startingIndex_stim+((binsPerStack*(i-1)):(binsPerStack*i-1));

  stim.stackedUpState=stim.stackedUpState+stim.upStateProb(indexRng)/numStacks_stim;
  stim.stackedUpOrHiState=stim.stackedUpOrHiState+stim.upOrHiStateProb(indexRng)/numStacks_stim;
  stim.stackedFallState=stim.stackedFallState+stim.fallStateProb(indexRng)/numStacks_stim;
  stim.stackedFallOrLowState=stim.stackedFallOrLowState+stim.fallOrLowStateProb(indexRng)/numStacks_stim;
  stim.stackedJointState=stim.stackedJointState+stim.jointStateProb(indexRng)/numStacks_stim;
  stim.stackedNonJointState=stim.stackedNonJointState+stim.nonJointStateProb(indexRng)/numStacks_stim;

  
  
  nostim.stackedUpState=nostim.stackedUpState+nostim.upStateProb(indexRng)/numStacks_stim;
  nostim.stackedUpOrHiState=nostim.stackedUpOrHiState+nostim.upOrHiStateProb(indexRng)/numStacks_stim;
  nostim.stackedFallState=nostim.stackedFallState+nostim.fallStateProb(indexRng)/numStacks_stim;
  nostim.stackedFallOrLowState=nostim.stackedFallOrLowState+nostim.fallOrLowStateProb(indexRng)/numStacks_stim;

  nostim.stackedJointState=nostim.stackedJointState+nostim.jointStateProb(indexRng)/numStacks_stim;
  nostim.stackedNonJointState=nostim.stackedNonJointState+nostim.nonJointStateProb(indexRng)/numStacks_stim;

  
end

%PRESTIM AVERAGING  **SKIP first 60s

stim.stackedUpStatePRESTIM=zeros(1,binsPerStack);
stim.stackedUpOrHiStatePRESTIM=zeros(1,binsPerStack);
stim.stackedFallStatePRESTIM=zeros(1,binsPerStack);
stim.stackedFallOrLowStatePRESTIM=zeros(1,binsPerStack);
stim.stackedJointStatePRESTIM=zeros(1,binsPerStack);
stim.stackedNonJointStatePRESTIM=zeros(1,binsPerStack);

nostim.stackedUpStatePRESTIM=zeros(1,binsPerStack);
nostim.stackedUpOrHiStatePRESTIM=zeros(1,binsPerStack);
nostim.stackedFallStatePRESTIM=zeros(1,binsPerStack);
nostim.stackedFallOrLowStatePRESTIM=zeros(1,binsPerStack);
nostim.stackedJointStatePRESTIM=zeros(1,binsPerStack);
nostim.stackedNonJointStatePRESTIM=zeros(1,binsPerStack);

for i=1:numStacks_prestim
    
  indexRng=startingIndex_prestim+((binsPerStack*(i-1)):binsPerStack*i-1);
  
  stim.stackedUpStatePRESTIM=stim.stackedUpStatePRESTIM+stim.upStateProb(indexRng)/numStacks_prestim;
  stim.stackedUpOrHiStatePRESTIM=stim.stackedUpOrHiStatePRESTIM+stim.upOrHiStateProb(indexRng)/numStacks_prestim;
  stim.stackedFallStatePRESTIM=stim.stackedFallStatePRESTIM+stim.fallStateProb(indexRng)/numStacks_prestim;
  stim.stackedFallOrLowStatePRESTIM=stim.stackedFallOrLowStatePRESTIM+stim.fallOrLowStateProb(indexRng)/numStacks_prestim;
  stim.stackedJointStatePRESTIM=stim.stackedJointStatePRESTIM+stim.jointStateProb(indexRng)/numStacks_prestim;
  stim.stackedNonJointStatePRESTIM=stim.stackedNonJointStatePRESTIM+stim.nonJointStateProb(indexRng)/numStacks_prestim;

  nostim.stackedUpStatePRESTIM=nostim.stackedUpStatePRESTIM+nostim.upStateProb(indexRng)/numStacks_prestim;
  nostim.stackedUpOrHiStatePRESTIM=nostim.stackedUpOrHiStatePRESTIM+nostim.upOrHiStateProb(indexRng)/numStacks_prestim;
  nostim.stackedFallStatePRESTIM=nostim.stackedFallStatePRESTIM+nostim.fallStateProb(indexRng)/numStacks_prestim;
  nostim.stackedFallOrLowStatePRESTIM=nostim.stackedFallOrLowStatePRESTIM+nostim.fallOrLowStateProb(indexRng)/numStacks_prestim;
  nostim.stackedJointStatePRESTIM=nostim.stackedJointStatePRESTIM+nostim.jointStateProb(indexRng)/numStacks_prestim;
  nostim.stackedNonJointStatePRESTIM=nostim.stackedNonJointStatePRESTIM+nostim.nonJointStateProb(indexRng)/numStacks_prestim;

end

TVstacked=(0:binsPerStack-1)*probTimeBin+probTimeBin/2;  %bin centers

%%%PLOTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% plot rise / plateaus state stuff

figure('Position',[0 0 1200 1000]);
subtightplot(nr,nc,1,gap,marg_h,marg_w);
ylim([0 max(stim_hist)]);
wbplotstimulus(wbstruct);

hold on;
plot(stim_binTimes(1:end-2),stim_hist(1:end-2),'b.-');
plot(nostim_binTimes(1:end-2),nostim_hist(1:end-2),'r.-');
xlim([0 totalTime]);

vline(stimStartTime);
legend({'stim','nostim'});
ylabel('# of up transitions');
SmartTimeAxis([0 totalTime]);
title('*-to-rise transitions');

subtightplot(nr,nc,2,gap,marg_h,marg_w);
for i=1:length(stim.trialName)
    text(0.2,i,strrep(stim.trialName{i},'_','\_'));
end
xlim([0 10]);
ylim([0 length(stim.trialName)+1]);
set(gca,'YDir','reverse');
ylabel('trial#');
set(gca,'YTick',1:length(stim.trialName));


subtightplot(nr,nc,4,gap,marg_h,marg_w);
for i=1:length(nostim.trialName)
    text(0.2,i,strrep(nostim.trialName{i},'_','\_'));
end
xlim([0 10]);
ylim([0 length(nostim.trialName)+1]);
set(gca,'YDir','reverse');
ylabel('control trial#');
set(gca,'YTick',1:length(nostim.trialName));

NudgeAxis(gca,-.08,0);


subtightplot(nr,nc,5,gap,marg_h,marg_w);
renderBinaryMatrix(fixnan(stim.upStateTraceCommonTimeBase));
colormap([1 1 1;0 0 1])
hold on;
set(gca,'YDir','reverse');

ylabel('trial#');
xlim([0 totalTime/dt]);
set(gca,'XTick',[0:60/dt:totalTime/dt]);
set(gca,'XTickLabel',[0:60:totalTime]);
title('rise states');
set(gca,'YTick',1:length(stim.traceColoring));
set(gca,'YTickLabel',1:length(stim.traceColoring));
ylim([0 length(stim.trialName)+1]);


subtightplot(nr,nc,6,gap,marg_h,marg_w);
renderBinaryMatrix(fixnan(stim.upOrHiStateTraceCommonTimeBase));
set(gca,'YDir','reverse');

colormap([1 1 1;0 0 1])
hold on;
ylabel('trial#');
xlim([0 totalTime/dt]);
set(gca,'XTick',[0:60/dt:totalTime/dt]);
set(gca,'XTickLabel',[0:60:totalTime]);
title('rise or plateau states');
set(gca,'YTick',1:length(stim.traceColoring));
set(gca,'YTickLabel',1:length(stim.traceColoring));
ylim([0 length(stim.trialName)+1]);


subtightplot(nr,nc,7,gap,marg_h,marg_w);
renderBinaryMatrix(fixnan(nostim.upStateTraceCommonTimeBase),[],'r');
colormap([1 1 1;0 0 1])
hold on;
set(gca,'YDir','reverse');

ylabel('control trial#');
xlim([0 totalTime/dt]);
set(gca,'XTick',[0:60/dt:totalTime/dt]);
set(gca,'XTickLabel',[0:60:totalTime]);
title('rise states');
set(gca,'YTick',1:length(nostim.traceColoring));
set(gca,'YTickLabel',1:length(nostim.traceColoring));
ylim([0 length(nostim.trialName)+1]);


subtightplot(nr,nc,8,gap,marg_h,marg_w);
renderBinaryMatrix(fixnan(nostim.upOrHiStateTraceCommonTimeBase),[],'r');
set(gca,'YDir','reverse');

colormap([1 1 1;0 0 1])
hold on;
ylabel('control trial#');
xlim([0 totalTime/dt]);
set(gca,'XTick',[0:60/dt:totalTime/dt]);
set(gca,'XTickLabel',[0:60:totalTime]);
title('rise or plateau states');
set(gca,'YTick',1:length(nostim.traceColoring));
set(gca,'YTickLabel',1:length(nostim.traceColoring));
ylim([0 length(nostim.trialName)+1]);



subtightplot(nr,nc,5+4,gap,marg_h,marg_w);
ylim([0 0.5]);
wbplotstimulus(wbstruct);
hold on;
plot(probTV,stim.upStateProb);
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title('rise state prob [5s time bins]');
ylabel('probability');

subtightplot(nr,nc,6+4,gap,marg_h,marg_w);
ylim([0 1]); 
wbplotstimulus(wbstruct);
hold on;
plot(probTV,stim.upOrHiStateProb);
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title('rise or plateau state prob  [5s time bins]');
ylabel('probability');



subtightplot(nr,nc,7+4,gap,marg_h,marg_w);
ylim([0 0.5]);
wbplotstimulus(wbstruct);
hold on;
plot(probTV,nostim.upStateProb,'r');
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title('rise state prob [5s time bins]');
ylabel('probability');

subtightplot(nr,nc,8+4,gap,marg_h,marg_w);
ylim([0 1]); 
wbplotstimulus(wbstruct);
hold on;
plot(probTV,nostim.upOrHiStateProb,'r');
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title('rise or plateau state prob  [5s time bins]');
ylabel('probability');



subtightplot(nr,nc,7+6,gap,marg_h,marg_w);
vline(segSize);
hold on;
plot(TVstacked,stim.stackedUpStatePRESTIM,'.-');
plot(TVstacked,nostim.stackedUpStatePRESTIM,'r.-');
xlim([0 stackSize]);
title('stacked rise state prob');
set(gca,'XTick',0:10:stackSize);
ylabel('probability');
xlabel('time (s)');
ylim([0 0.75]);

subtightplot(nr,nc,8+6,gap,marg_h,marg_w);
vline(segSize);
hold on;
plot(TVstacked,stim.stackedUpOrHiStatePRESTIM,'.-');
plot(TVstacked,nostim.stackedUpOrHiStatePRESTIM,'r.-');


ylim([0 1]);
xlim([0 stackSize]);
set(gca,'XTick',0:10:stackSize);
title('stacked rise or plateau state prob');
ylabel('probability');
xlabel('time (s)');


subtightplot(nr,nc,7+8,gap,marg_h,marg_w);
rectangle('Position',[0 0 30 .75],'FaceColor',color('lightgray'),'EdgeColor','none');
hold on;
plot(TVstacked,stim.stackedUpState,'.-');
plot(TVstacked,nostim.stackedUpState,'r.-');
xlim([0 stackSize]);
title('stacked rise state prob');
ylabel('probability');
xlabel('time (s)');
set(gca,'XTick',0:10:stackSize);
ylim([0 0.75]);

subtightplot(nr,nc,8+8,gap,marg_h,marg_w);
rectangle('Position',[0 0 30 1],'FaceColor',color('lightgray'),'EdgeColor','none');
hold on;
plot(TVstacked,stim.stackedUpOrHiState,'.-');
plot(TVstacked,nostim.stackedUpOrHiState,'r.-');

ylim([0 1]);
xlim([0 stackSize]);
set(gca,'XTick',0:10:stackSize);
title('stacked rise or plateau state prob');
ylabel('probability');
xlabel('time (s)');

mtit(['rise and plateau analysis :  bin size ' num2str(probTimeBin) ' s']);

export_fig(['transitionsJoint_StimVsnoStim-bin' num2str(probTimeBin) 's.pdf']);


%% plot joint state stuff

figure('Position',[0 0 1200 1000]);

subtightplot(nr,nc,1,gap,marg_h,marg_w);
ylim([0 max(stim_joint_hist)/numJointStimTrials]);
wbplotstimulus;
hold on;
plot(stim_joint_binTimes(1:end-2),stim_joint_hist(1:end-2)/numJointStimTrials,'b.-');
plot(nostim_joint_binTimes(1:end-2),nostim_joint_hist(1:end-2)/numJointControlTrials,'r.-');
xlim([0 totalTime]);

vline(stimStartTime);
legend({'stim','nostim'});
ylabel('# of joint transitions per trial');
SmartTimeAxis([0 totalTime]);
title(['joint transitions (+ ' jointNeuron ')']);


subtightplot(nr,nc,2,gap,marg_h,marg_w);
ylim([0 max(stim_joint_hist)/numJointStimTrials]);
wbplotstimulus;
hold on;
plot(stim_nonjoint_binTimes(1:end-2),stim_nonjoint_hist(1:end-2)/numJointStimTrials,'b.-');
plot(nostim_nonjoint_binTimes(1:end-2),nostim_nonjoint_hist(1:end-2)/numJointControlTrials,'r.-');
xlim([0 totalTime]);

vline(stimStartTime);
legend({'stim','nostim'});
ylabel('# of NONjoint transitions per trial');
SmartTimeAxis([0 totalTime]);
title(['NONjoint transitions (-' jointNeuron ')']);



subtightplot(nr,nc,3,gap,marg_h,marg_w);
vsIn=find(validIndices{1});
vuIn=find(validIndices{2});
for i=1:length(vsIn)
    text(0.2,i,strrep(wbMakeShortTrialname(stim.trialName{ vsIn(i) }),'_','\_'));
end
xlim([0 10]);
ylim([0 length(vsIn)+1]);
set(gca,'YDir','reverse');
ylabel('trial#');
set(gca,'YTick',1:length(vsIn));


subtightplot(nr,nc,4,gap,marg_h,marg_w);
for i=1:length(vuIn)
    text(0.2,i,strrep(wbMakeShortTrialname(nostim.trialName{ vuIn(i) }),'_','\_'));
end
xlim([0 10]);
ylim([0 length(vuIn)+1]);
set(gca,'YDir','reverse');
ylabel('control trial#');
set(gca,'YTick',1:length(vuIn));




subtightplot(nr,nc,5,gap,marg_h,marg_w);
renderBinaryMatrix(fixnan(stim.jointStateTraceCommonTimeBase));
colormap([1 1 1;0 0 1])
hold on;
set(gca,'YDir','reverse');
ylabel('trial#');
xlim([0 totalTime/dt]);
set(gca,'XTick',[0:60/dt:totalTime/dt]);
set(gca,'XTickLabel',[0:60:totalTime]);
title([refNeuron ' joint ' refTransitionType ' states']);
set(gca,'YTick',1:length(stim.tvValid));
set(gca,'YTickLabel',1:length(stim.tvValid));
ylim([0 length(stim.tvValid)+1]);



subtightplot(nr,nc,6,gap,marg_h,marg_w);
renderBinaryMatrix(fixnan(stim.nonJointStateTraceCommonTimeBase));
set(gca,'YDir','reverse');

colormap([1 1 1;0 0 1])
hold on;
ylabel('trial#');
xlim([0 totalTime/dt]);
set(gca,'XTick',[0:60/dt:totalTime/dt]);
set(gca,'XTickLabel',[0:60:totalTime]);
title([refNeuron ' NONjoint ' refTransitionType ' states']);
set(gca,'YTick',1:length(stim.tvValid));
set(gca,'YTickLabel',1:length(stim.tvValid));
ylim([0 length(nostim.tvValid)+1]);


subtightplot(nr,nc,7,gap,marg_h,marg_w);
renderBinaryMatrix(fixnan(nostim.jointStateTraceCommonTimeBase),[],'r');
colormap([1 1 1;0 0 1])
hold on;
set(gca,'YDir','reverse');
ylabel('control trial#');
xlim([0 totalTime/dt]);
set(gca,'XTick',[0:60/dt:totalTime/dt]);
set(gca,'XTickLabel',[0:60:totalTime]);
title([refNeuron ' CONTROL joint ' refTransitionType ' states']);
set(gca,'YTick',1:length(nostim.tvValid));
set(gca,'YTickLabel',1:length(nostim.tvValid));
ylim([0 length(nostim.tvValid)+1]);


subtightplot(nr,nc,8,gap,marg_h,marg_w);
renderBinaryMatrix(fixnan(nostim.nonJointStateTraceCommonTimeBase),[],'r');
set(gca,'YDir','reverse');
colormap([1 1 1;0 0 1])
hold on;
ylabel('control trial#');
xlim([0 totalTime/dt]);
set(gca,'XTick',[0:60/dt:totalTime/dt]);
set(gca,'XTickLabel',[0:60:totalTime]);
title([refNeuron ' CONTROL NON joint ' refTransitionType ' states']);
set(gca,'YTick',1:length(nostim.tvValid));
set(gca,'YTickLabel',1:length(nostim.tvValid));
ylim([0 length(nostim.tvValid)+1]);

subtightplot(nr,nc,5+4,gap,marg_h,marg_w);
ylim([0 0.5]);
wbplotstimulus;
hold on;
plot(probTV,stim.jointStateProb);
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title(['joint state prob [' probTimeBin 's time bins]']);
ylabel('probability');

subtightplot(nr,nc,6+4,gap,marg_h,marg_w);
ylim([0 1]); 
wbplotstimulus;
hold on;
plot(probTV,stim.nonJointStateProb);
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title(['NONjoint state prob  [5' probTimeBin 's time bins]']);
ylabel('probability');



subtightplot(nr,nc,7+4,gap,marg_h,marg_w);
ylim([0 0.5]);
wbplotstimulus;
hold on;
plot(probTV,nostim.jointStateProb,'r');
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title('CONTROL joint state prob [5s time bins]');
ylabel('probability');

subtightplot(nr,nc,8+4,gap,marg_h,marg_w);
ylim([0 1]); 
wbplotstimulus;
hold on;
plot(probTV,nostim.nonJointStateProb,'r');
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title('CONTROL NONjoint state prob  [5s time bins]');
ylabel('probability');



subtightplot(nr,nc,7+6,gap,marg_h,marg_w);
vline(segSize);
hold on;
plot(TVstacked,stim.stackedJointStatePRESTIM,'.-');
plot(TVstacked,nostim.stackedJointStatePRESTIM,'r.-');
xlim([0 stackSize]);
title('PRESTIM stacked joint state prob');
set(gca,'XTick',0:10:stackSize);
ylabel('probability');
xlabel('time (s)');
ylim([0 0.2]);

subtightplot(nr,nc,8+6,gap,marg_h,marg_w);
vline(segSize);
hold on;
plot(TVstacked,stim.stackedNonJointStatePRESTIM,'.-');
plot(TVstacked,nostim.stackedNonJointStatePRESTIM,'r.-');
ylim([0 .2]);
xlim([0 stackSize]);
set(gca,'XTick',0:10:stackSize);
title('PRESTIM stacked NONjoint state prob');
ylabel('probability');
xlabel('time (s)');


subtightplot(nr,nc,7+8,gap,marg_h,marg_w);
rectangle('Position',[0 0 30 .75],'FaceColor',color('lightgray'),'EdgeColor','none');
hold on;
plot(TVstacked,stim.stackedJointState,'.-');
plot(TVstacked,nostim.stackedJointState,'r.-');
xlim([0 stackSize]);
title('stacked joint state prob');
ylabel('probability');
xlabel('time (s)');
set(gca,'XTick',0:10:stackSize);
ylim([0 0.2]);

subtightplot(nr,nc,8+8,gap,marg_h,marg_w);
rectangle('Position',[0 0 30 1],'FaceColor',color('lightgray'),'EdgeColor','none');
hold on;
plot(TVstacked,stim.stackedNonJointState,'.-');
plot(TVstacked,nostim.stackedNonJointState,'r.-');
ylim([0 .2]);
xlim([0 stackSize]);
set(gca,'XTick',0:10:stackSize);
title('stacked NONjoint state prob');
ylabel('probability');
xlabel('time (s)');

mtit(['joint state analysis : ' refNeuron ':' refTransitionType '+' jointNeuron ':' jointNeuronTransitionType ' bin size ' num2str(probTimeBin) ' s'],'yoff',.02);
export_fig(['transitionsJoint_StimVsnoStim-' refNeuron '-' refTransitionType ...
    '-' jointNeuron '-' jointNeuronTransitionType '-bin' num2str(probTimeBin) 's.pdf'],'-append');

