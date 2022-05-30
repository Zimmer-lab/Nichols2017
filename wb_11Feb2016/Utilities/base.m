function base(varstring,var)
%function base(varstring,var)
    if nargin<2
        assignin('base',varstring,evalin('caller',varstring));
    else
        assignin('base',varstring,var);
    end
       
end