%-- frameinterval used for creating background image, converts to RGB for
%cluster tracking
%frameinterval = 10;
frameinterval = 100;

%use max instead of average
BackgroundProduction_V5(frameinterval);

ConvertBackgroundGray2RGB

ticks = 1000;
xmax = 5400;
PlotFrameRate = 50;
MinWormArea = 20; 
MaxWormArea = 540;

BatchWormTrackerTE_20130904_hist(0,0,0,ticks,xmax,0,0,PlotFrameRate,MinWormArea,MaxWormArea)
close all