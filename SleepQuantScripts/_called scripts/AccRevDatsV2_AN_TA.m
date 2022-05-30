function [TrcksAcc, files, DatasetPointer] = AccRevDatsV2_AN_TA(flnmstr)

%AN: Modified from AccRevDatsV2b to be able to work on old tracks which
%don't have wormimages.
%loads tracks data from wormanalyzer 'Analyze all tracks' into one
%structure 'TrcksAcc' and returns a cell array that contains all filenames

%AN: 20170309 adjusted to account for the time offset based of MV##
% This is accomplished by finding the time delay of that movie (i.e. the
% time difference between the frame number given and what is considered to
% be the true frame/second. Then this is subtracted from all the outputs and negative frames removed.
% Meaning that the start of some tracks are cut off.


flnms=dir(flnmstr); %create structure from filenames

files={flnms.name}';

[maxF, ~] = size(flnms);

TrcksAcc =[]; %structure that accumulates all tracks data

DatasetPointer(1,1) = 1;
DatasetPointer(1,2) = 0;

files{1,2} = 1;
files{2,3} = 0;

for i=1:maxF;
        
   
    file = load (flnms(i).name);
    
    FieldsToRemove = {'Path','LastCoordinates','LastSize','FilledArea','Round','RingEffect',...
                       'Time','SmoothX','SmoothY','Direction','AngSpeed','SmoothEccentricity',...
                       'SmoothRound'};
                      
    file.Tracks = rmfield(file.Tracks,FieldsToRemove);
    
   %to make compatable with old tracks which don't have
   %wormimage
   
   if isfield(file.Tracks,'WormImages');
       FieldsToRemoveNew = {'WormImages','MeanIntensity','Direction360','ApproxWormLength',...
                            'polishedReversals','OmegaTransDeep','OmegaTransShallow',...
                            'ReverseOmega','ReverseShallowTurn'};
        file.Tracks = rmfield(file.Tracks,FieldsToRemoveNew);
   end

    
    [~,NumTracks] = size(file.Tracks);
    
    if i>1
        
       DatasetPointer(i,1) = DatasetPointer(i-1,2)+1; 
       DatasetPointer(i,2) =  DatasetPointer(i-1,2) + NumTracks;
       
       
       files{i,2} = files{i-1,3}+1; 
       files{i,3} =  files{i-1,3} + NumTracks;
         
    else
        DatasetPointer(i,2) = NumTracks;
                files{i,3} = NumTracks;

        
    end
    
    disp('Warning!: correcting frame numbers (Annika and Tomas specific for old recordings where recording length was mistakenly 89.91min not 90min)')
    %Find MV## 
    MVposition = (strfind(files{i, 1},'MV'))+2;
    %Catches if MV numbers are not inserted
    if isempty(MVposition)
        disp(['Warning!: MV number not included for ',files{i, 1}])
        return
    end
    MVnumber = str2double(files{i, 1}(MVposition:(MVposition+1)));
    
    %Determine number of frames to subtract (use floor as it's unlikely the
    %program can add another frame but would rather skip it).
    FramesToSubtract = floor(5.4*3.003003003)*(MVnumber-1);
    
    % Subtract the frames from the frame vectors and the start/end frames of the
    % Pirouettes, OmegaTrans and Reversals
    for Tnum = 1: length(file.Tracks);
        file.Tracks(1,Tnum).Frames = file.Tracks(1,Tnum).Frames -FramesToSubtract;
        file.Tracks(1, Tnum).Pirouettes = file.Tracks(1, Tnum).Pirouettes -FramesToSubtract;
        file.Tracks(1, Tnum).OmegaTrans = file.Tracks(1, Tnum).OmegaTrans -FramesToSubtract;
        if ~isempty(file.Tracks(1, Tnum).Reversals)
            file.Tracks(1, Tnum).Reversals(:,1:2) = file.Tracks(1, Tnum).Reversals(:,1:2) -FramesToSubtract;
        end
        %take away negative (and ==0) frames from all fields
        %if max((file.Tracks(1,Tnum).Frames)<1); Have a case where frames
        %start at 41 but a pirouette is at 5...
            % Of the vectors:
            DiscludedFrames = (file.Tracks(1,Tnum).Frames)<1;
            file.Tracks(1,Tnum).Frames(DiscludedFrames) =[];
            file.Tracks(1,Tnum).Size(DiscludedFrames) =[];
            file.Tracks(1,Tnum).Eccentricity(DiscludedFrames) =[];
            file.Tracks(1,Tnum).MajorAxes(DiscludedFrames) =[];
            file.Tracks(1,Tnum).RingDistance(DiscludedFrames) =[];
            file.Tracks(1,Tnum).Speed(DiscludedFrames) =[];
            file.Tracks(1, 1).NumFrames = (file.Tracks(1, 1).NumFrames) - FramesToSubtract; 
            
            %For Pirouettes, OmegaTrans and Reversals:
            file.Tracks(1, Tnum).Pirouettes((min(file.Tracks(1, Tnum).Pirouettes,[],2))<1,:) = [];
            file.Tracks(1, Tnum).OmegaTrans((min(file.Tracks(1, Tnum).OmegaTrans,[],2))<1,:) = [];
            file.Tracks(1, Tnum).Reversals((min(file.Tracks(1, Tnum).Reversals,[],2))<=0,:) = [];
        %end
    end

    TrcksAcc = [TrcksAcc file.Tracks];
    
    
end;