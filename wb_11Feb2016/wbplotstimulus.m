function wbplotstimulus(wbstruct,textFlag,lineColor,textHeight,style)

if nargin<2
    textFlag=false;
end

if nargin<3 || isempty(lineColor)
    lineColor=MyColor('lightgray');
end

if nargin<4 || isempty(textHeight)
    textHeight=0.2;
end

if nargin<5 || isempty(style)
    style='solid';
end
    

if nargin<1
    %default stimulus pattern
    wbstruct.stimulus.switchtimes=360:30:690;
    wbstruct.stimulus.conc=[21 4];
    wbstruct.stimulus.initialstate=1;
end


if isfield(wbstruct,'stimulus') && ~isempty(wbstruct.stimulus)
    if isfield(wbstruct.stimulus,'ch')
        for thisswitch=1:length(wbstruct.stimulus.ch(1).switchtimes)
            
           if strcmp(style,'solid')
               if mod(thisswitch,2)==1
                   yl=get(gca,'YLim');
                   rectangle('Position',[wbstruct.stimulus.ch(1).switchtimes(thisswitch)   yl(1) ...
                     wbstruct.stimulus.ch(1).switchtimes(thisswitch+1)-wbstruct.stimulus.ch(1).switchtimes(thisswitch)    yl(2)-yl(1)  ],'EdgeColor','none',...
                     'FaceColor',lineColor);
               end
           else
               vline(wbstruct.stimulus.ch(1).switchtimes(thisswitch),lineColor);
           end
           
           numconclevels=length(wbstruct.stimulus.ch(1).conc);
           thisconcval=wbstruct.stimulus.ch(1).conc(1+mod(wbstruct{1}.stimulus.ch(1).initialstate+thisswitch-1, numconclevels));
           if textFlag
            text(wbstruct.stimulus.ch(1).switchtimes(thisswitch),textHeight,['  ' num2str(thisconcval) ' ' wbstruct.stimulus.ch(1).concunits ' ' wbstruct.stimulus.ch(1).identity],'Color',[0.5 0.5 0.5],'FontSize',12);
           end

        end
    else  %for stimulus with no channel info
        for thisswitch=1:length(wbstruct.stimulus.switchtimes)
            
            
           if strcmp(style,'solid')
               if mod(thisswitch,2)==1
                   yl=get(gca,'YLim');
                   rectangle('Position',[wbstruct.stimulus.switchtimes(thisswitch)   yl(1) ...
                     wbstruct.stimulus.switchtimes(thisswitch+1)-wbstruct.stimulus.switchtimes(thisswitch)   yl(2)-yl(1)  ],'EdgeColor','none',...
                     'FaceColor',lineColor);
               end
           else
               vline(wbstruct.stimulus.switchtimes(thisswitch),lineColor);
           end
           
           numconclevels=length(wbstruct.stimulus.conc);
           thisconcval=wbstruct.stimulus.conc(1+mod(wbstruct.stimulus.initialstate+thisswitch-1, numconclevels));
           if textFlag
            text(wbstruct.stimulus.switchtimes(thisswitch),textHeight,['  ' num2str(thisconcval) ' ' wbstruct.stimulus.concunits ' ' wbstruct.stimulus.identity],'Color',[0.5 0.5 0.5],'FontSize',12);
           end
        end
    end
end