%%
  
clear all

%Define cutoff:
cutoff = 1.25%1.25; %1.875; %3 for 40x. %1.875 would be equivalent

%Load tracks
[~, deepestFolder, ~] = fileparts(pwd);
load(strcat(deepestFolder,'_track.mat'));

SlideSpeedQuiClass
%% Find Quiescent time points
QuToWake = ~[true;diff(Active(:))~=1 ];
WakeToQu = ~[true;diff(Active(:))~=-1 ];

%% OLD
% QuRunStarta=find(WakeToQu(1:999),'1');
% QuRunStartb=(find(WakeToQu(1000:length(Active)),'1'))+999; %work around as it wouldn't give me all values.
% QuRunStart = [QuRunStarta; QuRunStartb];  %find(WakeToQu,'1');
% 
% QuRunEnda=find(QuToWake(1:999),'1');
% QuRunEndb=find(QuToWake(1000:length(Active)),'1')+999;
% QuRunEnd = [QuRunEnda; QuRunEndb];

%Gave error: 
% Error using rectangle
% Width and height must be > 0
% 
% Error in PharynxSpeedQA (line 49)
%     rectangle('Position',[x1,y1,w1,h1],'FaceColor', paleblue,'EdgeColor', paleblue);
%% 

QuRunStart=find(WakeToQu);
QuRunEnd=find(QuToWake);

if Active(1,1)==0; % adds a run start at tv=1 if there is Quiescence there
    QuRunStart(2:end+1)=QuRunStart;
    QuRunStart(1)=1;
end

if Active(1,end)==0 ;  % adds a run end at tv=end if there is Quiescence there
    QuRunEnd(length(QuRunEnd)+1,1)=length(Active);
    if Active(1,(end-1))==1;
        QuRunStart = QuRunStart(1:(end-1));
    end
end

%% Change to seconds
QuRunStart = QuRunStart*0.2;
QuRunEnd = QuRunEnd*0.2;

paleblue = [0.8  0.93  1]; %255

numBouts = length(QuRunStart);
y1=-0.399;
h1=60;

tv=0.2:0.2:299;

figure;
for n1= 1:numBouts;
    x1=(QuRunStart(n1));
    w1=(QuRunEnd(n1)-QuRunStart(n1));
    rectangle('Position',[x1,y1,w1,h1],'FaceColor', paleblue,'EdgeColor', paleblue);
end
title(strcat('Cutoff =', mat2str(cutoff)));
hold on;
plot(tv,SlideSpeed,'k')
hold on;
xlabel('Time (s)','Color','k','FontSize',12);
ylabel('Speed (pixel/0.2sec)','Color','k','FontSize',12);


    set(gca, 'XColor', 'k');
    set(gca, 'YColor', 'k');
    set(gca,'Color',[1 1 1]);
line('XData', [0 300], 'YData', [cutoff cutoff],'color','r','LineStyle', '-')
set(gca,'Color',[1 1 1]);
ylim([0 60]);