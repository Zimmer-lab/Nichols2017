 %Awba.m
%
%Annika
%

%201403014
%

foldernames={'/Volumes/Annika Nichols/Imaging/_Imaging_data/AQ1854-WB1-3_Prelet_18m_O2_21.0_20131206_44um_TF_15.35_W1_'};
 
options.numPixels=50;
options.numPixelsBonded=100;
options.thresholdMargin=500;
options.Rmax=7;
options.sliceWidthMax=2;
options.blobSafteyMargin=0.75;
options.globalMovieFlag=0;
options.quantFlag=1;
options.blobDetectFlag=1;
options.maxPlotWidth=3000;
options.excludePlanes=9; 
 
for i=1:length(foldernames)
 
    wba(foldernames{i},options);
 
end