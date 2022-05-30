%%Finds consequtive active runs and will exclude ones which are not long
%%enough.

ConsecSec = Qoptions.ConsecutiveBinSize; % consectutive number of seconds that the quiescent period be to be defined as Quiescent.

boutsizethreshold = round(ConsecSec*wbstruct.fps); % 30 seconds

%calculate positions of consequtive values, i.e. active run starts and ends
%QuiesceBout

WakeToQu = ~[true;diff(QuiesceBout(:))~=1 ];
QuToWake = ~[true;diff(QuiesceBout(:))~=-1 ];

ActRunEnd=find(WakeToQu,'1');
ActRunStart=find(QuToWake,'1');

if QuiesceBout(1,1)==0; % adds a run start at tv=1 if there is Activity there
    if length(ActRunStart)<2 % if ActRunStart is only 1 it makes a wrong vector direction.
        ActRunStart(2:end+1)=ActRunStart;
        ActRunStart(1)=1;   
        ActRunStart = ActRunStart';
    else
        ActRunStart(2:end+1)=ActRunStart;
        ActRunStart(1)=1;
    end
end

if QuiesceBout(end,1)==0;  % adds a run end at tv=end if there is Activity there
    ActRunEnd(length(ActRunEnd)+1,1)=length(QuiesceBout);
end

%calculates the lengths of the runs.
ActRunLength = ActRunEnd - ActRunStart;
DiscludedBout = ActRunLength <= boutsizethreshold;


for a = 1:(length(DiscludedBout));
    if DiscludedBout(a)== 1; % if it finds a bout to disclude it will change it to quiescence i.e. 1s
        QuiesceBout(ActRunStart(a):(ActRunEnd(a)-1),1) = '1'; %checks where it is switching
        a=a+1;
    else
        a=a+1;
    end
end

