function cdata = png_cdata(hfig)
%subfunction for rendering movie frame from figure

    % Get CDATA from hardcopy using opengl
    % Need to have PaperPositionMode be auto 
    orig_mode = get(hfig, 'PaperPositionMode');
    set(hfig, 'PaperPositionMode', 'auto');
    cdata = hardcopy(hfig, '-Dopengl', '-r0');
    % Restore figure to original state
    set(hfig, 'PaperPositionMode', orig_mode);
end
