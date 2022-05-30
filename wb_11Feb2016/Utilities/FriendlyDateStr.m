function str=FriendlyDateStr()

    str=strrep(strrep(datestr(now),':','-'),' ','-');

end