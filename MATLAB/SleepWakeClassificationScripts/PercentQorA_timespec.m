%%% Quiescent vs Active percentages

wbload;
load([strcat(pwd,'/Quant/QuiescentState.mat')]);

beforeRange =[1:(360*wbstruct.fps)];
stimRange   =[(round(360*wbstruct.fps):(420*wbstruct.fps))]; %%%CHECK!!!!
afterRange  =[(round(720*wbstruct.fps):(length(QuiesceBout)))];


before = sum(QuiesceBout(beforeRange))/length(QuiesceBout(beforeRange));
stim   = sum(QuiesceBout(stimRange))/length(QuiesceBout(stimRange));
after  = sum(QuiesceBout(afterRange))/length(QuiesceBout(afterRange));

PercentQ = [before stim after];

%%
figure;bar(PercentQ)
ylim([0 1]);


%% Quick inverse and collection of Percent Quiescent

num = length(PercentQ.stim);

All(1:num,1) = abs((PercentQ.before(1:num,1)-1));
All(1:num,2) = abs((PercentQ.stim(1:num,1)-1));
All(1:num,3) = abs((PercentQuiescent.after(1:num,1)-1));


