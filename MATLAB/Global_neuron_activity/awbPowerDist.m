%%% awbPowerDist gets back an analysis (e.g. RMS) distribution of ranges,
%%% will do it for a specified range or Quiescent vs Active (run through annikaPhasePlot).

if ~exist('wbstruct','var');
    wbload;
end

options.extraExclusionList1 = {'BAGL','BAGR','AQR','URXL','URXR'}; 

y1=50;   %y axis on hist plots
x1=1.4;    %x axis
x2=1.2;   %x axis of log scale
xcentres1 = (0:0.03:1.4); %For binning and x axis of histograms.
xcentres1 = (0:0.06:1.4);

Analysis1 = @rms; %put in function e.g. @rms @mean @std

options.range1=1:(wbstruct.fps*1080);  % [1:100,200:400] % in frames

plotflag1 = 1; 

QuiesceBoutFlag1 = 1; % 0 is off and will calculate the analysis for the range specificed. 1 is on, will calculate range automatically from the QuiescentState.m

%% Need to implement
%options.fieldName={'derivs','traces'}; % bring in define field.   
%options.fieldName='deltaFOverF_bc';

%%
options.version.awbPowerDist = 'v4_20160126';

clearvars IncludedNeurons

%These parts checks if a variable has been defined by a batch version to make sure the values specificed in the batch verson are used.
if ~exist('Analysis','var');
    Analysis =Analysis1;
end

if ~exist('xcentres','var');
    xcentres =xcentres1;
end

if ~isfield(options,'extraExclusionList');
    options.extraExclusionList =options.extraExclusionList1;
end

if ~exist('plotflag','var');
    plotflag =plotflag1;
end

if ~isfield(options,'rangeSeconds'); %If there is the field specified by the batch version, it will correct for seconds.
    options.range = options.range1;
else
    options.range = round((options.rangeSeconds)*wbstruct.fps); %correcting from seconds to frames.
end

% if the first value in options.range is 0, must correct so that the first t-point is 1.
if options.range(1,1) ==0;
    options.range(1,1)= 1;
end

if ~exist('QuiesceBoutFlag','var'); 
    QuiesceBoutFlag =QuiesceBoutFlag1;
end
    
clear Analysis1 xcentres1 QuiesceBoutFlag1 plotflag1;
options = rmfield(options,'range1');
options = rmfield(options,'extraExclusionList1');

%%
%make array with the simple neuron numbers to exclude.
numExclude=length(options.extraExclusionList);
num4=1;
ExcludedNeurons=[];
for num3 = 1:numExclude;
    aaa = mywbFindNeuron(options.extraExclusionList{num3});
    if ~isempty(aaa);
    ExcludedNeurons(1,num4) = aaa;
    num4=num4+1;
    end
end
[~,NeuronN] =size(wbstruct.simple.deltaFOverF_bc); %Note: if running a dataset and dimensions don't match then check to see if the wbstruct.simple _bc and normal deltaFOverF dimensions are the same. Else you might need to run wbProcessTraces.
IncludedNeurons = 1:NeuronN;
IncludedNeurons(:,ExcludedNeurons) = [];
options.NeuronsIDs= wbstruct.simple.ID(1,IncludedNeurons);
clear NeuronN;
%make number string excluding the simple numbers of the neurons to exclude.

%%
if QuiesceBoutFlag == 0; %0 is off and will calculate the analysis for the range specificed.
        Traces = wbstruct.simple.deltaFOverF_bc((options.range),IncludedNeurons);
        RangeAnalysed = Analysis(Traces);
        NeuronNum = length(RangeAnalysed);
        dateRun = datestr(now);
        save (strcat(pwd,'/Quant/PowerDistributionsRange.mat'), 'RangeAnalysed','options','dateRun','NeuronNum','Analysis'); %WILL SAVE OVER
        
        %Putting data into histogram format so it can be averaged across datasets
        %fraction of neurons in each bin
        BinnedRangeAnalysed =(histc(RangeAnalysed,xcentres))/NeuronNum;
        if plotflag ==1; 
            figure;plot(xcentres,BinnedRangeAnalysed,'g');
        end
        %disp('quieseboutflag == 0 and therefore running on
        %options.range'); %Not necessary to run, used for checking.

else %1 is on, it will calculate range automatically from the QuiescentState.m
    %Checks if there is QuiescentState file and loads it.
        masterfolder = pwd;
        cd ([strcat(masterfolder,'/Quant')]);
        num2 = exist('QuiescentState.mat', 'file');
        if gt(1,num2);
            X=['No QuiescentState file in folder: ', wbstruct.trialname, ', please run awbQAstateClassifier or specify own range'];
            disp(X)
            return
        end
        load('QuiescentState.mat');
        cd (masterfolder);

    %calculates positions of runs, i.e. QUIESCENT bout run starts
    %and ends.
    WakeToQuB = ~[true;diff(QuiesceBout(:))~=1 ];
    QuBToWake = ~[true;diff(QuiesceBout(:))~=-1 ];

    QuBRunStart=find(WakeToQuB,'1');
    QuBRunEnd=find(QuBToWake,'1');

    if QuiesceBout(1,1)==1; % adds a run start at tv=1 if there is Quiescence there
        QuBRunStart(2:end+1)=QuBRunStart;
        QuBRunStart(1)=1;
    end

    if QuiesceBout(end,1)==1;  % adds a run end at tv=end if there is Quiescence there
        QuBRunEnd(length(QuBRunEnd)+1,1)=length(QuiesceBout);
    end

    QuRangebuild = char.empty;
    if ~isempty(QuBRunStart)
        if QuBRunStart(1)==0; %can't start at a 0.
            QuBRunStart(1)=1;
        end
    
        QuRangebuild = strcat(QuRangebuild, num2str(QuBRunStart(1)),':',num2str(QuBRunEnd(1)));

        for num1= 2:length(QuBRunStart);
            QuRangebuild = strcat(QuRangebuild,',', num2str(QuBRunStart(num1)),':',num2str(QuBRunEnd(num1)));
        end
    else
        QuRangebuild = 0; %gets around if there is no quiescence
    end
    options.rangeQ=strcat('[', QuRangebuild, ']');
    
    %running Analysis calculation
    QuTraces = wbstruct.simple.deltaFOverF_bc([str2num(options.rangeQ)],IncludedNeurons);
    QuiesceAnalysed = Analysis(QuTraces);

    %%
    %calculates positions of runs, i.e. ACTIVE bout run starts and ends.
    ActBRunStart=find(QuBToWake,'1');
    ActBRunEnd=find(WakeToQuB,'1');

        if QuiesceBout(1,1)==0; % adds a run start at tv=1 if it is ACTIVE there
            ActBRunStart(2:end+1)=ActBRunStart;
            ActBRunStart(1)=1;
            ActBRunStart=ActBRunStart';
        end

        if QuiesceBout(end,1)==0;  % adds a run end at tv=end if there is ACTIVITY there
            ActBRunEnd(length(ActBRunEnd)+1,1)=length(QuiesceBout);
        end

    ActRangebuild = char.empty;

    if ActBRunStart(1)==0; %can't start at a 0.
    ActBRunStart(1)=1;
    end

    ActRangebuild = strcat(ActRangebuild, num2str(ActBRunStart(1)),':',num2str(ActBRunEnd(1)));

    for num1= 2:length(ActBRunStart);
        ActRangebuild = strcat(ActRangebuild,',', num2str(ActBRunStart(num1)),':',num2str(ActBRunEnd(num1)));
    end

    options.rangeA=strcat('[', ActRangebuild, ']');

    %running Analysis calculation
    ActTraces = wbstruct.simple.deltaFOverF_bc([str2num(options.rangeA)],IncludedNeurons);
    ActiveAnalysed = Analysis(ActTraces);

    NeuronNum = length(ActiveAnalysed);
    dateRun = datestr(now);
    save ([strcat(pwd,'/Quant/PowerDistributions.mat')], 'QuiesceAnalysed','ActiveAnalysed', 'options','dateRun','NeuronNum','Analysis'); %ACTIVE bout values
    
    %% Plotting and hist data for averaging
    %Putting data into histogram format so it can be averaged across datasets
    %fraction of neurons in each bin
    BinnedQuiesceAnalysed =(histc(QuiesceAnalysed,xcentres))/NeuronNum;
    BinnedActiveAnalysed =(histc(ActiveAnalysed,xcentres))/NeuronNum;
    
    if plotflag ==1; 
        figure;hist(QuiesceAnalysed,xcentres);
        hold on;
            xlim([0 x1]);
            ylim([0 y1]);
            set(gca,'FontSize',16)
        %     ylabel('DeltaF/F0', 'FontSize',16);
            set(gcf,'position',[1,2,400,400]);
            
        figure;hist(ActiveAnalysed,xcentres);
        hold on;
            xlim([0 x1]);
            ylim([0 y1]);
            set(gca,'FontSize',16)
        %    xlabel('RMS', 'FontSize',16);
        %    ylabel('DeltaF/F0', 'FontSize',16);
            set(gcf,'position',[1,2,400,400]);

        figure;plot(xcentres,BinnedQuiesceAnalysed,'b',xcentres,BinnedActiveAnalysed,'r');
        %figure;semilogx(xcentres,BinnedQuiesceAnalysed,xcentres,BinnedActiveAnalysed,'r');
    end

        
        clearvars -except options QuRangebuild ActRangebuild ActiveAnalysed QuiesceAnalysed...
            BinnedQuiesceAnalysed BinnedActiveAnalysed NeuronNum xcentres ResultsStructFilename...
            condition MainDir FolderList NumDataSets PowerDistributions wbstruct Analysis QuiesceBoutFlag...
            plotflag IncludedNeurons
end


