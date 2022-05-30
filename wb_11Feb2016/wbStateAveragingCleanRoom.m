%% transitions stats


options.plotFlag=false;
options.subPlotFlag=false;

df={'/Users/skato/Desktop/Dropbox/saulharristinamanuel/analyzedwholebraindatasets/Stim/&forStimProb',...
     '/Users/skato/Desktop/Dropbox/saulharristinamanuel/analyzedwholebraindatasets/NoStim/&forStimProb'};

 
refNeurons{1}={'AVAR','AVAL','AVAR','AVAL','AVAL',...
                            'AVAL','AVAR','AVAL','AVAL','AVAL',...
                            'AVAL','AVAL','AVAL','AVAL','AVAL','AVAR','AVAL'};
                        
refNeurons{2}={'AVAL','AVAL','AVAL','AVAR','AVAL',...
                            'AVAL','AVAL','AVAL','AVAL','AVAL',...
                            'AVAL','AVAL','AVAR'};
    
% for i=1:2
%     cd(df{i})
%     wbStateStats([],[],refNeurons{i});
% end

numStimTrials=length(refNeurons{1});
numControlTrials=length(refNeurons{2});



%NEW SET
cd('/Users/skato/Desktop/Dropbox/saulharristinamanuel/analyzedwholebraindatasets/NoStim/&forStimProb')
nostim=load('wbStateStatsStruct');

cd('/Users/skato/Desktop/Dropbox/saulharristinamanuel/analyzedwholebraindatasets/Stim/&forStimProb')
stim=load('wbStateStatsStruct');
stimFolders=listfolders([],true);

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


%compute state traces
commonTV=0:dt:totalTime;

for i=1:length(stim.traceColoring)   
    i
   stim.upStateTrace=double(stim.traceColoring{i}==2);
   
   CS=load([stimFolders{i} filesep 'Quant' filesep 'wbClusterRiseStruct.mat']);
   PRL=CS.PRL;
   stim.rise1StateTrace=zeros(size(stim.upStateTrace));
   for tr=1:length(stim.transitionTimes{i})
       if PRL.clusterMembership(tr)==2
           disp('yo')
           stim.rise1StateTrace( stim.stateRunStartIndices{i,2}(tr)  : ( stim.stateRunStartIndices{i,2}(tr) ...
            + stim.stateFrameLengths{i,2}(tr)-1))=1;
       end
   end
   size(stim.rise1StateTrace)
   size(stim.tv{i})
   stim.upOrHiStateTrace=double(stim.traceColoring{i}==2 | stim.traceColoring{i}==3);
   stim.fallStateTrace=double(stim.traceColoring{i}==4);
   stim.fallOrLowStateTrace=double(stim.traceColoring{i}==1 | stim.traceColoring{i}==4);
   
   stim.upStateTraceCommonTimeBase(:,i)=interp1(stim.tv{i},stim.upStateTrace,commonTV,'nearest',0); 
   stim.upOrHiStateTraceCommonTimeBase(:,i)=interp1(stim.tv{i},stim.upOrHiStateTrace,commonTV,'nearest',0); 
   stim.fallStateTraceCommonTimeBase(:,i)=interp1(stim.tv{i},stim.fallStateTrace,commonTV,'nearest',0);
   stim.fallOrLowStateTraceCommonTimeBase(:,i)=interp1(stim.tv{i},stim.fallOrLowStateTrace,commonTV,'nearest',0); 
   
   stim.rise1StateTraceCommonTimeBase(:,i)=interp1(stim.tv{i},stim.rise1StateTrace,commonTV,'nearest',0); 

end


for i=1:length(nostim.traceColoring)
    
   nostim.upStateTrace=double(nostim.traceColoring{i}==2);
   
   
   nostim.rise1StateTrace=nostim.upStateTrace;
   
   nostim.upOrHiStateTrace=double(nostim.traceColoring{i}==2 | nostim.traceColoring{i}==3);
   nostim.fallStateTrace=double(nostim.traceColoring{i}==4);
   nostim.fallOrLowStateTrace=double(nostim.traceColoring{i}==1 | nostim.traceColoring{i}==4);

   nostim.upStateTraceCommonTimeBase(:,i)=interp1(nostim.tv{i},nostim.upStateTrace,commonTV,'nearest',0); 
   nostim.upOrHiStateTraceCommonTimeBase(:,i)=interp1(nostim.tv{i},nostim.upOrHiStateTrace,commonTV,'nearest',0);  
   nostim.fallStateTraceCommonTimeBase(:,i)=interp1(nostim.tv{i},nostim.fallStateTrace,commonTV,'nearest',0); 
   nostim.fallOrLowStateTraceCommonTimeBase(:,i)=interp1(nostim.tv{i},nostim.fallOrLowStateTrace,commonTV,'nearest',0);  

   nostim.rise1StateTraceCommonTimeBase(:,i)=interp1(nostim.tv{i},nostim.rise1StateTrace,commonTV,'nearest',0); 

   
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
    stim.rise1StateProb(i)=sum(sum(fixnan(stim.rise1StateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    stim.upOrHiStateProb(i)=sum(sum(fixnan(stim.upOrHiStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    stim.fallStateProb(i)=sum(sum(fixnan(stim.fallStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    stim.fallOrLowStateProb(i)=sum(sum(fixnan(stim.fallOrLowStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;

    area=length(binIndexStart:binIndexEnd)*length(nostim.traceColoring);

    nostim.upStateProb(i)=sum(sum(fixnan(nostim.upStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    nostim.rise1StateProb(i)=sum(sum(fixnan(nostim.rise1StateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    nostim.upOrHiStateProb(i)=sum(sum(fixnan(nostim.upOrHiStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    nostim.fallStateProb(i)=sum(sum(fixnan(nostim.fallStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    nostim.fallOrLowStateProb(i)=sum(sum(fixnan(nostim.fallOrLowStateTraceCommonTimeBase(binIndexStart:binIndexEnd,:))))/area;
    
end


% stacked probability calculation

stim.stackedUpState=zeros(1,binsPerStack);
stim.stackedRise1State=zeros(1,binsPerStack);
stim.stackedFallState=zeros(1,binsPerStack);
stim.stackedUpOrHiState=zeros(1,binsPerStack);
stim.stackedFallOrLowState=zeros(1,binsPerStack);
nostim.stackedUpState=zeros(1,binsPerStack);
nostim.stackedRise1State=zeros(1,binsPerStack);
nostim.stackedFallState=zeros(1,binsPerStack);
nostim.stackedUpOrHiState=zeros(1,binsPerStack);
nostim.stackedFallOrLowState=zeros(1,binsPerStack);


for i=1:numStacks_stim
    
  indexRng=startingIndex_stim+((binsPerStack*(i-1)):(binsPerStack*i-1));

  stim.stackedUpState=stim.stackedUpState+stim.upStateProb(indexRng)/numStacks_stim;
  stim.stackedRise1State=stim.stackedRise1State+stim.rise1StateProb(indexRng)/numStacks_stim;
  stim.stackedUpOrHiState=stim.stackedUpOrHiState+stim.upOrHiStateProb(indexRng)/numStacks_stim;
  stim.stackedFallState=stim.stackedFallState+stim.fallStateProb(indexRng)/numStacks_stim;
  stim.stackedFallOrLowState=stim.stackedFallOrLowState+stim.fallOrLowStateProb(indexRng)/numStacks_stim;

  nostim.stackedUpState=nostim.stackedUpState+nostim.upStateProb(indexRng)/numStacks_stim;
  nostim.stackedRise1State=nostim.stackedRise1State+nostim.rise1StateProb(indexRng)/numStacks_stim;
  nostim.stackedUpOrHiState=nostim.stackedUpOrHiState+nostim.upOrHiStateProb(indexRng)/numStacks_stim;
  nostim.stackedFallState=nostim.stackedFallState+nostim.fallStateProb(indexRng)/numStacks_stim;
  nostim.stackedFallOrLowState=nostim.stackedFallOrLowState+nostim.fallOrLowStateProb(indexRng)/numStacks_stim;

end

%PRESTIM AVERAGING  **SKIP first 60s

stim.stackedUpStatePRESTIM=zeros(1,binsPerStack);
stim.stackedUpOrHiStatePRESTIM=zeros(1,binsPerStack);
stim.stackedFallStatePRESTIM=zeros(1,binsPerStack);
stim.stackedFallOrLowStatePRESTIM=zeros(1,binsPerStack);

nostim.stackedUpStatePRESTIM=zeros(1,binsPerStack);
nostim.stackedUpOrHiStatePRESTIM=zeros(1,binsPerStack);
nostim.stackedFallStatePRESTIM=zeros(1,binsPerStack);
nostim.stackedFallOrLowStatePRESTIM=zeros(1,binsPerStack);

for i=1:numStacks_prestim
    
  indexRng=startingIndex_prestim+((binsPerStack*(i-1)):binsPerStack*i-1);
  
  
  
  stim.stackedUpStatePRESTIM=stim.stackedUpStatePRESTIM+stim.upStateProb(indexRng)/numStacks_prestim;
  stim.stackedUpOrHiStatePRESTIM=stim.stackedUpOrHiStatePRESTIM+stim.upOrHiStateProb(indexRng)/numStacks_prestim;
  stim.stackedFallStatePRESTIM=stim.stackedFallStatePRESTIM+stim.fallStateProb(indexRng)/numStacks_prestim;
  stim.stackedFallOrLowStatePRESTIM=stim.stackedFallOrLowStatePRESTIM+stim.fallOrLowStateProb(indexRng)/numStacks_prestim;

  nostim.stackedUpStatePRESTIM=nostim.stackedUpStatePRESTIM+nostim.upStateProb(indexRng)/numStacks_prestim;
  nostim.stackedUpOrHiStatePRESTIM=nostim.stackedUpOrHiStatePRESTIM+nostim.upOrHiStateProb(indexRng)/numStacks_prestim;
  nostim.stackedFallStatePRESTIM=nostim.stackedFallStatePRESTIM+nostim.fallStateProb(indexRng)/numStacks_prestim;
  nostim.stackedFallOrLowStatePRESTIM=nostim.stackedFallOrLowStatePRESTIM+nostim.fallOrLowStateProb(indexRng)/numStacks_prestim;

end

TVstacked=(0:binsPerStack-1)*probTimeBin+probTimeBin/2;  %bin centers

%%%PLOTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% plot rise / plateaus state stuff

figure('Position',[0 0 1200 1000]);
subtightplot(nr,nc,1,gap,marg_h,marg_w);
ylim([0 max(stim_hist)/numStimTrials]);
wbplotstimulus;

hold on;
plot(stim_binTimes(1:end-2),stim_hist(1:end-2)/numStimTrials,'b.-');
plot(nostim_binTimes(1:end-2),nostim_hist(1:end-2)/numControlTrials,'r.-');
xlim([0 totalTime]);

vline(stimStartTime);
legend({'stim','nostim'});
ylabel('# of up transitions /trial');
SmartTimeAxis([0 totalTime]);
title('(r1) *-to-rise transitions per trial');

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
title('(r2) rise states');
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
title('(r3) rise or plateau states');
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
title('(r4) rise states');
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
title('(r5) rise or plateau states');
set(gca,'YTick',1:length(nostim.traceColoring));
set(gca,'YTickLabel',1:length(nostim.traceColoring));
ylim([0 length(nostim.trialName)+1]);



subtightplot(nr,nc,5+4,gap,marg_h,marg_w);
ylim([0 0.25]);
wbplotstimulus;
hold on;
plot(probTV,stim.upStateProb);

plot(probTV,stim.rise1StateProb,'c');


SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title(['(r6) rise state prob [' num2str(probTimeBin) 's time bins]']);
ylabel('probability');



subtightplot(nr,nc,6+4,gap,marg_h,marg_w);
ylim([0 1]); 
wbplotstimulus;
hold on;
plot(probTV,stim.upOrHiStateProb);
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title(['(r7) rise or plateau state prob  [' num2str(probTimeBin)  's time bins]']);
ylabel('probability');
set(gca,'YTick',[0 0.25 0.5 0.75 1]);



subtightplot(nr,nc,7+4,gap,marg_h,marg_w);
ylim([0 0.5]);
wbplotstimulus;
hold on;
plot(probTV,nostim.upStateProb,'r');
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title(['(r8) rise state prob [' num2str(probTimeBin) 's time bins]']);
ylabel('probability');


subtightplot(nr,nc,8+4,gap,marg_h,marg_w);
ylim([0 1]); 
wbplotstimulus;
hold on;
plot(probTV,nostim.upOrHiStateProb,'r');
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title(['(r9) rise or plateau state prob  [' num2str(probTimeBin) 's time bins]']);
ylabel('probability');



subtightplot(nr,nc,7+6,gap,marg_h,marg_w);
vline(segSize);
hold on;


plot(TVstacked,stim.stackedUpStatePRESTIM,'.-');
plot(TVstacked,nostim.stackedUpStatePRESTIM,'r.-');
xlim([0 stackSize]);
title('(r10) stacked rise state prob');
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
title('(r11) stacked rise or plateau state prob');
ylabel('probability');
xlabel('time (s)');


subtightplot(nr,nc,7+8,gap,marg_h,marg_w);
rectangle('Position',[0 0 30 .75],'FaceColor',color('lightgray'),'EdgeColor','none');
hold on;
plot(TVstacked,stim.stackedUpState,'-');
plot(TVstacked,stim.stackedRise1State,'c-');
plot(TVstacked,nostim.stackedUpState,'r-');
xlim([0 stackSize]);
title('(r12) stacked rise state prob');
ylabel('probability');
xlabel('time (s)');
set(gca,'XTick',0:10:stackSize);
ylim([0 0.2]);

subtightplot(nr,nc,8+8,gap,marg_h,marg_w);
rectangle('Position',[0 0 30 1],'FaceColor',color('lightgray'),'EdgeColor','none');
hold on;
plot(TVstacked,stim.stackedUpOrHiState,'-');
plot(TVstacked,nostim.stackedUpOrHiState,'r-');

ylim([0.25 .6]);
xlim([0 stackSize]);
set(gca,'XTick',0:10:stackSize);
title('(r13) stacked rise or plateau state prob');
ylabel('probability');
xlabel('time (s)');
set(gca,'YTick',[0:.1:.6]);


mtit(['rise and plateau analysis :  bin size ' num2str(probTimeBin) ' s']);

save2pdf(['StimeStateProbRise2' num2str(probTimeBin) 's.pdf']);
%

%%
%aux fig: stacking check
figure('Position',[0 0 1200 1000]);

subtightplot(2,2,1,[0.05 .05]);
rectangle('Position',[0 0 30 1],'FaceColor',color('lightgray'),'EdgeColor','none');
hold on;
for i=1:numStacks_stim
  indexRng=startingIndex_stim+((binsPerStack*(i-1)):binsPerStack*i-1);
  plot(TVstacked,stim.upStateProb(indexRng),'Color',color(i,6));
  
end
legend({'p1','p2','p3','p4','p5','p6'});
title('stim: rise only');
ylim([0 0.3]);
plot(TVstacked,stim.stackedUpState,'Color','b','LineWidth',2); 


subtightplot(2,2,2,[0.05 .05]);
rectangle('Position',[0 0 30 1],'FaceColor',color('lightgray'),'EdgeColor','none');

hold on;
for i=1:numStacks_stim
  indexRng=startingIndex_stim+((binsPerStack*(i-1)):binsPerStack*i-1);
  plot(TVstacked,nostim.upStateProb(indexRng),'Color',color(i,6));
  
end

plot(TVstacked,nostim.stackedUpState,'Color','r','LineWidth',2); 

legend({'p1','p2','p3','p4','p5','p6'});
title('nostim (control) rise only');
ylim([0 0.3]);


subtightplot(2,2,3,[0.05 .05]);
rectangle('Position',[0 0 30 1],'FaceColor',color('lightgray'),'EdgeColor','none');
hold on;
for i=1:numStacks_stim
  indexRng=startingIndex_stim+((binsPerStack*(i-1)):binsPerStack*i-1);
  plot(TVstacked,stim.upOrHiStateProb(indexRng),'Color',color(i,6));
  
end

plot(TVstacked,stim.stackedUpOrHiState,'Color','b','LineWidth',2); 



legend({'p1','p2','p3','p4','p5','p6'});
title('stim: rise&plateau');
ylim([0 0.8]);

subtightplot(2,2,4,[0.05 .05]);
rectangle('Position',[0 0 30 1],'FaceColor',color('lightgray'),'EdgeColor','none');

hold on;
for i=1:numStacks_stim
  indexRng=startingIndex_stim+((binsPerStack*(i-1)):binsPerStack*i-1);
  plot(TVstacked,nostim.upOrHiStateProb(indexRng),'Color',color(i,6));
  
end

plot(TVstacked,nostim.stackedUpOrHiState,'Color','r','LineWidth',2); 

legend({'p1','p2','p3','p4','p5','p6'});
title('nostim (control) rise&plateau');
ylim([0 0.8]);

mtit('STACK AVERAGING VERIFCATION');
%export_fig(['transitions_STACKS_StimVsnoStim-bin' num2str(probTimeBin) 's.pdf'])


%   stim.stackedUpOrHiStatePRESTIM=stim.stackedUpOrHiStatePRESTIM+stim.upOrHiStateProb(indexRng)/numStacks_prestim;
%   stim.stackedFallStatePRESTIM=stim.stackedFallStatePRESTIM+stim.fallStateProb(indexRng)/numStacks_prestim;
%   stim.stackedFallOrLowStatePRESTIM=stim.stackedFallOrLowStatePRESTIM+stim.fallOrLowStateProb(indexRng)/numStacks_prestim;
% 
%   nostim.stackedUpStatePRESTIM=nostim.stackedUpStatePRESTIM+nostim.upStateProb(indexRng)/numStacks_prestim;
%   nostim.stackedUpOrHiStatePRESTIM=nostim.stackedUpOrHiStatePRESTIM+nostim.upOrHiStateProb(indexRng)/numStacks_prestim;
%   nostim.stackedFallStatePRESTIM=nostim.stackedFallStatePRESTIM+nostim.fallStateProb(indexRng)/numStacks_prestim;
%   nostim.stackedFallOrLowStatePRESTIM=nostim.stackedFallOrLowStatePRESTIM+nostim.fallOrLowStateProb(indexRng)/numStacks_prestim;
% 
% end



%plot fall/trough state stuff

figure('Position',[0 0 1200 1000]);

subtightplot(nr,nc,1,gap,marg_h,marg_w);
ylim([0 max(stim_fall_hist)/numStimTrials]);
wbplotstimulus;
hold on;
plot(stim_fall_binTimes(1:end-2),stim_fall_hist(1:end-2)/numStimTrials,'b.-');
plot(nostim_fall_binTimes(1:end-2),nostim_fall_hist(1:end-2)/numControlTrials,'r.-');
xlim([0 totalTime]);

vline(stimStartTime);
legend({'stim','nostim'});
ylabel('# of fall transitions / trial');
SmartTimeAxis([0 totalTime]);
title('*-to-fall transitions per trial');


subtightplot(nr,nc,5,gap,marg_h,marg_w);
renderBinaryMatrix(fixnan(stim.fallStateTraceCommonTimeBase));
colormap([1 1 1;0 0 1])
hold on;
set(gca,'YDir','reverse');

ylabel('trial#');
xlim([0 totalTime/dt]);
set(gca,'XTick',[0:60/dt:totalTime/dt]);
set(gca,'XTickLabel',[0:60:totalTime]);
title('fall states');
set(gca,'YTick',1:length(stim.traceColoring));
set(gca,'YTickLabel',1:length(stim.traceColoring));
ylim([0 length(stim.trialName)+1]);


subtightplot(nr,nc,6,gap,marg_h,marg_w);
renderBinaryMatrix(fixnan(stim.fallOrLowStateTraceCommonTimeBase));
set(gca,'YDir','reverse');

colormap([1 1 1;0 0 1])
hold on;
ylabel('trial#');
xlim([0 totalTime/dt]);
set(gca,'XTick',[0:60/dt:totalTime/dt]);
set(gca,'XTickLabel',[0:60:totalTime]);
title('fall or trough states');
set(gca,'YTick',1:length(stim.traceColoring));
set(gca,'YTickLabel',1:length(stim.traceColoring));
ylim([0 length(stim.trialName)+1]);


subtightplot(nr,nc,7,gap,marg_h,marg_w);
renderBinaryMatrix(fixnan(nostim.fallStateTraceCommonTimeBase),[],'r');
colormap([1 1 1;0 0 1])
hold on;
set(gca,'YDir','reverse');
ylabel('control trial#');
xlim([0 totalTime/dt]);
set(gca,'XTick',[0:60/dt:totalTime/dt]);
set(gca,'XTickLabel',[0:60:totalTime]);
title('fall states');
set(gca,'YTick',1:length(nostim.traceColoring));
set(gca,'YTickLabel',1:length(nostim.traceColoring));
ylim([0 length(nostim.trialName)+1]);


subtightplot(nr,nc,8,gap,marg_h,marg_w);
renderBinaryMatrix(fixnan(nostim.fallOrLowStateTraceCommonTimeBase),[],'r');
set(gca,'YDir','reverse');
colormap([1 1 1;0 0 1])
hold on;
ylabel('control trial#');
xlim([0 totalTime/dt]);
set(gca,'XTick',[0:60/dt:totalTime/dt]);
set(gca,'XTickLabel',[0:60:totalTime]);
title('fall or trough states');
set(gca,'YTick',1:length(nostim.traceColoring));
set(gca,'YTickLabel',1:length(nostim.traceColoring));
ylim([0 length(nostim.trialName)+1]);



subtightplot(nr,nc,5+4,gap,marg_h,marg_w);
ylim([0 0.5]);
wbplotstimulus;
hold on;
plot(probTV,stim.fallStateProb);
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title('fall state prob [5s time bins]');
ylabel('probability');

subtightplot(nr,nc,6+4,gap,marg_h,marg_w);
ylim([0 1]); 
wbplotstimulus;
hold on;
plot(probTV,stim.fallOrLowStateProb);
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title('fall or trough state prob  [5s time bins]');
ylabel('probability');

set(gca,'YTick',[0 0.25 0.5 0.75 1]);


subtightplot(nr,nc,7+4,gap,marg_h,marg_w);
ylim([0 0.5]);
wbplotstimulus;
hold on;
plot(probTV,nostim.fallStateProb,'r');
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title('fall state prob [5s time bins]');
ylabel('probability');

subtightplot(nr,nc,8+4,gap,marg_h,marg_w);
ylim([0 1]); 
wbplotstimulus;
hold on;
plot(probTV,nostim.fallOrLowStateProb,'r');
SmartTimeAxis([0 totalTime]);
xlim([0 totalTime]);
title('fall or trough state prob  [5s time bins]');
ylabel('probability');
set(gca,'YTick',[0 0.25 0.5 0.75 1]);





subtightplot(nr,nc,7+6,gap,marg_h,marg_w);
vline(segSize);
hold on;
plot(TVstacked,stim.stackedFallStatePRESTIM,'.-');
plot(TVstacked,nostim.stackedFallStatePRESTIM,'r.-');
xlim([0 stackSize]);
title('stacked fall state prob');
set(gca,'XTick',0:10:stackSize);
ylabel('probability');
xlabel('time (s)');
ylim([0 0.75]);

subtightplot(nr,nc,8+6,gap,marg_h,marg_w);
vline(segSize);
hold on;
plot(TVstacked,stim.stackedFallOrLowStatePRESTIM,'.-');
plot(TVstacked,nostim.stackedFallOrLowStatePRESTIM,'r.-');
ylim([0 1]);
xlim([0 stackSize]);
set(gca,'XTick',0:10:stackSize);
title('stacked fall or trough state prob');
ylabel('probability');
xlabel('time (s)');


subtightplot(nr,nc,7+8,gap,marg_h,marg_w);
rectangle('Position',[0 0 30 .75],'FaceColor',color('lightgray'),'EdgeColor','none');
hold on;
plot(TVstacked,stim.stackedFallState,'-');
plot(TVstacked,nostim.stackedFallState,'r-');
xlim([0 stackSize]);
title('stacked fall state prob');
ylabel('probability');
xlabel('time (s)');
set(gca,'XTick',0:10:stackSize);
ylim([0 0.75]);
set(gca,'YTick',[0 0.25 0.5 0.75 1]);

subtightplot(nr,nc,8+8,gap,marg_h,marg_w);
rectangle('Position',[0 0 30 1],'FaceColor',color('lightgray'),'EdgeColor','none');
hold on;
plot(TVstacked,stim.stackedFallOrLowState,'-');
plot(TVstacked,nostim.stackedFallOrLowState,'r-');
ylim([0.2 0.8]);
xlim([0 stackSize]);
set(gca,'XTick',0:10:stackSize);
title('stacked fall or trough state prob');
ylabel('probability');
xlabel('time (s)');
set(gca,'YTick',[0.25 0.5 0.75]);

mtit(['fall and trough analysis :  bin size ' num2str(probTimeBin) ' s']);


%export_fig(['transitions_StimVsnoStim-bin' num2str(probTimeBin) 's.pdf'],'-append');





%% compute p-values for phase shuffled

numSamples=100000;
randomPhaseShifts=4*rand(numSamples,size(stim.fallOrLowStateTraceCommonTimeBase,2))-1;

thisStartingIndex=3601;
thisEndingIndex=7201;

stackedBinnedRandTrial=zeros(12,numSamples);
tic    
for n=1:numSamples
    
   
    %make phase shuffled trials
    
    trialsClipped=stim.fallOrLowStateTraceCommonTimeBase( thisStartingIndex:end,:);
    phaseShuffledTrial=zeros(size(trialsClipped));
    
    for tr=1:size(stim.fallOrLowStateTraceCommonTimeBase,2);         
        phaseShuffledTrial(:,tr)=circshift(trialsClipped(:,tr),round(randomPhaseShifts(n,tr)*(thisEndingIndex-thisStartingIndex)));
        
        
    end
    
    
    %summed trial
    summedRandTrial=sum(fixnan(phaseShuffledTrial),2);
 
    
    %bin trial
    binnedRandTrial=zeros(1,72);
    k=1;
    for f=1:50:3600
       binnedRandTrial(k)=mean(summedRandTrial(f:f+49));
       k=k+1;
    end
    % stacked probability calculation

    iv=1:12:71;
    
    for k=1:6
        stackedBinnedRandTrial(:,n)=stackedBinnedRandTrial(:,n) + (binnedRandTrial(iv(k):(iv(k)+11)))'/13/6;
    end
end


summedUnshuffledTrial=sum(fixnan(trialsClipped),2);
binnedUnshuffledTrial=zeros(1,72);
k=1;
for f=1:50:3600
   binnedUnshuffledTrial(k)=mean(summedUnshuffledTrial(f:f+49)); 
   k=k+1;
end

stackedUnshuffledTrial=zeros(12,1);

for k=1:6
   stackedUnshuffledTrial=stackedUnshuffledTrial +binnedUnshuffledTrial(iv(k):(iv(k)+11))'/13/6;
end

    
toc
%% visualize phase shuffled sampling procedire
figure;
subplot(2,1,1);
plot(0.95*trialsClipped+repmat((1:13),size(trialsClipped,1),1));
hold on;
plot(mean(trialsClipped,2))
plot(24+(1:50:3600),(binnedUnshuffledTrial)/size(trialsClipped,2)-1,'r')
plot(24+(1:50:600),stackedUnshuffledTrial-6,'g')

subplot(2,1,2);
plot(0.95*phaseShuffledTrial+repmat((1:13),size(trialsClipped,1),1));
hold on;
plot(mean(phaseShuffledTrial,2))
plot(24+(1:50:3600),(binnedRandTrial)/size(trialsClipped,2)-1,'r')

plot(24+(1:50:600),stackedBinnedRandTrial(:,n)-6,'g')


%% pvalue
%{
figure;
nr=4;
subplot(nr,1,1);
rectangle('Position',[0 0 30 1],'FaceColor',color('lightgray'),'EdgeColor','none');
hold on;
plot(TVstacked,stim.stackedFallOrLowState,'.-');
plot(TVstacked,nostim.stackedFallOrLowState,'r.-');
plot(TVstacked,mean(stackedBinnedRandTrial,2),'g.-');
plot(TVstacked,stackedUnshuffledTrial,'c--');
ylim([0 1]);
xlim([0 stackSize]);
set(gca,'XTick',0:10:stackSize);
title('stacked fall or trough state prob');
ylabel('probability');
xlabel('time (s)');


baseLevel=mean(stackedBinnedRandTrial(:));

subplot(nr,1,2);
rectangle('Position',[0 -.5 30 1],'FaceColor',color('lightgray'),'EdgeColor','none');
hold on;
plot(TVstacked,stim.stackedFallOrLowState-baseLevel,'.-');
%plot(TVstacked,nostim.stackedFallOrLowState,'r.-');
plot(TVstacked,mean(stackedBinnedRandTrial,2)-baseLevel,'g.-');
ylim([-.5 .5]);
xlim([0 stackSize]);
set(gca,'XTick',0:10:stackSize);
title('stacked fall or trough state prob');
ylabel('probability');
xlabel('time (s)');


clear testStat1a;
acceptLevel1a=mean(abs(stackedUnshuffledTrial-baseLevel));
ctrlLevel1a=mean(abs(nostim.stackedFallOrLowState'-baseLevel));
testStat1a=mean(abs(stackedBinnedRandTrial-baseLevel),1);

pValue1a=sum(testStat1a>acceptLevel1a)/numSamples;
pValueCTRL1a=sum(testStat1a>ctrlLevel1a)/numSamples;
subplot(nr,1,3);
hist(testStat1a,240);
hold on;
vline(acceptLevel1a);
vline(ctrlLevel1a,'r');
intitle(['test: sum(abs(deltamean) p<' num2str(pValue1a) ', ctrl p<' num2str(pValueCTRL1a)]);


shifted=stackedUnshuffledTrial-baseLevel;
shiftedCTRL=nostim.stackedFallOrLowState'-baseLevel;
acceptLevel2=sum(diff(shifted(1:6)))-sum(diff(shifted(7:12)));
ctrlLevel2=sum(diff(shiftedCTRL(1:6)))-sum(diff(shiftedCTRL(7:12)));
clear testStat2;

for n=1:numSamples
    testStat2(n)=sum(diff(stackedBinnedRandTrial(1:6,n)))-sum(diff(stackedBinnedRandTrial(7:12,n)));
end

subplot(nr,1,4);
hist(testStat2,240);
hold on;
vline(acceptLevel2);
vline(ctrlLevel2,'r');
pValue2=sum(testStat2>acceptLevel2)/numSamples;
pValueCTRL2=sum(testStat2>ctrlLevel2)/numSamples;
intitle(['test: diff1-diff2  p<' num2str(pValue2) ', ctrl p<' num2str(pValueCTRL2) ]);


export_fig(['entrainmentSignificanceTesting.pdf']);

%}



% clear testStat1;
% acceptLevel1=sum(stackedUnshuffledTrial-baseLevel);
% ctrlLevel1=sum(nostim.stackedFallOrLowState' - baseLevel);
% testStat1=sum((stackedBinnedRandTrial-baseLevel),1);
% pValue1=sum(testStat1>acceptLevel1)/numSamples;
% pValueCTRL1=sum(testStat1>ctrlLevel1)/numSamples;
% subplot(nr,1,3);
% hist(testStat1,240);
% hold on;
% vline(acceptLevel1);
% %vline(ctrlLevel1,'r');
% intitle(['test: sum(deltamean) p<' num2str(pValue1) ', ctrl p<' num2str(pValueCTRL1)]);

