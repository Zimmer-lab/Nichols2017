function frame=time2frame(tv,time)
%frame=time2frame(tv,time)

    for i=1:length(time)
         frame(i)=find(tv>=time(i),1,'first');
    end

end