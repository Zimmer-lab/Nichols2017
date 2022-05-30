function TransformInterp()
%
    full_length=2132;
    uprezfactor=100;

    logdir=uigetdir('Select a directory of MotionTransform files');
    logfiles=dir([logdir filesep '*.txt']); 

    if ~exist([logdir filesep 'Expanded'],'dir')
        mkdir(logdir,'Expanded');
    end

    for f=1:length(logfiles)

        fid=fopen([logdir filesep logfiles(f).name]);
        fidw=fopen([logdir filesep 'Expanded' filesep logfiles(f).name(1:end-4) '-EX.txt'],'w');

        %read off first three lines and write into new file
        for i=1:3
            tline = fgetl(fid);
            fprintf(fidw,'%s\n',tline);
        end

        %read off copies of 010 
        tlines=cell(full_length/uprezfactor+1,10);
        getline='.';
        i=1; t=2;

        while ischar(getline)
            for i=1:10
                 getline = fgetl(fid);
                 if ischar(getline)
                    tlines{t,i}=getline;
                 end
            end
            t=t+1;
        end
        
        
        %copy in first timewindow entry from second, will not use
        %tranlations value
        
        for i=1:10
           tlines{1,i} = tlines{2,i};
        end 
        
        totalT=t-2;
        
        baseline=str2num(tlines{1,7});
          
        intervpvals(1,:)=baseline;
        
        for t=2:totalT
            interpvals(t,:)=str2num(tlines{t,3})-baseline;
        end

  
        interpvals(1,:)=[];
%         size(interpvals)


        %interpindices=[151:uprezfactor:(51+(totalT-1)*uprezfactor)]';
        interpindices=[51:uprezfactor:(-49+(totalT-1)*uprezfactor)]';

%         interpindices


        interpx=interp1(interpindices,interpvals(:,1),1:full_length,'linear','extrap')/uprezfactor+baseline(1);
        interpy=interp1(interpindices,interpvals(:,2),1:full_length,'linear','extrap')/uprezfactor+baseline(2);

        %interpolate up to 100x


        k=2; 
        for t=1:totalT+1



                for j=1:uprezfactor
                    if k<=full_length
                     tlines{t,2}=['Source img: ' num2str(k) ' Target img: 1'];  %frame number
                     tlines{t,3}=[num2str(interpx(k)) char(9) num2str(interpy(k))];
                     k=k+1;  
                     for i=1:10
                         fprintf(fidw,'%s\n',tlines{t,i});
                     end
                    end

               end
        end  

        fclose(fid);
        fclose(fidw);
        disp(['file ' num2str(f) ' processed.']);       
end



        

end %func


%% this was for image stabilizer plugin output
% 
% full_length=2132;
% uprezfactor=100;
% 
% logdir=uigetdir('Select a directory of log files');
% logfiles=dir([logdir filesep '*.txt']); 
% 
% if ~exist([logdir filesep 'Expanded'],'dir')
%     mkdir(logdir,'Expanded');
% end
% 
% for i=1:length(logfiles)
%     
%     k=importdata([logdir filesep logfiles(i).name], ',', 2);
%     
%     repk=kron(k.data,ones(uprezfactor,1));
% 
%     repk=repk(1:full_length,:);
% 
%     repk(:,1)=1:size(repk,1);
% 
%     firstline=k.textdata{1,1};
%     secondline=k.textdata{2,1};
% 
%     fid = fopen([logdir filesep 'Expanded' filesep logfiles(i).name(1:end-4) '_expanded.log'],'w');
%     fprintf(fid,'%s\n',firstline);
%     fprintf(fid,'%s\n',secondline);
%     for i=1:size(repk,1)
%         fprintf(fid,'%d,%d,%f,%f\n',repk(i,1),repk(i,2),repk(i,3),repk(i,4));
%     end
%     fclose(fid);
% 
% end



