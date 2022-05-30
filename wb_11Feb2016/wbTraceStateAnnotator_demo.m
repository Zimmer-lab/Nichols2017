%wbTraceStateAnnotator_demo

cd('/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AIBWorms');
load('aibworms.mat');
figure;

for n=1:length(allimgingworms);
    traces(:,n)=allimgingworms(n).deltaRoverR0;
    reftraces(:,n)=allimgingworms(n).fwdspeed;
end

for n=1:length(allimgingworms);
    subtightplot(length(allimgingworms),1,n);
    plot(normalize(traces(:,n)));

    hold on;
    plot(normalize(reftraces(:,n)),'r');
end

clear options;
options.dt=1/30;
options.pairedRefTraces=normalize(reftraces);
wbTraceStateAnnotator(traces,options);
