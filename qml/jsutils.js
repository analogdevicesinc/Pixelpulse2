/**
 * From http://stackoverflow.com/questions/13861254/json-stringify-deep-objects, post by Gili.
 * Modified for integration with QML by Ian Daniher, 03/26/15.
 * Returns the JSON representation of an object.
 *
 * @param {value} object the object
 * @param {number} objectMaxDepth for objects, the maximum number of times to recurse into descendants
 * @param {number} arrayMaxLength for arrays, the maximum number of elements to enumerate
 * @param {string} indent the string to use for indentation
 * @return {string} the JSON representation
 */
var request = function (url, callback) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = (function(myxhr) {
        return function() {
             if(myxhr.readyState === 4) callback(myxhr)
	    }
    })(xhr);
    xhr.open('GET', url, true);
    xhr.send('');
}

var checkLatest = function (target) {
	var text;
    request("https://api.github.com/repos/analogdevicesinc/pixelpulse2/releases", function(t) {
        var d = JSON.parse(t.responseText)[0];
        text = "The most recent release is " + d.tag_name + ", published at " + (new Date(d.published_at)).toString() + "." + '\n\n' + "It is available for download at " + d.html_url + ".";
		target.text += text;
    });
	return '\n\n\n'
}

var checkLatestFw = function (callback) {
	var text;
    request("https://api.github.com/repos/analogdevicesinc/m1k-fw/releases", function(t) {
        var d = JSON.parse(t.responseText)[0];
        callback(d.tag_name);
    //    callback('v2.02');
    });
	return '\n\n\n'
}

var requestFile = function(url, callback) {
    var xhr = new XMLHttpRequest();
    console.log('LOG: url: ', url);

    xhr.onloadstart = (function(myxhr) {
        return function() {
            console.log('LOG: onloadstart: ', myxhr.status);
        }
    })(xhr);
    xhr.onprogress = (function(myxhr) {
        return function() {
            console.log('LOG: progress: ', myxhr.status);
        }
    })(xhr);
    xhr.onerror = (function(myxhr) {
        return function() {
            console.log('LOG: error: ', myxhr.status);
        }
    })(xhr);
    xhr.ontimeout = (function(myxhr) {
        return function() {
            console.log('LOG: timeout: ', myxhr.status);
        }
    })(xhr);
    xhr.onloadend = (function(myxhr) {
        return function() {
            console.log('LOG: onloadend: ', myxhr.status);
        }
    })(xhr);
    xhr.onreadystatechange = (function(myxhr) {
        return function() {
            if(myxhr) console.log('LOG: status ready: ', myxhr.readyState);//if(myxhr.readyState === 4)
            if(myxhr.readyState === 4 && myxhr.status  === 200) callback(myxhr)
	    }
    })(xhr);

    xhr.onload = (function(myxhr) {
        return function() {
            console.log('LOG: status load: ', myxhr.status);
             if(myxhr.status  === 200) callback(myxhr)
	    }
    })(xhr);
    xhr.open('GET', url, true);
	//xhr.responseType = "arraybuffer";
    xhr.send('');
}

var getFirmwareURL = function(callback) {
	var releaseURL = 'https://api.github.com/repos/analogdevicesinc/m1k-fw/releases';
	console.log('LOG: releaseURL: ', releaseURL);

	request(releaseURL, function(t) {
        var d = JSON.parse(t.responseText)[0];
        var id = d.id;
		var releaseAssetURL = releaseURL + '/' + id + '/assets';
		console.log('LOG: releaseAssetURL: ', releaseAssetURL);

		request(releaseAssetURL, function(t) {
			var d = JSON.parse(t.responseText)[0];
			//var fileDownloadURL = "https://github-cloud.s3.amazonaws.com/releases/26525695/3fe901bc-7d73-11e5-8c12-7b3a65a3415a.bin?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAISTNZFOVBIJMK3TQ%2F20151120%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20151120T171256Z&X-Amz-Expires=300&X-Amz-Signature=910d228f306a836ce95e930d4533713fd11019db6e224ef06636b07295384979&X-Amz-SignedHeaders=host&actor_id=0&response-content-disposition=attachment%3B%20filename%3Dm1000.bin&response-content-type=application%2Foctet-stream";//d.browser_download_url;
            var fileDownloadURL = d.browser_download_url;
			console.log('LOG: fileDownloadURL: ', fileDownloadURL);

			request(fileDownloadURL, function(t) {
				console.log('LOG: The response was received!');
				var header = t.getResponseHeader('Location');
                console.log('LOG: Response ', header);
                callback(header);
			});
		});
	});
};

var toJSON = function(object, objectMaxDepth, arrayMaxLength, indent)
{
    "use strict";

    /**
     * Escapes control characters, quote characters, backslash characters and quotes the string.
     *
     * @param {string} string the string to quote
     * @returns {String} the quoted string
     */
    function quote(string)
    {
        escapable.lastIndex = 0;
        var escaped;
        if (escapable.test(string))
        {
            escaped = string.replace(escapable, function(a)
            {
                var replacement = replacements[a];
                if (typeof (replacement) === "string")
                    return replacement;
                // Pad the unicode representation with leading zeros, up to 4 characters.
                return "\\u" + ("0000" + a.charCodeAt(0).toString(16)).slice(-4);
            });
        }
        else
            escaped = string;
        return "\"" + escaped + "\"";
    }

    /**
     * Returns the String representation of an object.
     * 
     * Based on <a href="https://github.com/Canop/JSON.prune/blob/master/JSON.prune.js">https://github.com/Canop/JSON.prune/blob/master/JSON.prune.js</a>
     *
     * @param {string} path the fully-qualified path of value in the JSON object
     * @param {type} value the value of the property
     * @param {string} cumulativeIndent the indentation to apply at this level
     * @param {number} depth the current recursion depth
     * @return {String} the JSON representation of the object, or "null" for values that aren't valid
     * in JSON (e.g. infinite numbers).
     */
    function toString(path, value, cumulativeIndent, depth)
    {
        switch (typeof (value))
        {
            case "string":
                return quote(value);
            case "number":
                {
                    // JSON numbers must be finite
                    if (isFinite(value))
                        return String(value);
                    return "null";
                }
            case "boolean":
                return String(value);
            case typeof(function(){}): 
            case "object":
                {
                    /*if (!value)
                        return "null";*/
                    var valueIndex = values.indexOf(value);
                    if (valueIndex !== -1)
                        return "Reference => " + paths[valueIndex];
                    values.push(value);
                    paths.push(path);
                    if (depth > objectMaxDepth)
                        return "...";

                    // Make an array to hold the partial results of stringifying this object value.
                    var partial = [];

                    // Is the value an array?
                    var i;
                    if (value.length)
                    {
                        // The value is an array. Stringify every element
                        var length = Math.min(value.length, arrayMaxLength);

                        // Whether a property has one or multiple values, they should be treated as the same
                        // object depth. As such, we do not increment the object depth when recursing into an
                        // array.
                        for (i = 0; i < length; ++i)
                        {
                            partial[i] = toString(path + "." + i, value[i], cumulativeIndent + indent, depth,
                                arrayMaxLength);
                        }
                        if (i < value.length)
                        {
                            // arrayMaxLength reached
                            partial[i] = "...";
                        }
                        return "\n" + cumulativeIndent + "[" + partial.join(", ") + "\n" + cumulativeIndent +
                            "]";
                    }

                    // Otherwise, iterate through all of the keys in the object.
                    for (var subKey in value)
                    {
                        if (Object.prototype.hasOwnProperty.call(value, subKey) & (subKey != "parent") & (typeof(value[subKey] != "function")))
                        {
                            var subValue;
                            try
                            {
                                subValue = toString(path + "." + subKey, value[subKey], cumulativeIndent + indent,
                                    depth + 1);
                                partial.push(quote(subKey) + ": " + subValue);
                            }
                            catch (e)
                            {
                                // this try/catch due to forbidden accessors on some objects
                                if (e.message)
                                    subKey = e.message;
                                else
                                    subKey = "access denied";
                            }
                        }
                        if (typeof(value[subKey] != "function"))
                        {
                            partial.push(quote(subKey) +": "+ value[subKey].toString());
                        }
                    }
                    var result = "\n" + cumulativeIndent + "{\n";
                    for (i = 0; i < partial.length; ++i)
                        result += cumulativeIndent + indent + partial[i] + ",\n";
                    if (partial.length > 0)
                    {
                        // Remove trailing comma
                        result = result.slice(0, result.length - 2) + "\n";
                    }
                    result += cumulativeIndent + "}";
                    return result;
                }
            default:
                return "null";
        }
    }

    if (indent === undefined)
        indent = "  ";
    if (objectMaxDepth === undefined)
        objectMaxDepth = 0;
    if (arrayMaxLength === undefined)
        arrayMaxLength = 50;
    // Matches characters that must be escaped
    var escapable =
        /[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g;
    // The replacement characters
    var replacements =
        {
            "\b": "\\b",
            "\t": "\\t",
            "\n": "\\n",
            "\f": "\\f",
            "\r": "\\r",
            "\"": "\\\"",
            "\\": "\\\\"
        };
    // A list of all the objects that were seen (used to avoid recursion)
    var values = [];
    // The path of an object in the JSON object, with indexes corresponding to entries in the
    // "values" variable.
    var paths = [];
    return toString("root", object, "", 0);
};
