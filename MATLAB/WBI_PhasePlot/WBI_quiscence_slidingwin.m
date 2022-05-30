frameNum = length(instQuiesce);


binsize=9; %in frames as using seconds doesn't make much sense as it must be uneven

binsize=binsize-1;
wakestate = instQuiesce; %NOTE instQuiesce = instantaneous Quiescence

% Note: 1 equals a Quiescent state, while 0 signifies an active state.
% The sliding window can't calculate on the edges. Exclude or leave as is?
 

  for i=((binsize/2)+1):(frameNum-((binsize/2))-1);
      
    slidingwin=instQuiesce((i-((binsize)/2)):(i+(binsize/2)),1);
    if mean(slidingwin)>0.8
        wakestate(i,1)=1;
    else
        wakestate(i,1)=0;
    end
  end
figure;
h1= plot(instQuiesce, 'r');
hold on; 
wakestate2=wakestate+.05;
h2= plot((wakestate2), 'b');
set(h1, 'LineWidth', 5);  
set(h2, 'LineWidth', 5);  


% wbload;
% wbstruct.fps
% binsize=((2.*round((wbstruct.fps)+1)/2)-1)+5; % this should end up around 

  
  