%%QuiesRuns

ConsecSec = Qoptions.ConsecutiveBinSize; % consectutive number of seconds that the quiescent period be to be defined as Quiescent.

%N = round(10*fps); % Required number of consecutive numbers following a first one
boutsizethreshold = round(ConsecSec*wbstruct.fps); % 30   seconds

%calculate positions of consequtive values, i.e. quiescent run starts and ends

WakeToQu = ~[true;diff(instQuiesce(:))~=1 ];
QuToWake = ~[true;diff(instQuiesce(:))~=-1 ];

QuRunStart=find(WakeToQu,'1');
QuRunEnd=find(QuToWake,'1');

if instQuiesce(1,1)==1; % adds a run start at tv=1 if there is Quiescence there
    QuRunStart(2:end+1)=QuRunStart;
    QuRunStart(1)=1;
end

if instQuiesce(end,1)==1;  % adds a run end at tv=end if there is Quiescence there
    QuRunEnd(length(QuRunEnd)+1,1)=length(instQuiesce);
end

%calculates the lengths of the runs.
QuRunLength = QuRunEnd - QuRunStart;
IncBout = QuRunLength >= boutsizethreshold;
QuiesceBout = false(length(instQuiesce),1);

for a = 1:(length(IncBout));
    if IncBout(a)== 1;
        QuiesceBout(QuRunStart(a):(QuRunEnd(a)-1),1) = '1'; %checks where it is switching
        a=a+1;
    else
        a=a+1;
    end
    
    if QuiesceBout(end,1)==0 & QuiesceBout((end-1),1)==1; %adds a 1 at the end if the second to last value is also a one (corrects for 0 at end artefact)
       QuiesceBout(end,1) = '1';
    end
end

