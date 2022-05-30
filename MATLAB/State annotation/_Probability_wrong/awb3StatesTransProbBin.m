%% awb3StateTransProbBinned

% clear all
%
awb3States

binSize = 60; %in seconds

binSizeF = binSize*5;
binNumber = 5400/binSizeF;


for recNum = 1:NumDataSets
    startFrame = 1;
    for binNum = 1:binNumber
        clearvars trans;
        endFrame = floor(binNum*binSizeF);
        if endFrame >= 5400
            endFrame = 5399;
        end
        x = [[0,1,2,0],iThreeStates(recNum,startFrame:endFrame)];
        startFrame = endFrame+1;
        %had to add the the 0,1,2,0 dummy at the start so all transitions would
        %be looked at.
    
        % make transition matrix
        transDummy = full(sparse(x(1:end-1)+1, x(2:end)+1, 1));
    
        % take away dummy transitions
        if x(5) == 0
            dummyBase = [1,1,0;0,0,1;1,0,0];
        elseif x(5) == 1
            dummyBase = [0,2,0;0,0,1;1,0,0];
        elseif x(5) == 2
            dummyBase = [0,1,1;0,0,1;1,0,0];
        end
        trans = transDummy - dummyBase;
        TransProbData{recNum,binNum} = bsxfun(@rdivide, trans, sum(trans,2));
    end
end

% Getting out data across recordings for Prism.
clearvars   FRprob FQprob
for recNum = 1:NumDataSets
    for binNum =1:binNumber
        FRprob(recNum,binNum) = TransProbData{recNum,binNum}(2,1,:);
        FQprob(recNum,binNum) = TransProbData{recNum,binNum}(2,3,:);
        FFprob(recNum,binNum) = TransProbData{recNum,binNum}(2,2,:);
        
        RFprob(recNum,binNum) = TransProbData{recNum,binNum}(1,2,:);
        RQprob(recNum,binNum) = TransProbData{recNum,binNum}(1,3,:);
        RRprob(recNum,binNum) = TransProbData{recNum,binNum}(1,1,:);

        
        QFprob(recNum,binNum) = TransProbData{recNum,binNum}(3,1,:);
        QRprob(recNum,binNum) = TransProbData{recNum,binNum}(3,2,:);
        QQprob(recNum,binNum) = TransProbData{recNum,binNum}(3,3,:);


    end
end

%replace NaNs with zeros
FRprob(isnan(FRprob)) = 0;
FQprob(isnan(FQprob)) = 0;
FFprob(isnan(FFprob)) = 0;
RRprob(isnan(RRprob)) = 0;

%Plot

figure; plot(mean(FQprob))
hold on; plot(mean(FRprob),'r')

figure; plot(mean(FFprob))
hold on; plot(mean(RRprob),'r')

%% State probability
[r,c] = size(iThreeStates);
Fprob = zeros(r,c);
Fprob(iThreeStates == 1) = 1;

[r,c] = size(iThreeStates);
Rprob = zeros(r,c);
Rprob(iThreeStates == 0) = 1;

[r,c] = size(iThreeStates);
Qprob = zeros(r,c);
Qprob(iThreeStates == 2) = 1;


figure; plot(mean(reshape(mean(Fprob),300,18)),'g','linewidth',2);
hold on; plot(mean(reshape(mean(Rprob),300,18)),'r','linewidth',2)
hold on; plot(mean(reshape(mean(Qprob),300,18)),'b','linewidth',2)
ylim([0,1])
title('Probability of being in that state')


% normalises by the probability of being in that state
figure; plot(mean(FQprob)./mean(reshape(mean(Fprob),300,18)))
hold on; plot(mean(FRprob)./mean(reshape(mean(Fprob),300,18)),'r')
title('normalised by the probability of being in that state')

