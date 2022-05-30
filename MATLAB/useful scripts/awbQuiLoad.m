%awbQuiLoad
%load QuiesceState
masterfolder = pwd;
cd (strcat(masterfolder,'/Quant'));
num2 = exist('QuiescentState.mat', 'file');
if gt(1,num2);
    X=['No QuiescentState file in folder: ', wbstruct.trialname, ', please run awbQAstateClassifier or specify own range'];
    disp(X)
    return
end
load('QuiescentState.mat');
cd (masterfolder);