.pragma library

function step(min, max, count) {
  // Inspired by d3.js
  var span = max - min;
  var step = Math.pow(10, Math.floor(Math.log(span / count) / Math.LN10));
  var err = count / span * step;

    // Filter ticks to get closer to the desired count.
         if (err <= .35) step *= 10
    else if (err <= .75) step *= 5
    else if (err <= 1.0) step *= 2

  return step
}
