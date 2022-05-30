%% Quiescent vs Active percentages
%For a dataset you can calculate the fraction quiescent (PercentQ) or
%fraction active (FractionA) for the specified time points.

wbload;
load([strcat(pwd,'/Quant/QuiescentState.mat')]);

%Specified range
beforeRange =[(round(1*wbstruct.fps):(360*wbstruct.fps))];
stimRange   =[(round(360*wbstruct.fps):(720*wbstruct.fps))]; %%%CHECK!!!!
afterRange  =[(round(720*wbstruct.fps):(1080*wbstruct.fps))];


before = sum(QuiesceBout(beforeRange))/length(QuiesceBout(beforeRange));
stim   = sum(QuiesceBout(stimRange))/length(QuiesceBout(stimRange));
after  = sum(QuiesceBout(afterRange))/length(QuiesceBout(afterRange));

PercentQ = [before stim after];

%% Quick inverse and collection of Percent Quiescent

FractionA(1,1:3) = abs((PercentQ(1,1:3)-1)); % gives you Fraction active

%%
figure;bar(FractionA)
ylim([0 1]);


