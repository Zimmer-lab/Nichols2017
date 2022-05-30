function handle=PopupBoxMsgUpdate(handle,msgString,position,name)

        if nargin<4
            name='Notification';
        end
        
        if nargin<3
            position=[500 500 300 100];
        end
        
        figure(handle);
        clf;
        annotation('textbox',[0.1 0.5 0.8 0.1],'String',msgString,'EdgeColor','none','HorizontalAlignment','center','FontSize',12);
        drawnow;
        
end