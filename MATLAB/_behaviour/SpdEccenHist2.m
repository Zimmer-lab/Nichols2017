%% Plot Speed vs dEccentricity/dt
%Enter Prelethargus data folder:
direct.Pre = '/Users/nichols/Desktop/_test/npr-1-CX13663_18C_O2_21.0_s_1.PreLet_2015_';

%Enter Lethargus data folder:
direct.Let = '/Users/nichols/Desktop/_test/npr-1-CX13663_18C_O2_21.0_s_2015_2.Lethargus_';

%%
condition = {'Pre','Let'};
maindir =pwd;

for nnn = 1:2;
    CurrCond = condition{nnn};
    cd(direct.(CurrCond));
    
    DataFileName = '*_als.mat';

    Files = dir(DataFileName);
    
    [NumberOfAlsFiles, ~] = size(Files);
    allSpeed=[];
    allEccen=[];

    for CurrAlsFile = 1:NumberOfAlsFiles

        disp(num2str(CurrAlsFile));

        disp(strcat('now loading: ',32, Files(CurrAlsFile).name));
        load(Files(CurrAlsFile).name);
        [~, NumTracks] = size(Tracks);
        for ii = 1:NumTracks;
            allSpeedi = Tracks(ii).Speed;
            allEcceni = diff(Tracks(ii).Eccentricity);
            allSpeed = horzcat(allSpeed, allSpeedi(1:(end-1))); %we lose one Eccen data point cause of d/dt.
            allEccen = horzcat(allEccen, allEcceni(1:(end)));
        end

    end
%data
S.(CurrCond) =allSpeed;
E.(CurrCond) =allEccen;
end


%% Plotting
%axes
xedges=(0:0.0001:0.01);
yedges=(0:0.00025:0.035);


for nn = 1:2;
    CurrCond = condition{nn};
    %the 2D histograms
    M.(CurrCond) = (hist2(E.(CurrCond),S.(CurrCond), xedges, yedges))/length(E.(CurrCond));
    figure;imagesc(xedges, (yedges),M.(CurrCond));
    set(gca,'YDir','normal')

    maxyedges= max(yedges);
    xlabel('dEccentricity/dt');
    ylabel('Speed');

end

% Be careful of random flipping and worng axes

%%NOTE
%Need to be able to compare this back to the cutoffs. However these are
%binned.


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
