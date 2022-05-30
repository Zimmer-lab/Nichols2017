function ReScroll(old_scroll_val)

   if nargin<1
       old_scroll_val=1;
   end
   
    
   %Get all the axes positions
   ax_hndl = findall(gcf,'Type','axes');
   for i = length(ax_hndl):-1:1,
       a_pos(i,:) = get(ax_hndl(i),'position');
   end
   pos_y_range = [min(.07,min(a_pos(:,2))) max(a_pos(:,2) + a_pos(:,4) )+.07-.9];

   %compute and set new axis positions
   ypos = (1-old_scroll_val)*diff(pos_y_range);  
   for i2 = 1:length(ax_hndl),
      cp=get(ax_hndl(i2),'position');
      set(ax_hndl(i2),'position', [cp(1) ypos+a_pos(i2,2) cp(3) cp(4)]);
   end
   
   %update scroll bar
   scroll_hndl = findall(gcf,'Type','uicontrol','Tag','scroll');
   if ~isempty(scroll_hndl)
       set(scroll_hndl,'Value',old_scroll_val);
   end
   
   %drawnow;



end