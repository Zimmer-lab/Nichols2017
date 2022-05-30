function handle=PopupBoxMsg(msgString,position,name)

        if nargin<3
            name='Notification';
        end
        
        if nargin<2
            position=[500 500 300 100];
        end
        
        handle=figure('Position',position,'MenuBar','none','name','Notification');
        
        annotation('textbox',[0.1 0.5 0.8 0.1],'String',msgString,'EdgeColor','none','HorizontalAlignment','center','FontSize',12);
        drawnow;
        
end