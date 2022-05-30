function wbComputeClusterStats


cSf=load('Quant/wbClusterFallStruct.mat');
cSr=load('Quant/wbClusterRiseStruct.mat');

options.altBootstrapInputValues=[];
options.altBootstrapDistanceMeasure=[];
options.altBootstrapNan=[];
options.bootstrapFlag=true;
options.bootstrapNumIterations=1000000;
options.bootstrapSequentialDrawFlag=false;
tic
StatsRise=wbClusterBootstrap(cSr,options);
StatsFall=wbClusterBootstrap(cSf,options);
toc


ClusterStats.StatsRise=StatsRise;
ClusterStats.StatsFall=StatsFall;
save('ClusterStats.mat','-struct','ClusterStats') 

end
