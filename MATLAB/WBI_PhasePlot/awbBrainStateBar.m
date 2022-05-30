clear all 

wbload;
load(strcat(pwd,'/Quant/QuiescentState.mat'));

ReversalRISE=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
ReversalHIGH=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;
ReversalFALL=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==4;

paleblue = [0.8  0.93  1]; %255
blue = [0 0 204]/255; %255

forestgreen = [0 153 0]/255;
burntorange = [225 115 0]/255;
burntorange2 = [255 180 0]/255;
yellow = [255 240 102]/255;
purple = [76 0 103]/255;
red = [200 20 0]/255;
turquoise = [0 153 153]/255;

recessmap = [turquoise;blue;red;burntorange2;purple];

colorm = double(2*ReversalRISE+QuiesceBout);
colorm(find(ReversalHIGH),1)=3;
colorm(find(ReversalFALL)) = 4;

figure; imagesc(colorm');
colormap(recessmap)

print(gcf,'brainstateColorbar.ai','-depsc')
