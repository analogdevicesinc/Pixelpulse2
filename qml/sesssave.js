var saveState = function () {
	var signalStates = {};
	for (var a = 0; a < deviceRepeater.count; a++){
		var deviceItem = deviceRepeater.itemAt(a);
		for (var b = 0; b < deviceItem.channelRepeater.count; b++){
			var channelItem = deviceItem.channelRepeater.itemAt(b);
			var channel = channelItem.channel;
			for (var c = 0; c < channelItem.signalRepeater.count; c++) {
				var label = '' + a + session.devices[a].channels[b].label +"_"+ session.devices[a].channels[b].signals[c].label;
				var signalState = {};
				var signalItem = channelItem.signalRepeater.itemAt(c);
				var signal = signalItem.signal;
				signalState.src = signal.src.src;
				signalState.v1 = signal.src.v1;
				signalState.v2 = signal.src.v2;
				signalState.period = signal.src.period;
				signalState.phase = signal.src.phase;
				signalState.duty = signal.src.duty;
				signalState.xscale = signalItem.xaxis.xscale;
				signalState.ymin = signalItem.ymin;
				signalState.ymax = signalItem.ymax;
                signalState.mode = channel.mode;
				signalStates[label] = signalState;
			}
		}
	}
    var generalState = {}
    generalState.signalCheckBox = toolbar.colorDialog.sigCheckBox.checked;
    generalState.plotsCheckBox = toolbar.colorDialog.plotCheckBox.checked;
    generalState.sliderBrightness = toolbar.colorDialog.sliderB.value;
    generalState.sliderContrast = toolbar.colorDialog.sliderC.value;
    generalState.sliderPhosphor = toolbar.colorDialog.sliderPh.value;
    generalState.sliderDotSize = toolbar.colorDialog.sliderDot.value;
    generalState.xy_checked = plotsVisibleItem.checked;
    signalStates['generalSettings'] = generalState;
	return signalStates;
};


var restoreState = function (signalStates){
	for (var a = 0; a < deviceRepeater.count; a++){
		var deviceItem = deviceRepeater.itemAt(a);
		for (var b = 0; b < deviceItem.channelRepeater.count; b++){
			var channelItem = deviceItem.channelRepeater.itemAt(b);
			var channel = channelItem.channel;
			for (var c = 0; c < channelItem.signalRepeater.count; c++) {
				var label = '' + a + session.devices[a].channels[b].label +"_"+ session.devices[a].channels[b].signals[c].label;
				var signalItem = channelItem.signalRepeater.itemAt(c);
				var signalState = signalStates[label];
				var signal = signalItem.signal;
				channel.mode = signalState.mode;
				signal.src.src = signalState.src;
				signal.src.v1 = signalState.v1;
				signal.src.v2 = signalState.v2;
				signal.src.period = signalState.period;
                signal.src.phase = signalState.phase;
				signal.src.duty = signalState.duty;
				signalItem.ymin = signalState.ymin;
                signalItem.ymax = signalState.ymax;
			}
		}
	}
    var generalState = signalStates['generalSettings']
    toolbar.colorDialog.sigCheckBox.checked = generalState.signalCheckBox;
    toolbar.colorDialog.plotCheckBox.checked = generalState.plotsCheckBox;
    toolbar.colorDialog.sliderB.value = generalState.sliderBrightness;
    toolbar.colorDialog.sliderC.value = generalState.sliderContrast;
    toolbar.colorDialog.sliderPh.value = generalState.sliderPhosphor;
    toolbar.colorDialog.sliderDot.value = generalState.sliderDotSize;
    plotsVisibleItem.checked = generalState.xy_checked;
}
