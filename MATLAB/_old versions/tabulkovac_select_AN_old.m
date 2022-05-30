function tabulkovac_select_AN(dirPath)
%-example run-:tabulkovac_select_AN('/Users/eichler/Desktop/_Averaging_FEQ/_Test_Stats_Results');

clc
files    = dir(dirPath);
fid      = -1;
fileName = '';

% -- 8 processing round = 8 different variables to store
for round = 1 : 8
    
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
                
                fprintf('Processing file %s, round %d \n',fileName,round);
                
                % -- round number <==> variable name correspodence decision
                % logic
                
                %%%%%%%%%%%%%
 
                
                switch(round)
                    case 1
                        var = 'LRresponse1SleepSelect';
                        [fid,fileOpened] = writeTableAsCSV(fid,fileOpened,fileName,var);
                    case 2
                        var = 'LRresponse1WakeSelect';
                        [fid,fileOpened] = writeTableAsCSV(fid,fileOpened,fileName,var);
                    case 3
                        var = 'LRresponse2SleepSelect';
                        [fid,fileOpened] = writeTableAsCSV(fid,fileOpened,fileName,var);
                    case 4
                        var = 'LRresponse2WakeSelect';
                        [fid,fileOpened] = writeTableAsCSV(fid,fileOpened,fileName,var);
                    case 5
                        var = 'Oresponse1SleepSelect';
                        [fid,fileOpened] = writeTableAsCSV(fid,fileOpened,fileName,var);
                    case 6
                        var = 'Oresponse1WakeSelect';
                        [fid,fileOpened] = writeTableAsCSV(fid,fileOpened,fileName,var);
                    case 7
                        var = 'Oresponse2WakeSelect';
                        [fid,fileOpened] = writeTableAsCSV(fid,fileOpened,fileName,var);
                    case 8
                        var = 'Oresponse2SleepSelect';
                        [fid,fileOpened] = writeTableAsCSV(fid,fileOpened,fileName,var);
                end
            end
            
        end
    end
end

if fid ~= -1
    try
        fclose(fid);
    catch me
        fprintf('Hmm, weird could not close the %s csv file, data should be okay.\n',fileName);
    end
end

end


function [fid,fileOpened] = writeTableAsCSV(fid,fileOpened,fileName,var)

load(fileName,var);

if fileOpened == false
    fid = fopen(strcat(var,'.csv'), 'w');
    if (fid ~= -1)
        fileOpened = true;
    else
        fprintf('\n\nError: file %scsv is probably open in external editor / excel. Close it! \n',fileName(1:end-3));
    end
end

fprintf(fid,'%s;'    ,fileName);
fprintf(fid,'%.16f; ',eval(var)');
fprintf(fid,'\n');
end