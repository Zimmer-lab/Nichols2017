function [evalTimeSeriesTV,evalTimeSeries]=wbPlotEvalTimeSeries(wbstruct,options)

%if nargin<1 || isempty(wbstruct)
    %wbstruct=wbload([],false);
%end

if nargin<2
    options=[];
end

if ~isfield(options,'neuronSubset');
    options.neuronSubset=[];
end

if ~isfield(options,'evalType')
    options.evalType='rms';
end

if ~isfield(options,'evalParams')
    options.evalParams=[];
end

if ~isfield(options,'timeWindowsSize')
    options.timeWindowSize=100;  %in frames
end

if ~isfield(options,'slidingStepSize')
    options.slidingStepSize=options.timeWindowSize;   %use 1 for max sampling
end

if ~isfield(options,'saveDir')
    if exist([pwd '/Quant'],'dir')==7
        options.saveDir=([pwd '/Quant']);
    else
        options.saveDir=pwd;
    end
end

if ~isfield(options,'saveFlag')
    options.saveFlag=true;
end


flagstr=['-tw' num2str(options.timeWindowSize)];

if options.slidingStepSize~=options.timeWindowSize
    flagstr=[flagstr '-ss' num2str(options.slidingStepSize)];
end

%sliding window calculations are unoptimized.

evalTimeSeriesTV=1:options.slidingStepSize:(length(evalTV)- options.timeWindowSize);

for tw=1:length(evalTimeSeriesTV)

    evalOptions.range=evalTimeSeriesTV(tw) + [0 options.timeWindowSize];
    %need to intrp1 what the evalTimeSeries is calculating to make sure
    %they're on the same x axis
   
    evalTimeSeries(tw,:)=wbEvalTraces(wbstruct,options.evalType,options.evalParams,options.neuronSubset,evalOptions);

end
      


figure('Position',[200 200 800 600]);
subplot(2,1,1);
for i=1:size(evalTimeSeries,2)
    plot((evalTimeSeriesTV/wbstruct.fps),evalTimeSeries);
end
%title('individual neurons');
ylabel(options.evalType);
xlabel('time (s)');
ylim([0 1.4]);
xlim([0 1080]);
box off;

subplot(2,1,2);
plot((evalTimeSeriesTV/wbstruct.fps),mean(evalTimeSeries,2));
title('mean');
ylabel(options.evalType);
xlabel('time (s)');
xlim([0 1080]);
box off;

save ('/Users/nichols/Documents/Imaging/MasterFolder/evalTimeSeries', 'evalTimeSeries');

mtit([options.evalType ' timeseries for ' wbstruct.displayname '  ' flagstr]);

%export_fig([options.saveDir '/TimeseriesPlot-' options.evalType  '-' wbMakeShortTrialname(wbstruct.trialname) flagstr '.pdf'],'-transparent');


