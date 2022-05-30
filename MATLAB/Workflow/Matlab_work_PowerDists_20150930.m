%xcentres = (0:0.03:1.4); %For binning and x axis of histograms.
xcentres = (0:0.06:1.4); %For binning and x axis of histograms.


cumsum1= cumsum(mean(PowerDistributions.BinnedQuiesceAnalysed_npr1Let));
cumsum2= cumsum(mean(PowerDistributions.BinnedActiveAnalysed_npr1Let));

figure;plot(xcentres,cumsum1,'b',xcentres,cumsum2,'r')

figure;plot(xcentres,mean(PowerDistributions.BinnedQuiesceAnalysed_npr1Let),'b',xcentres,mean(PowerDistributions.BinnedActiveAnalysed_npr1Let),'r')
hold on;
%mnRange1ALL2 = mean(NeuronResponse.(NameO4),2);

mnRange1ALL= (PowerDistributions.BinnedQuiesceAnalysed_npr1Let,2);
strRange1ALL = std(PowerDistributions.BinnedQuiesceAnalysed_npr1Let,0,2)/sqrt(9);

jbfill(xcentres,mnRange1ALL+strRange1ALL,mnRange1ALL-strRange1ALL,grey,grey,0,0.3);
    

    