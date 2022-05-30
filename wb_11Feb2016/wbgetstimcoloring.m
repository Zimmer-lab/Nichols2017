function timecoloring=wbgetstimcoloring(wbstruct,number,onsettime,polarity)

if nargin<4
    polarity=0;
end

if nargin<2 
    
    timecoloring=zeros(size(wbstruct.tv));
    if isfield(wbstruct,'stimulus') && ~isempty(wbstruct.stimulus)
        if isfield(wbstruct.stimulus,'ch')
            for thisswitch=(1+polarity):length(wbstruct.stimulus.ch(1).switchtimes)
               vline(wbstruct.stimulus.ch(1).switchtimes(thisswitch));
               numconclevels=length(wbstruct.stimulus.ch(1).conc);
               thisconcval=wbstruct.stimulus.ch(1).conc(1+mod(wbstruct{1}.stimulus.ch(1).initialstate+thisswitch-1, numconclevels));
               text(wbstruct.stimulus.ch(1).switchtimes(thisswitch),0.2,['  ' num2str(thisconcval) ' ' wbstruct.stimulus.ch(1).concunits ' ' wbstruct.stimulus.ch(1).identity],'Color',[0.5 0.5 0.5],'FontSize',12);


            end
        else  %for stimulus with no channel info
            for thisswitch=(1+polarity):2:length(wbstruct.stimulus.switchtimes)


               if length(wbstruct.stimulus.switchtimes) > thisswitch

                    timecoloring(time2frame( wbstruct.tv, wbstruct.stimulus.switchtimes(thisswitch) )  :  time2frame (wbstruct.tv, wbstruct.stimulus.switchtimes(thisswitch+1)  ) ) =1;
               else

                    timecoloring(time2frame( wbstruct.tv, wbstruct.stimulus.switchtimes(thisswitch) )  :  time2frame (wbstruct.tv, wbstruct.stimulus.switchtimes(end) )   )=1;

               end
            end
        end
    end
    
else
    
    timecoloring=zeros(size(wbstruct.tv));
    if isfield(wbstruct,'stimulus') && ~isempty(wbstruct.stimulus)
        if isfield(wbstruct.stimulus,'ch')
            for thisswitch=(1+polarity):length(wbstruct.stimulus.ch(1).switchtimes)
               vline(wbstruct.stimulus.ch(1).switchtimes(thisswitch));
               numconclevels=length(wbstruct.stimulus.ch(1).conc);
               thisconcval=wbstruct.stimulus.ch(1).conc(1+mod(wbstruct{1}.stimulus.ch(1).initialstate+thisswitch-1, numconclevels));
               text(wbstruct.stimulus.ch(1).switchtimes(thisswitch),0.2,['  ' num2str(thisconcval) ' ' wbstruct.stimulus.ch(1).concunits ' ' wbstruct.stimulus.ch(1).identity],'Color',[0.5 0.5 0.5],'FontSize',12);


            end
        else  %for stimulus with no channel info
            for thisswitch=(number*2-1+polarity):(number*2-1+polarity)

               if nargin<3 || isempty(onsettime)
                    
                   if length(wbstruct.stimulus.switchtimes) > thisswitch

                        timecoloring(time2frame( wbstruct.tv, wbstruct.stimulus.switchtimes(thisswitch) )  :  time2frame (wbstruct.tv, wbstruct.stimulus.switchtimes(thisswitch+1)  ) ) =1;
                   else

                        timecoloring(time2frame( wbstruct.tv, wbstruct.stimulus.switchtimes(thisswitch) )  :  time2frame (wbstruct.tv, wbstruct.stimulus.switchtimes(end) )   )=1;

                   end

               else
                   
                   
                    if length(wbstruct.stimulus.switchtimes) > thisswitch

                        timecoloring(time2frame( wbstruct.tv, wbstruct.stimulus.switchtimes(thisswitch) )  : time2frame( wbstruct.tv, wbstruct.stimulus.switchtimes(thisswitch) ) + onsettime ) =1;
                   else

                        timecoloring(time2frame( wbstruct.tv, wbstruct.stimulus.switchtimes(thisswitch) )  : time2frame( wbstruct.tv, wbstruct.stimulus.switchtimes(thisswitch) ) + onsettime   )=1;

                   end        
                   
                   
                   
               end
               
               
               
               
            end
        end
    end
    
    
    
    
    




end