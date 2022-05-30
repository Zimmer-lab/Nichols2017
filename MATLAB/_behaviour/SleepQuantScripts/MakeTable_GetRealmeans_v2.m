function MakeTable_GetRealmeans()
% 1. Run
% 2. Pick the directory with _select.mat files
% !! It's not skipping other .mat files
% 3. only the RealMeans has the correct number format, other vales do not

clc
currentFolder = pwd;
dirPath = uigetdir(currentFolder, 'Pick a Directory');

files    = dir(dirPath);
fid      = -1;
fileName = '';

% first clean specific csv files 
 RemoveFile( strcat(dirPath,'/nExperiments.csv'));
 RemoveFile( strcat(dirPath,'/nTracksPerExp.csv'));
 RemoveFile( strcat(dirPath,'/numTrack.csv'));
 RemoveFile( strcat(dirPath,'/RealMeans.csv'));
 RemoveFile( strcat(dirPath,'/SingleRecordNames.csv'));



% -- 6 processing round = 6 different variables to store
%for round = 1 : 3

fileOpened = false;

if fid ~= -1
    try
        fclose(fid);
    catch me
        fprintf('Hmm, weird could not close the %s csv file, data should be okay.\n',fileName);
    end
end

% -- find in all mat files the variable corresponding to the round number
for i = 1 : length(files)
    
    % -- check if the file is not directory
    if (files(i).isdir) == false
        
        % -- get the filename & file extension
        fileName = files(i).name;
        fileExt  = fileName(end-3:end);
        
        
        % -- check that the file is only of .mat type
        if strcmp( fileExt,'.mat') == true
            
            fprintf('Processing file %s \n',fileName);
            
            % -- round number <==> variable name correspodence decision
            % logic
            
            [RealMeans,nExperiments,nTracksPerExp,numTrack,SingleRecordNames] = SleepStats_Get_MeanReadout_v2(fileName);
            
             writeTableAsCSV('RealMeans',fileName,RealMeans);
             writeTableAsCSV('nExperiments', fileName, nExperiments);
             writeTableAsCSV('nTracksPerExp', fileName,nTracksPerExp);
             writeTableAsCSV('numTrack',fileName,numTrack);
             writeTableAsCSV('SingleRecordNames',fileName,SingleRecordNames);

        end % strcmp
        
    end
end
%end% round

% 
% if fid ~= -1
%     try
%         fclose(fid);
%     catch me
%         fprintf('Hmm, weird could not close the %s csv file, data should be okay.\n',fileName);
%     end
% end

end

function RemoveFile(file)
if exist(file,'file')==2
  fprintf('Deleting %s \n',file)
  delete(file);
end  

end


function   writeTableAsCSV(csvFileName, matFileName, var)

 
% if fileOpened == false
%     fid = fopen(strcat(varName,'.csv'), 'w');
%     if (fid ~= -1)
%         fileOpened = true;
%     else
%         fprintf('\n\nError: file %scsv is probably open in external editor / excel. Close it! \n',fileName(1:end-3));
%     end
% end
% 

fid = fopen(strcat(csvFileName,'.csv'), 'a+');

fprintf(fid,'%s;'    ,matFileName);
fprintf(fid,'%.16f; ',var);
fprintf(fid,'\n');

fclose(fid);
end