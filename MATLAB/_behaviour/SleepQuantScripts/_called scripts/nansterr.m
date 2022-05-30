%calculates standard error from array containing NaN values
%08/22/07 Manuel Zimmer

function standarderror=nansterr(inputarray)


standarderror=nanstd(inputarray)./sqrt(sum(isfinite(inputarray)));