%Awba.m
%
%Annika
%

%date ran
%

foldernames={'/Users/nichols/Documents/Imaging/ZIM540_Let_O2_21.0_s_20131113_tetfd_10.45_W4 2'};
 
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
options.excludePlanes=8; 
 
for i=1:length(foldernames)
 
    wba(foldernames{i},options);
 
end