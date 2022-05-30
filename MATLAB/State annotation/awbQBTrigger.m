%% Trigger off falling asleep
clear all

Neurons = {'RIS', 'RMED','RMEV'};%,'RMEL','RMER','AVAL','AVAR','VB02'};

%Range = [1:360,720:1080]; %in sec, range where Qbout can end
Range = [1:1080]; %in sec, range where Qbout can end

priorLength = 120; %in sec, period prior to the trigger taken

%
intLength = 1000; % timepoints

FolderList = mywbGetDataFolders;
NumDataSets = length(FolderList);
MainDir = pwd;

tvi1num = 600; %time vector extrapolated
% tvi = 1:1000; %time vector extrapolated
%tvo =wbstruct.tv; %time vector original
%NeuronResponse.tv= (0:0.2:1079.8);

%Preallocate
for neuNum = 1:length(Neurons)
    NeuronTrig.(Neurons{neuNum}) = (nan(NumDataSets*10,tvi1num));
    counti.(Neurons{neuNum}) =1;
    count.(Neurons{neuNum}) =1;
end

for recNum = 1:NumDataSets %Folder loop
    tic
    cd(FolderList{recNum});
    wbload;
    
    %% load QuiescentState
    awbQuiLoad
    
    %% calculates quiescent and active range
    calculateQuiescentRange
    
    %% 
    numQB = length(QuBRunEnd);
    
    for QBnum = 1:numQB;
        for neuNum = 1:length(Neurons);
            if max((Range == round(QuBRunEnd(QBnum)/wbstruct.fps)));
                neuronTrace = wbgettrace(Neurons{neuNum});
                if ~isnan(sum(neuronTrace))
                    priorBRange =floor(QuBRunEnd(QBnum)-(priorLength*wbstruct.fps)):QuBRunEnd(QBnum);
                    if min(priorBRange) >=0 &&  max(priorBRange) <=1040 %was 1
                        tvi1 = linspace(min(priorBRange),max(priorBRange),tvi1num);
                        NeuronTrig.(Neurons{neuNum})(count.(Neurons{neuNum}),:) = interp1(priorBRange,neuronTrace(priorBRange),tvi1);%had to use spline as linear was giving nans, maybe as there were negative numbers
                        count.(Neurons{neuNum}) = count.(Neurons{neuNum})+1;
                        if QuBRunStart(QBnum) >= 40 && max(((Range) == round(QuBRunStart(QBnum)/wbstruct.fps))) == 1;
                            tvi = linspace(QuBRunStart(QBnum)-40,QuBRunEnd(QBnum)+40,600);
                            NeuronTrigIn.(Neurons{neuNum})(counti.(Neurons{neuNum}),:)=interp1((QuBRunStart(QBnum)-40):(QuBRunEnd(QBnum)+40),neuronTrace((QuBRunStart(QBnum)-40):(QuBRunEnd(QBnum)+40)),tvi);
                            counti.(Neurons{neuNum}) = counti.(Neurons{neuNum})+1;
                        end
                    end
                end
            end
        end
    end
    toc
    cd(MainDir)
end

%% Plotting

for neuNum = 1:length(Neurons);
    figure; imagesc((NeuronTrigIn.(Neurons{neuNum})(:,:)))
    title(Neurons{neuNum})
    
    figure; plot((NeuronTrigIn.(Neurons{neuNum})'),'k')
    hold on; plot(nanmean(NeuronTrigIn.(Neurons{neuNum})),'r', 'linewidth',5)
    title(Neurons{neuNum})
    ylim([0,1.5])
end
