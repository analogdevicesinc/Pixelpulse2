// basic csv serialisation function 
// accepts a list of lists representing the columns of data, and a list of text labels
var dumpsample = function (columns, labels) {
   if (columns.length != labels.length) {
      throw("label length mismatches number of columns");
   }
   var lengths = columns.map(function(x) {return x.length;})
   var csvContent = '';
   for (var i = 0; i < labels.length; i++) {
       csvContent += labels[i] + ((i != (labels.length-1)) ? "," : "");
   }
   csvContent += "\n";
   var minimumLength = Math.min.apply(null, lengths);
   for (var i = 0; i < minimumLength; i++) {
       for (var j = 0; j < columns.length; j++) {
            csvContent += columns[j][i] + ((j != (columns.length-1)) ? "," : "");
        }
        csvContent += (i != (minimumLength-1) ? "\n" : "");
    }
   return csvContent
}
