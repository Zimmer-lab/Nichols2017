function [fulltraces,transitionTimes,transitionFallTimes,reversals,meanalignrises,meanalignfalls,singlealigns,alignmenttv] = HKwbtriggeralign(transitionTimes,transitionFallTimes,varargin)
%Trigger-align to AVA on and AVA off (or anything else in place TransitionTimes and TransitionFallTimes, in seconds, 
%as long as you use '' rather than a number), all neurons found with the name or number
%listed in 'neuronnames', across all datasets loaded as described here:
%First load 'wbStateStatsStruct', then load a dataset(s) as a structure 
%named with the folder tag name as it is in the trialName field 
%(number corresponding to transitionTimes cell).
%

plotfulltraces = 1; %up to 5 at the moment - add a new color for more
plotsomeframes = 1; %with 4 varargins, and frames as the 4th, plot any set of frames in the first varargin if this = 1; have to use with 4 varargins
plotaligntotimes = 0;
plotalignments = 0;
plotsingles = 0;
timeoneachside = 30; %in s

%if nothing is loaded, sitting in folder &fixed (or analogous), first load
%wbStateStatesStruct, then scroll through all TS folders loading wbstructs with 
%proper names (or just write in one TS foldername):
if nargin > 2
    dataset = varargin{1};
    if isnumeric(varargin{2})
        datasetno = varargin{2};
    end  
    if nargin == 4
        moreframestoplot = varargin{2};
    end
    if nargin > 4
        if strcmp(varargin{3},'conv2time')
            transitionTimes = transitionTimes/dataset.fps;
            transitionFallTimes = transitionFallTimes/dataset.fps;
        elseif strcmp(varargin{3},'aligntopeaks')
            neuronnames = { 'SMDVR' };
            findneurons;
            smdv = dataset.deltaFOverF_bc(:,neuroninds(1));
            %find wb SMDV peaks
            [peaks] = peakdet(smdv,0.3);
            figure; plot(smdv);
            hold on;
            plot(peaks(:,1),peaks(:,2),'r*');
            transitionTimes = peaks(:,1)/dataset.fps;
            transitionFallTimes = peaks(:,1)/dataset.fps;
        end
    end
end

%these neurons will be searched for across all TS variables
neuronnames = {
    %'RIBL'
    %'AVAR'
    %'AIBR'
    %'RMED'
    'AVFL'
    %'AVFR'
    };

%convert transitiontimes from seconds to frames, and timeoneachside from seconds to frames
if ~isempty(transitionTimes)
    if isnumeric(varargin{2})
        transitionTimesplot = (transitionTimes{datasetno});
        transitionFallTimesplot = (transitionFallTimes{datasetno});
        transitionTimes = (transitionTimes{datasetno}*dataset.fps)+1;
        transitionFallTimes = (transitionFallTimes{datasetno}*dataset.fps)+1;
        if length(transitionTimes) == length(transitionFallTimes)
            reversals = [transitionTimes transitionFallTimes];
        else
            if length(transitionTimes) < length(transitionFallTimes)
                transitionTimes = [1;transitionTimes];
            else
                transitionFallTimes = [transitionFallTimes;size(dataset.deltaFOverF0_bc,1)];
            end
            reversals = [transitionTimes transitionFallTimes];
        end
    else
        transitionTimesplot = transitionTimes;
        transitionFallTimesplot = transitionFallTimes;
        transitionTimes = (transitionTimes*dataset.fps)+1;
        transitionFallTimes = (transitionFallTimes*dataset.fps)+1;
    end
    framesoneachside = timeoneachside*4; %assuming fps is never greater than 4, then this is the frame numbers used for alignment, converted back to s for plotting
    alignmenttv = [flipud(dataset.tv(2:framesoneachside+1)*-1) ; dataset.tv(1:framesoneachside+1)];
end

findneurons;
fulltraces = [];
for thisneuron = 1:size(neuroninds,1)
    fulltraces = [fulltraces dataset.deltaFOverF_bc(:,neuroninds(thisneuron))];
end
if ~isempty(transitionTimes)
    meanalignrises = [];
    meanalignfalls = [];
    for thisneuron = 1:size(neuroninds,1)
        [nmeanrise nsinglerises] = alignthese(fulltraces(:,thisneuron),transitionTimes,framesoneachside,1);
        [nmeanfall nsinglefalls] = alignthese(fulltraces(:,thisneuron),transitionFallTimes,framesoneachside,1);
        meanalignrises = [meanalignrises ; nmeanrise]; singlealigns(thisneuron).rises = nsinglerises;
        meanalignfalls = [meanalignfalls ; nmeanfall]; singlealigns(thisneuron).falls = nsinglefalls;
    end
end

if plotfulltraces
    color = {'k' 'r' 'b' 'g' 'm','c'};
    figure;
    for thisneuron = 1:size(neuroninds,1)
        plot(dataset.tv,dataset.deltaFOverF_bc(:,neuroninds(thisneuron)),color{thisneuron})
        hold on;
    end
    legend(neuronnames{1:end});
    if plotaligntotimes
        hold on;
        for thisrise = 1:size(transitionTimesplot,1)
            line([transitionTimesplot(thisrise,1) transitionTimesplot(thisrise,1)],[0 5],'Color','g')
            hold on
        end    
        hold on;
        for thisrise = 1:size(transitionFallTimesplot,1)
            line([transitionFallTimesplot(thisrise,1) transitionFallTimesplot(thisrise,1)],[0 5],'Color','c')
            hold on
        end
    end
    if plotsomeframes
        hold on
        for thisframe = 1:length(moreframestoplot)
            line([moreframestoplot(thisframe,1)/dataset.fps moreframestoplot(thisframe,1)/dataset.fps],[0 4],'Color','k')
            hold on
        end
    end
    hold off;
end

if plotalignments
    for thisneuron = 1:size(neuronnames,1)
        figure;plot(alignmenttv,meanalignrises(thisneuron,:));
        title([neuronnames(thisneuron) ' rise'])
        xlim([timeoneachside*-1 timeoneachside])
        xlabel('Time (seconds)','FontSize',20);
        ylabel('dF/F0','FontSize',20);
        set(gca,'FontSize',20);
        figure;plot(alignmenttv,meanalignfalls(thisneuron,:));
        title([neuronnames(thisneuron) ' fall'])
        xlim([timeoneachside*-1 timeoneachside])
        xlabel('Time (seconds)','FontSize',20);
        ylabel('dF/F0','FontSize',20);
        set(gca,'FontSize',20);
    end
end

if plotsingles
    for thisneuron = 1:size(neuronnames,1)
        figure;
        for thisrise = 1:size(singlealigns(thisneuron).rises,1)
            plot(alignmenttv,singlealigns(thisneuron).rises(thisrise,:));
            hold on;
        end
        title([neuronnames(thisneuron) ' rise'])
        xlim([timeoneachside*-1 timeoneachside])
        xlabel('Time (seconds)','FontSize',20);
        ylabel('dF/F0','FontSize',20);
        set(gca,'FontSize',20);
        figure;
        for thisfall = 1:size(singlealigns(thisneuron).falls,1)
            plot(alignmenttv,singlealigns(thisneuron).falls(thisfall,:));
            hold on;
        end
        title([neuronnames(thisneuron) ' fall'])
        xlim([timeoneachside*-1 timeoneachside])
        xlabel('Time (seconds)','FontSize',20);
        ylabel('dF/F0','FontSize',20);
        set(gca,'FontSize',20);
    end
end

%end main

%%
%subs

%find a neuron's index, named or numbered
function findneurons
    neuronsmissing = [];
    neuroninds = [];
    for thisneuron = 1:size(neuronnames,1)
        found = 0;
        ind = 0;
        if isstr(neuronnames{thisneuron})
            for thiscell = 1:size(dataset.ID,2)
                trythiscell = dataset.ID{thiscell};
                if size(trythiscell,2) > 1
                    trythiscell = trythiscell(1);
                end
                found = strcmp(trythiscell,neuronnames{thisneuron});
                if found
                    ind = thiscell;
                end
                found = 0;
            end
            if ind > 0
                neuroninds = [neuroninds ; ind];
                %            figure;plot(dataset.tv,dataset.deltaFOverF_bc(:,ind))
            else
                neuronsmissing = [neuronsmissing ; thisneuron];
            end
        else
            found = 1;
            neuroninds = [neuroninds ; neuronnames{thisneuron}];
        end
    end
    neuronnames(neuronsmissing)=[];
end





end

%end subs

%%
%related scripts

% % check that AVAL onsets and offsets are correct
% % find AVAL
% % make sure to reset all names in 5 places, and datasetnum: TS20140905c 
% datasetnum=3;
% found = 0;
% AVAind = 0;
% transitionTimesfix = (transitionTimes{datasetnum}*TS20140905c.fps)+1;
% transitionFallTimesfix = (transitionFallTimes{datasetnum}*TS20140905c.fps)+1;
% for thiscell = 1:size(TS20140715e.ID,2)
%     found = strcmp(TS20140715e.ID{thiscell},'AVAL');
%     if found
%         AVAind = thiscell;
%     end
%     found = 0;
% end
% 
% figure;plot(TS20140905c.deltaFOverF_bc(:,AVAind))
% hold on;
% for thistrans = 1:size(transitionTimes{datasetnum},1)
%     plot(transitionTimesfix(thistrans,1),-1:0.01:1,'r-')
%     hold on;
% end
% for thistrans = 1:size(transitionFallTimes{datasetnum},1)
%     plot(transitionFallTimesfix(thistrans,1),-1:0.01:1,'k-')
%     hold on;
% end
% hold off;

