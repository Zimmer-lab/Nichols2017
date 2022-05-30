javaoptsFile=[matlabroot filesep 'bin' filesep computer('arch') filesep 'java.opts'];

fid=fopen(javaoptsFile,'a');  %append write mode

%%
fprintf(fid,'%s','-Xmx512m');
fclose(fid);

type(javaoptsFile)

disp('FIN.');

%%
java.lang.Runtime.getRuntime.maxMemory/1024/1024