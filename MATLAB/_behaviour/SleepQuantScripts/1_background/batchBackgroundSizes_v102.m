%-- frameinterval used for creating background image, converts to RGB for
%cluster tracking
frameinterval = 10;

BackgroundProduction_V4(frameinterval);

ConvertBackgroundGray2RGB

ticks = 1000;
xmax = 5400;
PlotFrameRate = 50;
MinWormArea = 20; 
MaxWormArea = 140;
MaxWormArea = 250;

BatchWormTrackerTE_20130904_hist(0,0,0,ticks,xmax,0,0,PlotFrameRate,MinWormArea,MaxWormArea)
close all