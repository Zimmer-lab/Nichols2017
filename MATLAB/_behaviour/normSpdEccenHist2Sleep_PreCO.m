%% Plot Speed vs dEccentricity/dt
clear all
%Enter Prelethargus data folder:
direct.Pre = '/Users/nichols/Desktop/_Dish/_Prelet_one folder';

%Enter Lethargus data folder:
direct.Let = '/Users/nichols/Desktop/_Dish/_Let_one folder';

%Enter Prelethargus data folder:
% direct.Pre = '/Users/nichols/Desktop/_SleepQuant_2DHist/N2_18_O2_21.0_s_1.Prelet';
% 
% %Enter Lethargus data folder:
% direct.Let = '/Users/nichols/Desktop/_SleepQuant_2DHist/N2_18_O2_21.0_s_2.Let_';

%Time from recording (bins):
tRange = 150:240;
tRange = 1:240;
%tRange = 1:120;

%%
condition = {'Pre','Let'};

for nnn = 1:2;
    CurrCond = condition{nnn};
    cd(direct.(CurrCond));
    
    DishSleepQuant %with pwd as input!!!!
    % Formly used(pre 2016-08-04): SleepQuant_v2
    
    %only want from 10% oxygen from dish assays. use tRange
    % Use aAllSpeed for all tracks or AllSpeed for only full length tracks.
    % Do this for all the Range matrices:
    RangeSBinTrcksSpdSize = aAllSpeed(:,tRange);
    RangeDBinSmoothedEccentricityDSt = aAllEccen(:,tRange);
    
    Rangermdwlstate = aAllrmdwlstate(:,tRange); %aAllrmdwlstate aAllPreCOrmdwlstate
    RangePostureState = aAllPostureState(:,tRange); %aAllPostureState aAllPreCOPostureState
    
    %Find full tracks... ==0.
    sum(isnan(AllSpeed'));
    
    [rows, cols] =size(RangeSBinTrcksSpdSize);
    
    FullAllnormSpeed =  reshape(RangeSBinTrcksSpdSize',[1,(rows*cols)]); 
    %we lose one Eccen data point cause of d/dt.
    FullAllnormEccen = reshape(RangeDBinSmoothedEccentricityDSt',[1,(rows*cols)]);
    FullAllrmdwlstate =  reshape(Rangermdwlstate',[1,(rows*cols)]); 
    FullAllPostureState =  reshape(RangePostureState',[1,(rows*cols)]);


%data
DataT.Sp.(CurrCond) =FullAllnormSpeed;
DataT.Ec.(CurrCond) =FullAllnormEccen;
DataT.Rmdwl.(CurrCond) =FullAllrmdwlstate;
DataT.Pos.(CurrCond) =FullAllPostureState;
end

%Don't need to:Reshape into 1 row, remove NaNs. we lose one Eccen data point cause of d/dt.
%as can just input the catatonated struct into hist2 and it deals with the
%NaNs.


%% Plotting
%axes
xedges=(0:0.00005:0.002);
yedges=(0:0.001:0.05);

%Plot Speed vs Eccen.
for nn = 1:2;
    CurrCond = condition{nn};
    %the 2D histograms
    M.(CurrCond) = (hist2(DataT.Ec.(CurrCond),DataT.Sp.(CurrCond), xedges, yedges))/length(DataT.Ec.(CurrCond));
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

%%
DataTypeName = {'Speed','Eccentricity','Rmdwlstate','PostureState'};
DataType = {'Sp','Ec','Rmdwl','Pos'};

% Plot  hist
for nn = 1:length(DataType);
    for nnn= 1:2;%conditions 
        if nn < 3
            numHistBins = 100;
        else
            numHistBins =7;
        end
        CurrCond = condition{nnn};
        CurrData = DataT.(DataType{nn});
        figure; 
        [Counts,binValues] = hist(CurrData.(CurrCond)(:),numHistBins);
        normCounts = Counts/sum(~isnan((CurrData.(CurrCond)))); %Normalise, excludes NaNs
        bar(binValues, normCounts, 'barwidth', 1);
        title(strcat(DataTypeName{nn},'-',CurrCond));
        
        if nn == 3;
            if nnn == 1
                PreRmdwlHist = normCounts;
            else
                LetRmdwlHist = normCounts;
            end
        end
        
        if nn == 4;
            if nnn == 1
                PrePosHist = normCounts;
            else
                LetPosHist = normCounts;
            end
        end
            
        
        %Cutoffs
        if nn == 1; %Speed
           line('XData', [0.008 0.008], 'YData', [0 0.5], 'color', [0 0 0], 'LineStyle', '-')
        end
        
        if nn == 2; %Eccen
           line('XData', [0.0009 0.0009], 'YData', [0 0.5], 'color', [0 0 0], 'LineStyle', '-')
        end
        
    end
end

%% Plot both Pre and Let on same plot
test = [LetRmdwlHist; PreRmdwlHist];
figure; bar(test');

test = [PrePosHist; LetPosHist];
figure; bar(test');

%% Plot histograms of eccen.
for nnn= 1:2;%conditions
    CurrCond = condition{nnn};
    CurrData = DataT.Ec.(CurrCond);
    HistBinCen = 0:0.00002:0.009;
    figure;
    [Counts,binValues] = hist(CurrData(:),HistBinCen);
    
    normCounts = Counts/sum(~isnan((CurrData))); %Normalise, excludes NaNs
    bar(binValues, normCounts, 'barwidth', 1);
    %set axis
    title(strcat('dEccentricity/dt-',CurrCond));

end

%% Plots 2D histogram of the Rmdwl and Posture state.
%axes
xyedges=(0:1:6);
xedges=(0:0.00005:0.003);%(0:0.001:0.9);%(0:0.00005:0.003); %should be bigger, then becomes y axis
yedges=(0:0.00025:0.05);%(0:0.0001:0.01);%(0:0.00025:0.05);

% 10% Dish
xedges=(0:0.00005:0.003);
yedges=(0:0.00025:0.05);

%Plot Speed vs Eccen.
for nn = 1:2;
    CurrCond = condition{nn};
    %the 2D histograms %first position is Y!!!! Bug in the function. This
    %is only the case when the two matrices are the same size or Y is
    %bigger but CHECK!
    Ma.(CurrCond) = (hist2(DataT.Pos.(CurrCond),DataT.Rmdwl.(CurrCond), xedges, yedges))/length(DataT.Pos.(CurrCond));
    figure;imagesc(xedges, (yedges),Ma.(CurrCond));
    set(gca,'YDir','normal')
    title(CurrCond);

     %maxyedges= max(yedges);
     ylabel('RmdwlState');
     xlabel('PostureState');

     %Thresholds lines 
     %Speed 0.35 0.35
     line('XData', [0.0009 0.0009], 'YData', [-0.5 0.008], 'color', [1 1 1], 'LineStyle', '-')
     %Eccen 0.2 0.2
     line('XData', [-0.5 0.0009], 'YData', [0.008 0.008], 'color', [1 1 1], 'LineStyle', '-')
end

% Be careful of random flipping and wrong axes
%% NOTE
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
