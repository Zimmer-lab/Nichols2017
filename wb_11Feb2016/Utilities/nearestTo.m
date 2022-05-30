function closestIndex=nearestTo(val,array)         

    [delta, closestIndex] = min(abs(array-val));

end