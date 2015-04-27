// basic csv serialisation function
// accepts a list of lists representing the columns of data, and a list of text labels
var dumpSamples = function (columns, labels) {
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
            var x = columns[j][i].toFixed(4);
            x = (x == 0) ? (0.00001).toFixed(4) : x;
            csvContent += (x >= 0 ? "+" : "") + x + ((j != (columns.length-1)) ? "," : "");
        }
        csvContent += (i != (minimumLength-1) ? "\n" : "");
    }
   return csvContent
}

var saveData = function () {
    var labels = [];
    var columns = [];
    if (session.devices) {
        for (var i = 0; i < session.devices.length; i++) {
            for (var j = 0; j < session.devices[i].channels.length; j++) {
                for (var k = 0; k < session.devices[i].channels[i].signals.length; k++) {
                    var label = '' + i + session.devices[i].channels[j].label +"_"+ session.devices[i].channels[j].signals[k].label;
                    labels.push(label);
                    columns.push(session.devices[i].channels[j].signals[k].buffer.getData());
                };
            };
        };
    fileio.writeByURI(fileDialog.fileUrls[0], dumpSamples(columns, labels));
    };
};

