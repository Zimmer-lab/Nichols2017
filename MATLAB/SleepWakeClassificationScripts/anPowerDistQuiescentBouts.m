%annika power dist for quiescent periods

%calculate positions of consequtive values, i.e. quiescent bout run starts
%and ends.

WakeToQuB = ~[true;diff(QuiesceBout(:))~=1 ];
QuBToWake = ~[true;diff(QuiesceBout(:))~=-1 ];

QuBRunStart=find(WakeToQuB,'1');
QuBRunEnd=find(QuBToWake,'1');

if QuiesceBout(1,1)==1; % adds a run start at tv=1 if there is Quiescence there
    QuBRunStart(2:end+1)=QuBRunStart;
    QuBRunStart(1)=1;
end

if QuiesceBout(end,1)==1;  % adds a run end at tv=end if there is Quiescence there
    QuBRunEnd(length(QuBRunEnd)+1,1)=length(QuiesceBout);
end


%builds the options.range for the quiescent bouts.
rangebuild = char.empty;
rangebuild = strcat(rangebuild, num2str(QuBRunStart(1)),':',num2str(QuBRunEnd(1)));

for num1= 2:length(QuBRunStart);
    rangebuild = strcat(rangebuild,',', num2str(QuBRunStart(num1)),':',num2str(QuBRunEnd(num1)));
end

options.range=strcat('[',rangebuild,']');  % [1:100,200:400] %

% %options.fieldName={'derivs','traces'};    OR
% options.fieldName='deltaFOverF_bc';
% wbload;
% sA=wbPlotDistribution(wbstruct,'rms',options);

% clearvars -except sA 
% dateRun = datestr(now);
% save ([strcat(pwd,'/Quant/QuiescentState.mat')]);