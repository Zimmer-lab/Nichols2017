function wbcompilation=wbdatacompile(wbstructOrDataFolderNameCellArray,options)
%function wbdatacompile(wbstruct,options)
%
%Saul Kato
%compile traces from one or more wbstructs
%resample all traces to common fps
%make trial averages
%
%2013113

if exist('options','var') && (iscell(options) || ischar(options))  %if options is a string or cell rather than a struct, assume it is neuron names
    options_temp=options;
    clear options;
    options.neuronName=options_temp;
end


if nargin<2 || ~isfield(options,'neuronName')
    options.neuronName=[];
end

if nargin<2 || ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF';
end

if nargin<2 || ~isfield(options,'saveDir')
    options.saveDir=pwd;
end

if nargin<2 || ~isfield(options,'saveFlag')
    options.saveFlag=1;
end

if nargin<2 || ~isfield(options,'range')  %range in seconds
    options.range=0;
end

if nargin<2 || ~isfield(options,'fps_resampled')
    options.fps_resampled=10;
end

if nargin<2 || ~isfield(options,'smoothing')
    options.smoothing=1;
end

if nargin<1 || isempty(wbstructOrDataFolderNameCellArray)
    [wbstructOrDataFolderNameCellArray,wbstructfilename]=wbload(wbstructOrDataFolderNameCellArray,false);
    if isempty(wbstructOrDataFolderNameCellArray)
        disp('quitting.');
        return;
    end
end
    
% if ~isstruct(wbstruct) && ~iscell(wbstruct)  %if wbstruct is just traces
%     disp('combining raw traces');
%     traces=wbstruct;
%     clear wbstruct;
%     wbstruct{1}.ref=traces;
%     options.fieldName='ref';
%     wbstruct{1}.trialname='ref';
%     wbstruct{1}.displayname='ref';
%     wbstruct{1}.fps=5;
%     wbstruct{1}.tv=mtv(wbstruct{1}.ref(:,1),1/wbstruct{1}.fps);
    
if iscell(wbstructOrDataFolderNameCellArray)  %cell array input
       
    if ischar(wbstructOrDataFolderNameCellArray{1}) %cell array of filenames
        
        disp('combining multiple datafolders.')
        for i=1:length(wbstructOrDataFolderNameCellArray)
            wbstruct{i}=wbload(wbstructOrDataFolderNameCellArray{i},false);
        end
    else %cell array of wbstruct
        wbstruct=wbstructOrDataFolderNameCellArray;
    end
    
else
    wbstruct{1}=wbstructOrDataFolderNameCellArray;
end

%wbstructOrDataFolderNameCellArray has now been converted to a 
%cell array named wbstruct


if ~isfield(options,'subsets')
    if ~isempty(options.neuronName)

        %build subset list from neuronNames
        for i=1:length(wbstruct)

                if ischar(options.neuronName)
                    
                    [~,neuronNumber ] = wbgettrace(options.neuronName,wbstruct{i});
                    if isnan(neuronNumber)
                        disp('quitting.');
                        return;
                    else
                        options.subsets{i}=neuronNumber;
                    end

                elseif iscell(options.neuronName)
                    
                    options.subsets{i}=[];
                    options.subsetNames{i}=[];
                    for j=1:length(options.neuronName)
                        
                        [~,neuronNumber] = wbgettrace(options.neuronName{j},wbstruct{i});
                        if ~isnan(neuronNumber)
                            options.subsets{i}=[options.subsets{i} neuronNumber];
                            options.subsetNames{i}{end+1}=options.neuronName{j};
                        end  
                    
                    end
                    
                end
           

        end


    else

        disp('no options.subsets specified. will use ALL neurons from all trials.');
        for i=1:length(wbstruct)
            options.subsets{i}=1:size(wbstruct{i}.f_parents,2);  %ALL neurons
        end    

    end

end



if nargin<2 || ~isfield(options,'trialcolors')
    for i=1:length(wbstruct)
        options.trialcolors{i}=color(i,1+length(wbstruct));
    end
end


% if nargin<2 || ~isfield(options,'names')
%     for i=1:length(wbstruct)
%         options.names{i}=repcell({''},size(wbstruct{i}.f_parents,2));
%     end
% end

for i=1:length(wbstruct)
    TeXColor{i}=['\color[rgb]{' num2str(options.trialcolors{i}) '}'];
end

neurons_allsubsets=[];
neurons_allsubsets_trial=[];
neurons_allsubsets_color=[];
neurons_allsubsets_name=[];
neurons_allsubsets_trialname={};
for i=1:length(wbstruct)
    tracesfortrial{i}=getfield(wbstruct{i},options.fieldName);
    neurons_allsubsets=[neurons_allsubsets options.subsets{i}];
    neurons_allsubsets_trial=[neurons_allsubsets_trial i*ones(1,length(options.subsets{i}))];
    neurons_allsubsets_color=[neurons_allsubsets_color; repmat(options.trialcolors{i},length(options.subsets{i}),1)];
    neurons_allsubsets_name=[neurons_allsubsets_name options.subsetNames{i}];
    for j=1:length(options.subsets{i})
        neurons_allsubsets_trialname{end+1}= wbstruct{i}.trialname;
    end
    
    trialendtime(i)=wbstruct{i}.tv(end);
    trialstarttime(i)=wbstruct{i}.tv(1);
end

neurons_allsubsets_name


%nn=size(traces,2);
nn=length(neurons_allsubsets);

if nargin<2 || ~isfield(options,'sortOrder')
    for i=1:length(wbstruct)
        options.sortOrder{i}=1:size(wbstruct{i}.f_parents,2);
    end
end

if nargin<2 || ~isfield(options,'sortOrderName')
    options.sortOrderName='unsorted';
end

if options.range>0  
    rngvec=[options.range(1) options.range(2)];
    rngstr=['[' num2str(options.range(1)) 's-' num2str(options.range(2)) 's]'];
else
    rngvec=[min(trialstarttime) max(trialendtime)];
    rngstr='';
end

tv_resampled=(rngvec(1):1/options.fps_resampled:rngvec(2))';

traces_resampled=zeros(length(tv_resampled),length(neurons_allsubsets));

for n=1:size(neurons_allsubsets,2)    
    
    thistrial=neurons_allsubsets_trial(n);


    
    tvs{n}=wbstruct{thistrial}.tv;
    traces{n}=tracesfortrial{thistrial}(:,options.sortOrder{thistrial}(neurons_allsubsets(n)));
    
    traces_resampled(:,n)=interp1(tvs{n},traces{n},tv_resampled,'linear',NaN);
end   
    
%plot stimulus
if isfield(wbstruct{1},'stim') && ~isempty(wbstruct{1}.stim)
    for thisswitch=1:length(wbstruct{1}.stim.ch(1).switchtimes)
       numconclevels=length(wbstruct{1}.stim.ch(1).conc);
       thisconcval=wbstruct{1}.stim.ch(1).conc(1+mod(wbstruct{1}.stim.ch(1).initialstate+thisswitch-1, numconclevels));
    end
end

wbcompilation.tv=tvs;
wbcompilation.traces=traces;
wbcompilation.fps_resampled=options.fps_resampled;
wbcompilation.traces_resampled=traces_resampled;
wbcompilation.tv_resampled=tv_resampled;
wbcompilation.neuronNames=neurons_allsubsets_name;
wbcompilation.trials=neurons_allsubsets_trialname;
wbcompilation.meantrace=nanmean(traces_resampled,2);

    

if (options.saveFlag) 
    save(['wbcompilation-' datestr(now) '.mat'],'wbcompilation');   
end