function [TrcksAcc, files, DatasetPointer] = AccRevDatsV2_AN(flnmstr)

%AN: Modified from AccRevDatsV2b to be able to work on old tracks which
%don't have wormimages.
%loads tracks data from wormanalyzer 'Analyze all tracks' into one
%structure 'TrcksAcc' and returns a cell array that contains all filenames



flnms=dir(flnmstr); %create structure from filenames


files={flnms.name}';

[max, ~] = size(flnms);

TrcksAcc =[]; %structure that accumulates all tracks data

DatasetPointer(1,1) = 1;
DatasetPointer(1,2) = 0;

files{1,2} = 1;
files{2,3} = 0;

for i=1:max;
    
    
    
   
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
    
    
    
    TrcksAcc = [TrcksAcc file.Tracks];
    
    
end;