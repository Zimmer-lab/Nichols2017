
NewAnalysisTag = 0; %have on one when starting a new analysis.

%Put in neuron numbers of the two neurons you want to cross correlate

N1=46;
N2=93;

ResultsStructFilename = 'AVAVB2.mat';

MasterFolder = '/Users/nichols/Documents/Imaging/MasterFolder';

CurrentDirectory = pwd;

if ~NewAnalysisTag

cd(MasterFolder);

load(ResultsStructFilename);

cd(CurrentDirectory);

n = length(ResultsStruct);

n=n+1;

else
    
    ResultsStruct = struct;
    
    n=1;

end











Opts.fpsInter = 6;

tvInter = ((0:6479)/Opts.fpsInter)';

AllOpts.Range = 1:6479;

Opts.CorrelationWindow = 360 * Opts.fpsInter;

Opts.Range=cell(1,3);

Opts.Range{1} = 1:360*6;

Opts.Range{2} = (1:360*6) + 360*6;

Opts.Range{3} =  (1:360*6) + 720*6; Opts.Range{3}(end) = [];

%Opts.Range1= AllOpts.Range;


N1trace = interp1(tv,deltaFOverF(:,N1),tvInter,'linear');

N2trace = interp1(tv,deltaFOverF(:,N2),tvInter,'linear');





%figure out later why last element in N1trace and N2trace is NaN

N1trace(end) = [];
N2trace(end) =[];
tvInter(end) =[];

XCN12=cell(1,3);

for i=1:3
    
    NFig(i)=figure;
    
    subplot(3,1,1);
    
    plot(tvInter(Opts.Range{i}),N1trace(Opts.Range{i}))
    
    subplot(3,1,2);
    
    plot(tvInter(Opts.Range{i}),N2trace(Opts.Range{i}))
    
    [XCN12{i}, lags] = xcorr(N1trace(Opts.Range{i}),N2trace(Opts.Range{i}),Opts.CorrelationWindow);
    
    
    TimeLags = lags/Opts.fpsInter;
    
    subplot(3,1,3)
    
    plot(TimeLags,XCN12{i});
    
    [maxXC,maxLag] = max(abs(XCN12{i}));
    
    disp(maxXC);
    disp(TimeLags(maxLag));
    
end


ResultsStruct(n).displayname = displayname;

ResultsStruct(n).XCN_Opts.Range1 = XCN12{1};


ResultsStruct(n).XCN_Opts.Range2 = XCN12{2};

ResultsStruct(n).XCN_Opts.Range3 = XCN12{3};

ResultsStruct(n).NeuronNum1 = N1;

ResultsStruct(n).NeuronNum2 = N2;

ResultsStruct(n).ID1 = ID{N1};

ResultsStruct(n).ID2 = ID{N2};

ResultsStruct(n).Opts = Opts;


cd(MasterFolder);

save(ResultsStructFilename,'ResultsStruct');

cd(CurrentDirectory);

%bbbb=[ResultsStruct.XCN_Range3];


%%

grey = [0.7 0.7 0.7];

NumXCs = length(ResultsStruct);

Range1ALL = [];
Range2ALL = [];
Range3ALL = [];



NumFr = length(ResultsStruct(1).XCN_Opts.Range1);
Wind = (NumFr-1)/2;
TimeVec = ((-Wind:Wind)/ResultsStruct(1).Opts.fpsInter)';

n=0;

for i = 1:4; %[5 7 8 9 10  12 13 14];
    
    n=n+1;
    
    Range1ALL = [Range1ALL, ResultsStruct(i).XCN_Opts.Range1];
    Range2ALL = [Range2ALL, ResultsStruct(i).XCN_Opts.Range2];
    Range3ALL = [Range3ALL, ResultsStruct(i).XCN_Opts.Range3];
    
end



figure; plot(TimeVec,Range1ALL);

ylim([-800 800]);

mnRange1ALL = mean(Range1ALL,2);

strRange1ALL = std(Range1ALL,0,2)/sqrt(n);

figure; 

%jbfill(TimeVec,mnRange1ALL+strRange1ALL,mnRange1ALL-strRange1ALL,[1 1 1],[0 0 0],0,1);

plot(TimeVec,mnRange1ALL+strRange1ALL,'k','LineWidth',0.5);

hold on;

plot(TimeVec,mnRange1ALL-strRange1ALL,'k','LineWidth',0.5);


plot(TimeVec,mnRange1ALL,'b','LineWidth',1.5);

ylim([-500 500]);

%

figure; plot(TimeVec,Range2ALL);

ylim([-800 800]);

mnRange2ALL = mean(Range2ALL,2);

strRange2ALL = std(Range2ALL,0,2)/sqrt(n);

figure; 

%jbfill(TimeVec,mnRange1ALL+strRange1ALL,mnRange1ALL-strRange1ALL,[1 1 1],[0 0 0],0,1);

plot(TimeVec,mnRange2ALL+strRange2ALL,'k','LineWidth',0.5);

hold on;

plot(TimeVec,mnRange2ALL-strRange2ALL,'k','LineWidth',0.5);


plot(TimeVec,mnRange2ALL,'b','LineWidth',1.5);

ylim([-500 500]);


%

figure; plot(TimeVec,Range3ALL);

ylim([-800 800]);

mnRange3ALL = mean(Range3ALL,2);

strRange3ALL = std(Range3ALL,0,2)/sqrt(n);

figure; 

%jbfill(TimeVec,mnRange1ALL+strRange1ALL,mnRange1ALL-strRange1ALL,[1 1 1],[0 0 0],0,1);

plot(TimeVec,mnRange3ALL+strRange3ALL,'k','LineWidth',0.5);

hold on;

plot(TimeVec,mnRange3ALL-strRange3ALL,'k','LineWidth',0.5);


plot(TimeVec,mnRange3ALL,'b','LineWidth',1.5);

ylim([-500 500]);

