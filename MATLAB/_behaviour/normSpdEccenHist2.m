%% Plot Speed vs dEccentricity/dt
%Enter Prelethargus data folder:
direct.Pre = '/Users/nichols/Desktop/_Dish/_Prelet_one folder/_PreLet_als';

%Enter Lethargus data folder:
direct.Let = '/Users/nichols/Desktop/_Dish/_Let_one folder';

%Time from recording:
tRange = 150:240;
%tRange = 1:120;


%%
condition = {'Pre','Let'};

for nnn = 1:2;
    CurrCond = condition{nnn};
    cd(direct.(CurrCond));
    
    allnormSpeed=[];
    allnormEccen=[];
    
    GetNormSpdEccen

    
    %only want from 10% oxygen from dish assays. use tRange
    RangeSBinTrcksSpdSize = SBinTrcksSpdSize(:,tRange);
    RangeDBinSmoothedEccentricityDSt = DBinSmoothedEccentricityDSt(:,tRange);
    
    %Find full tracks... ==0.
    sum(isnan(SBinTrcksSpdSize'));
    
    [rows, cols] =size(RangeSBinTrcksSpdSize);
    
    FullAllnormSpeed =  reshape(RangeSBinTrcksSpdSize',[1,(rows*cols)]); 
    %we lose one Eccen data point cause of d/dt.
    FullAllnormEccen = reshape(RangeDBinSmoothedEccentricityDSt',[1,(rows*cols)]);

%data
S.(CurrCond) =FullAllnormSpeed;
E.(CurrCond) =FullAllnormEccen;
end

%Don't need to:Reshape into 1 row, remove NaNs. we lose one Eccen data point cause of d/dt.
%as can just input the catatonated struct into hist2 and it deals with the
%NaNs.


%% Plotting
%axes
xedges=(0:0.00005:0.002);
yedges=(0:0.001:0.5);

for nn = 1:2;

    CurrCond = condition{nn};
    %the 2D histograms
    M.(CurrCond) = (hist2(E.(CurrCond),S.(CurrCond), xedges, yedges))/length(E.(CurrCond));
    figure;imagesc(xedges, (yedges),M.(CurrCond));
    set(gca,'YDir','normal')
    title(CurrCond);

     %maxyedges= max(yedges);
     xlabel('dEccentricity/dt');
     ylabel('Speed');

     %Thresholds lines
     line('XData', [0.0009 0.0009], 'YData', [0 0.008], 'color', [1 1 1], 'LineStyle', '-')
     line('XData', [0 0.0009], 'YData', [0.008 0.008], 'color', [1 1 1], 'LineStyle', '-')


end

% Be careful of random flipping and wrong axes

%%NOTE
%Need to be able to compare this back to the cutoffs. 
%             binning = 15; %binning in frames: speed is averaged over the bins, turns are summed up.
% 
%             %categorization parameters for speed:
%             cutoff = 0.008; % 0.008  above which speed (wormlenghts / s) the worm is considered to be engaged in a motion bout
%             roamthresh = 0.35; 
% 
%             %categorization parameters for eccentricity:
%             posturethresh = 0.2;
%             SmoothEccentWin = 5 ; %smooth eccentricity over how many bins
%             DEccentrThresh = 0.0009; % above which eccentricity change (D/Dt) the worm is considered to be engaged in a motion bout
% 
