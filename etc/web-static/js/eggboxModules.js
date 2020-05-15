"use strict";

// ---- Pod Dependency Graph ----------------------------------------------------------------------

define("onReveal", ["jquery"], function ($) {
	return function(div, func) {
		$(document).ready(function () {
			var $div = $(div);
			if ($div.size() > 0 ) {

				var revealed = false;
				var divTop = $div.offset().top;
				var revealCheck = function () {
					if (!revealed && $(window).scrollTop() + $(window).height() > divTop) {
						revealed = true;
						func();
					}
				};

				$(window).scroll(revealCheck);
				revealCheck();
			}
		});
	}
});

define("podGraph", ["d3", "jquery", "onReveal", "debounce"], function(d3, $, onReveal, debounce) {
	return function(thePod, links) {
		onReveal(".dependencyGraph", function() { boing(thePod, links) });
	}

	function boing(thePod, links) {

		// based on http://bl.ocks.org/mbostock/1153292
		var nodes = {};

		// Compute the distinct nodes from the links.
		links.forEach(function(link) {
			link.source = nodes[link.source] || (nodes[link.source] = {name: link.source});
			link.target = nodes[link.target] || (nodes[link.target] = {name: link.target});
		});

		// add the css styles
		links.forEach(function(link) {
			if (link.css !== "") nodes[link.target.name].css = link.css;
		});
		nodes[thePod].css = "thisPod";

		var width  = d3.select(".dependencyGraph").node().getBoundingClientRect().width;
		var height = 300;

		var force = d3.layout.force()
			.nodes(d3.values(nodes))
			.links(links)
			.size([width, height])
			.linkDistance(90)
			.charge(-1000)
			.on("tick", tick)
			.start();

		var svg = d3.select(".dependencyGraph").append("svg")
			.attr("width", width)
			.attr("height", height);

		// define the arrow head
		svg.append("defs").selectAll("marker")
			.data(["end"])
			.enter()
			.append("marker")
			.attr("id", function(d) { return d; })
			.attr("viewBox", "0 -5 10 10")
			.attr("refX", 30)
			.attr("refY", 0)
			.attr("markerWidth", 6)
			.attr("markerHeight", 6)
			.attr("orient", "auto")
			.append("path")
			.attr("d", "M0,-5L10,0L0,5");

		// convert links to svg
		var link = svg.append("g").selectAll("line")
			.data(force.links())
			.enter().append("line")
			.attr("class", "link")
			.attr("marker-end", "url(#end)");

		// convert nodes to svg circles
		var node = svg.append("g").selectAll("circle")
			.data(force.nodes())
			.enter().append("circle")
			.attr("r", 16)
			.attr("class", function(d) { return d.css; })
			.call(force.drag);

		// convert nodes to svg text labels
		var text = svg.append("g").selectAll("text")
			.data(force.nodes())
			.enter().append("text")
			.attr("x", 8)
			.attr("y", ".31em")
			.text(function(d) { return d.name; });

		// http://stackoverflow.com/a/16135837/1532548
		var isIe = navigator.appVersion.indexOf("MSIE 10") !== -1;
		if (!isIe)
			isIe = navigator.userAgent.indexOf("Trident") !== -1 && navigator.userAgent.indexOf("rv:11") !== -1;

		// this tick() func is run on every, um, tick!
		function tick() {
			// obligatory hack for IE
			// see http://stackoverflow.com/a/18475039/1532548
			if (isIe)
				link.each(function() {
					this.parentNode.insertBefore(this, this);
				});

			node.attr("transform", transform);
			text.attr("transform", transform);

			link.attr("x1", function(d) { return d.source.x; })
				.attr("y1", function(d) { return d.source.y; })
				.attr("x2", function(d) { return d.target.x; })
				.attr("y2", function(d) { return d.target.y; });
		}

		function transform(d) {
			return "translate(" + d.x + "," + d.y + ")";
		}

		$(window).on('resize', $.debounce(200, resizeGraph));
		function resizeGraph() {
			var width  = d3.select(".dependencyGraph").node().getBoundingClientRect().width;
			svg.attr("width", width);
			force.size([width, height]).resume();	// perturb the graph on resize
		}
	}
});


// ---- Unscramble Module -------------------------------------------------------------------------

define("unscramble", [], function() {

	var randomise = function (strLength) {
		var text = "";
    	var possible = "!#$%()*+-/:=?@~ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%()*+-/:=?@~";
    	for( var i=0; i < strLength; i++ )
    	    text += possible.charAt(Math.floor(Math.random() * possible.length));
    	return text;
	}

	var countdown = function (element, secret, cnt) {
		var text = secret.substr(0, cnt) + randomise(secret.length - cnt);
		element.innerHTML = text;
		element.href = "mailto:" + text;
		if (cnt++ <= secret.length)
			setTimeout(function() {
				countdown(element, secret, cnt);
			}, 100);
	};

	return function(elementId) {
		var element = document.getElementById(elementId);
		var secret = element.getAttribute("data-unscramble").split("").reverse().join("");
		countdown(element, secret, 0);
	};
});



// ---- Pod Page Pod Filtering --------------------------------------------------------------------

define("podFiltering", ["jquery", "tinysort", "debounce"], function($, tinysort, debounce) {

	// TODO: should refactor this to have a model
	$(document).ready(function() {

		var $btnSortByName	= $("#sortByName");
		var $btnSortByDate	= $("#sortByDate");
		var $tags   		= $("#tags");
		var $searchBox 		= $("#searchBox");
		var $searchGo		= $("#searchGo");
		var allTags 		= ($tags.attr("data-allTags") + " tag-none-active").trim().split(" ");

		function encodeUrl(all, none) {
			var query = "";
			if ($btnSortByName.hasClass("active"))
				query = "?sortByName=true";

			// 'sortByDate' is the default, so just don't inlcude it in the URL
			//if ($btnSortByDate.hasClass("active"))
			//	query = "?sortByDate=true";

			var tags = [];
			if (all || none) {
			// 'all' is the default, so just don't inlcude it in the URL
			//	if (all === true)
			//		tags.push("all");
				if (none === true)
					tags.push("none");
			} else {
				var allActive = true;
				var activeTags = $tags.attr("class").split(" ");
				$.each(allTags, function(i, tag) {
					if ($.inArray(tag, activeTags) > -1)
						tags.push(tag.slice(4, -7));
					else
						allActive = false;
				});
				if (allActive)
					// 'all' is the default, so just don't inlcude it in the URL
					tags.length = 0;
			}
			if (tags.length > 0) {
				query += (query === "") ? "?" : "&";
				query += "tags=";
				$.each(tags, function(i, val) {
					if (i > 0)
						query += ",";
					query += val;
				});
			}

			var searchBoxVal = $searchBox.val().trim();
			if (searchBoxVal !== "") {
				query += (query === "") ? "?" : "&";
				query += "q=" + encodeURIComponent(searchBoxVal);
			}

			query += (query === "") ? "?" : "";
			history.replaceState({}, "", query);
		}

		function decodeUrl() {
			// see http://stackoverflow.com/a/2880929/1532548
			var match,
				pl     = /\+/g,  // Regex for replacing '+' symbol with a ' '
				search = /([^&=]+)=?([^&]*)/g,
				decode = function (s) { return decodeURIComponent(s.replace(pl, " ")); },
				query  = window.location.search.substring(1),
				params = {};
			while (match = search.exec(query))
				params[decode(match[1])] = decode(match[2]);

			if (params["sortByName"] === "true")
				sortByName();
			if (params["sortByDate"] === "true")
				sortByDate();
			if (!params["tags"] || params["tags"] === "all") {
				$.each(allTags, function(i, tag) {
					$tags.addClass(tag);
				});
			} else {
				$.each(allTags, function(i, tag) {
					$tags.removeClass(tag);
				});
				if (params["tags"] !== "none") {
					$.each(params["tags"].split(","), function (i, val) {
						$tags.addClass("tag-" + val + "-active");
					});
				}
			}
			if (params["q"]) {
				$searchBox.val(params["q"])
				filterPods();
			}
		}

		function sortByName() {
			$btnSortByName.addClass("active");
			$btnSortByDate.removeClass("active");
			tinysort(".podList > .media", {data:"name"});
		}

		function sortByDate() {
			$btnSortByDate.addClass("active");
			$btnSortByName.removeClass("active");
			tinysort(".podList > .media", {data:"date", order:"desc"});
		}

		function filterPods() {
			var searchTerm = $searchBox.val().trim().toLowerCase();
			if (searchTerm === "")
				$tags.removeClass("search-active");
			else
				$tags.addClass("search-active");

			var exactMatch = false;
			$(".podList > .media").each(function() {
				var $this = $(this);
				if ($this.data("name").toLowerCase().indexOf(searchTerm) > -1)
					$this.removeClass("search-notFound");
				else
					$this.addClass("search-notFound");

				if ($this.data("name").toLowerCase() === searchTerm)
					exactMatch = true;
			});

			if (exactMatch) {
				$searchGo.removeClass("btn-default");
				$searchGo.addClass("btn-primary");
				$searchGo.prop("disabled", false);
			} else {
				$searchGo.removeClass("btn-primary");
				$searchGo.addClass("btn-default");
				$searchGo.prop("disabled", true);
			}

			encodeUrl(false, false);
		}

		function submitSearch() {
			var searchTerm	= $searchBox.val().trim().toLowerCase();
			var podName		= null;

			$(".podList > .media").each(function() {
				var $this = $(this);
				if ($this.data("name").toLowerCase() === searchTerm)
					podName = $this.data("podname");
			});

			if (podName != null)
				window.location.href = "/pods/" + encodeURIComponent(podName);
		}

		$(window).on("popstate", function() {
			decodeUrl();
		});

		$btnSortByName.on("click", function(event) {
			sortByName();
			encodeUrl(false, false);
			return false;
		});
		$btnSortByDate.on("click", function(event, element) {
			sortByDate();
			encodeUrl(false, false);
			return false;
		});

		$tags.on("click", ".tag", function(event) {
			var $tag 	= $(event.target).closest(".tag");
			var tagName	= null;	// --> tag-web
			$.each($tag.attr("class").split(" "), function(i, val) {
				// check tag value to prevent "all" from triggering it
				if (val.indexOf("tag-") === 0 && allTags.indexOf(val + "-active") > -1) {
					tagName = val;
				}
			});
			if (tagName != null) {
				$.each(allTags, function(i, tag) {
					$tags.removeClass(tag);
				});
				$tags.addClass(tagName + "-active");
				encodeUrl(false, false);
			}
		});

		// do this in JS because  tags are only buttons on the All Pods page
		$.each(allTags, function(i, val) {
			var tagName = val.slice(4, -7);
			$(".tag." + val.slice(0, -7)).attr("title", "Show '" + tagName + "' pods");
		});

		$("#btnAllTags").on("click", function(event) {
			$.each(allTags, function(i, tag) {
				$tags.addClass(tag);
			});
			encodeUrl(true, false);
		});

		$searchBox.on("input", $.debounce(100, filterPods));

		$("#searchForm").submit(function(event) {
			event.preventDefault();
			submitSearch();
		});

		// kick off Pod sorting on page load
		decodeUrl();

		// the stoopid IE dropbox takes up most of the page!
		var ua		= window.navigator.userAgent;
		var msie	= ua.indexOf('MSIE ') > 0;
		var trident = ua.indexOf('Trident/') > 0;
		var edge	= ua.indexOf('Edge/') > 0;
		if (!msie && !trident && !edge) {
			$searchBox.focus();
			$searchBox.select();
		}
	});
});



// ---- Index Page Pod Search ---------------------------------------------------------------------

define("podSearch", ["jquery", "debounce"], function($, debounce) {

	$(document).ready(function() {

		var $searchBox 		= $("#searchBox");
		var $searchGo		= $("#searchGo");
		var allProjNames	= [];

		$("#projNames option").each(function() {
			allProjNames.push(this.getAttribute("value"));
		});

		function filterPods() {
			var searchTerm = $searchBox.val().trim().toLowerCase();

			var exactMatch = false;
			$.each(allProjNames, function(i, val) {
				if (val.toLowerCase() == searchTerm)
					exactMatch = true;
			});

			$searchGo.prop("disabled", searchTerm === "");

			if (exactMatch) {
				$searchGo.removeClass("btn-default");
				$searchGo.addClass("btn-primary");
			} else {
				$searchGo.removeClass("btn-primary");
				$searchGo.addClass("btn-default");
			}
		}

		function submitSearch() {
			var searchTerm	= $searchBox.val().trim().toLowerCase();
			var podName		= null;

			$("#projNames option").each(function() {
				var $this = $(this);
				if ($this.val().toLowerCase() === searchTerm)
					podName = $this.data("podname");
			});

			if (podName != null)
				window.location.href = "/pods/" + encodeURIComponent(podName);
			else
				window.location.href = "/pods/?q=" + encodeURIComponent(searchTerm);
		}

		$searchBox.on("input", $.debounce(100, filterPods));

		$("#searchForm").submit(function(event) {
			event.preventDefault();
			submitSearch();
		});

		// the stoopid IE dropbox takes up most of the page!
		var ua		= window.navigator.userAgent;
		var msie	= ua.indexOf('MSIE ') > 0;
		var trident = ua.indexOf('Trident/') > 0;
		var edge	= ua.indexOf('Edge/') > 0;
		if (!msie && !trident && !edge) {
			$searchBox.focus();
			$searchBox.select();
		}
		filterPods();
	});
});



// ---- TableSort ---------------------------------------------------------------------------------

define("tableSort", ["tinysort"], function(tinysort) {

	return function(tableId) {
		var table = document.getElementById(tableId)
			,tableHead    = table.querySelector('thead')
			,tableHeaders = tableHead.querySelectorAll('th')
			,tableBody    = table.querySelector('tbody')
		;
		tableHead.addEventListener('click',function(e){
			var tableHeader  = e.target
				,textContent = tableHeader.textContent
				,tableHeaderIndex,isAscending,order
			;
			if (textContent!=='add row') {
				while (tableHeader.nodeName!=='TH') {
					tableHeader = tableHeader.parentNode;
				}
				tableHeaderIndex = Array.prototype.indexOf.call(tableHeaders,tableHeader);
				isAscending = tableHeader.getAttribute('data-order')==='asc';
				order = isAscending?'desc':'asc';
				tableHeader.setAttribute('data-order',order);
				tinysort(
					tableBody.querySelectorAll('tr')
					,{
						selector:'td:nth-child('+(tableHeaderIndex+1)+')'
						,order: order
					}
				);
			}
		});
	}
});



// ---- NotFound ---------------------------------------------------------------------------------

define("notFound", ["jquery"], function($) {
	var $body	= $(".glow");
	var speed	= 100;
	var time	= 0;

	function rgbToHex(R,G,B) {return toHex(R)+toHex(G)+toHex(B)}
	function toHex(n) {
		n = parseInt(n,10);
		if (isNaN(n)) return "00";
		n = Math.max(0,Math.min(n,255));
		return "0123456789ABCDEF".charAt((n-n%16)/16) + "0123456789ABCDEF".charAt(n%16);
	}

	// https://github.com/danro/jquery-easing/blob/master/jquery.easing.js
	// t: current time, b: start value, c: end value, d: total time
	var easeInOutBack = function (t, b, c, d, s) {
		if (s == undefined) s = 1.70158;
		if ((t/=d/2) < 1) return c/2*(t*t*(((s*=(1.525))+1)*t - s)) + b;
		return c/2*((t-=2)*t*(((s*=(1.525))+1)*t + s) + 2) + b;
	};

	var pulse = function() {
		time += speed;
		if (time > 3000 || time < 0) {
			speed = -speed;
			time  += speed;
		}
		var size = easeInOutBack(time, 75, 175, 3000);

		var r = 0x20 * size / 250;
		var g = 0xEE * size / 250;
		var b = 0x23 * size / 250;
		var c = "#"+rgbToHex(r,g,b);
		$body.css({ background: c })
	};

	$(document).ready(function() {
		setInterval(pulse, 100);
	});

	var hive = document.getElementsByClassName("hive")[0];
	var pageX, pageY, x, y, dx, dy;
	var maxTiltAngle = 30;

	$("body").on("mousemove", function(e) {
		pageX = e.pageX;
		pageY = e.pageY;

		x  = (pageX - hive.offsetLeft - (hive.offsetWidth  / 2)) / 4;
		y  = (pageY - hive.offsetTop  - (hive.offsetHeight / 2)) / 4;

		dx = -x % 202;
		dy = -y % 229;

		hive.style.backgroundPosition = dx + "px " + dy + "px";
	})
});



// ---- HiveSparks --------------------------------------------------------------------------------

define("hiveSparks", ["jquery"], function($) {
	var $spark	= $(".hive-spark.go")[0];
	var speed	= 100;
	var time	= 0;
	var sparkX	= 0;
	var speedX	= 5;

	// https://github.com/danro/jquery-easing/blob/master/jquery.easing.js
	// t: current time, b: start value, c: end value, d: total time
	var easeInOutBack = function (t, b, c, d, s) {
		if (s == undefined) s = 1.70158;
		if ((t/=d/2) < 1) return c/2*(t*t*(((s*=(1.525))+1)*t - s)) + b;
		return c/2*((t-=2)*t*(((s*=(1.525))+1)*t + s) + 2) + b;
	};

	var pulse = function() {
		time += speed;
		if (time > 3000 || time < 0) {
			speed = -speed;
			time  += speed;
		}
		var size = easeInOutBack(time, 0, 50+20, 3000) - (50+(20/2));

		$spark.style.top  = size + "px";
		$spark.style.left = sparkX + "px";

		sparkX += speedX;
		if (sparkX > $(document).width())
			sparkX = 0;
	};

	$(document).ready(function() {
		setInterval(pulse, 100);
	});
});



// ---- AnchorJS Module ---------------------------------------------------------------------------

define("anchorJS", [], function() {

/*!
 * AnchorJS - v1.1.1 - 2015-05-23
 * https://github.com/bryanbraun/anchorjs
 * Copyright (c) 2015 Bryan Braun; Licensed MIT
 */
function AnchorJS(A){"use strict";this.options=A||{},this._applyRemainingDefaultOptions=function(A){this.options.icon=this.options.hasOwnProperty("icon")?A.icon:"&#xe9cb",this.options.visible=this.options.hasOwnProperty("visible")?A.visible:"hover",this.options.placement=this.options.hasOwnProperty("placement")?A.placement:"right",this.options.class=this.options.hasOwnProperty("class")?A.class:""},this._applyRemainingDefaultOptions(A),this.add=function(A){var e,t,o,n,i,s,a,l,c,r,h,g,B,Q;if(this._applyRemainingDefaultOptions(this.options),A){if("string"!=typeof A)throw new Error("The selector provided to AnchorJS was invalid.")}else A="h1, h2, h3, h4, h5, h6";if(e=document.querySelectorAll(A),0===e.length)return!1;for(this._addBaselineStyles(),t=document.querySelectorAll("[id]"),o=[].map.call(t,function(A){return A.id}),i=0;i<e.length;i++){if(e[i].hasAttribute("id"))n=e[i].getAttribute("id");else{s=e[i].textContent,a=s.replace(/[^\w\s-]/gi,"").replace(/\s+/g,"-").replace(/-{2,}/g,"-").substring(0,64).replace(/^-+|-+$/gm,"").toLowerCase(),r=a,c=0;do void 0!==l&&(r=a+"-"+c),l=o.indexOf(r),c+=1;while(-1!==l);l=void 0,o.push(r),e[i].setAttribute("id",r),n=r}h=n.replace(/-/g," "),g='<a class="anchorjs-link '+this.options.class+'" href="#'+n+'" aria-label="Anchor link for: '+h+'" data-anchorjs-icon="'+this.options.icon+'"></a>',B=document.createElement("div"),B.innerHTML=g,Q=B.childNodes,"always"===this.options.visible&&(Q[0].style.opacity="1"),"&#xe9cb"===this.options.icon&&(Q[0].style.fontFamily="anchorjs-icons",Q[0].style.fontStyle="normal",Q[0].style.fontVariant="normal",Q[0].style.fontWeight="normal"),"left"===this.options.placement?(Q[0].style.position="absolute",Q[0].style.marginLeft="-1em",Q[0].style.paddingRight="0.5em",e[i].insertBefore(Q[0],e[i].firstChild)):(Q[0].style.paddingLeft="0.375em",e[i].appendChild(Q[0]))}return this},this.remove=function(A){for(var e,t=document.querySelectorAll(A),o=0;o<t.length;o++)e=t[o].querySelector(".anchorjs-link"),e&&t[o].removeChild(e);return this},this._addBaselineStyles=function(){if(null===document.head.querySelector("style.anchorjs")){var A,e=document.createElement("style"),t=" .anchorjs-link {   opacity: 0;   text-decoration: none;   -webkit-font-smoothing: antialiased;   -moz-osx-font-smoothing: grayscale; }",o=" *:hover > .anchorjs-link, .anchorjs-link:focus  {   opacity: 1; }",n=' @font-face {   font-family: "anchorjs-icons";   font-style: normal;   font-weight: normal;   src: url(data:application/x-font-ttf;charset=utf-8;base64,AAEAAAALAIAAAwAwT1MvMg8SBTUAAAC8AAAAYGNtYXAWi9QdAAABHAAAAFRnYXNwAAAAEAAAAXAAAAAIZ2x5Zgq29TcAAAF4AAABNGhlYWQEZM3pAAACrAAAADZoaGVhBhUDxgAAAuQAAAAkaG10eASAADEAAAMIAAAAFGxvY2EAKACuAAADHAAAAAxtYXhwAAgAVwAAAygAAAAgbmFtZQ5yJ3cAAANIAAAB2nBvc3QAAwAAAAAFJAAAACAAAwJAAZAABQAAApkCzAAAAI8CmQLMAAAB6wAzAQkAAAAAAAAAAAAAAAAAAAABEAAAAAAAAAAAAAAAAAAAAABAAADpywPA/8AAQAPAAEAAAAABAAAAAAAAAAAAAAAgAAAAAAADAAAAAwAAABwAAQADAAAAHAADAAEAAAAcAAQAOAAAAAoACAACAAIAAQAg6cv//f//AAAAAAAg6cv//f//AAH/4xY5AAMAAQAAAAAAAAAAAAAAAQAB//8ADwABAAAAAAAAAAAAAgAANzkBAAAAAAEAAAAAAAAAAAACAAA3OQEAAAAAAQAAAAAAAAAAAAIAADc5AQAAAAACADEARAJTAsAAKwBUAAABIiYnJjQ/AT4BMzIWFxYUDwEGIicmND8BNjQnLgEjIgYPAQYUFxYUBw4BIwciJicmND8BNjIXFhQPAQYUFx4BMzI2PwE2NCcmNDc2MhcWFA8BDgEjARQGDAUtLXoWOR8fORYtLTgKGwoKCjgaGg0gEhIgDXoaGgkJBQwHdR85Fi0tOAobCgoKOBoaDSASEiANehoaCQkKGwotLXoWOR8BMwUFLYEuehYXFxYugC44CQkKGwo4GkoaDQ0NDXoaShoKGwoFBe8XFi6ALjgJCQobCjgaShoNDQ0NehpKGgobCgoKLYEuehYXAAEAAAABAACiToc1Xw889QALBAAAAAAA0XnFFgAAAADRecUWAAAAAAJTAsAAAAAIAAIAAAAAAAAAAQAAA8D/wAAABAAAAAAAAlMAAQAAAAAAAAAAAAAAAAAAAAUAAAAAAAAAAAAAAAACAAAAAoAAMQAAAAAACgAUAB4AmgABAAAABQBVAAIAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAADgCuAAEAAAAAAAEADgAAAAEAAAAAAAIABwCfAAEAAAAAAAMADgBLAAEAAAAAAAQADgC0AAEAAAAAAAUACwAqAAEAAAAAAAYADgB1AAEAAAAAAAoAGgDeAAMAAQQJAAEAHAAOAAMAAQQJAAIADgCmAAMAAQQJAAMAHABZAAMAAQQJAAQAHADCAAMAAQQJAAUAFgA1AAMAAQQJAAYAHACDAAMAAQQJAAoANAD4YW5jaG9yanMtaWNvbnMAYQBuAGMAaABvAHIAagBzAC0AaQBjAG8AbgBzVmVyc2lvbiAxLjAAVgBlAHIAcwBpAG8AbgAgADEALgAwYW5jaG9yanMtaWNvbnMAYQBuAGMAaABvAHIAagBzAC0AaQBjAG8AbgBzYW5jaG9yanMtaWNvbnMAYQBuAGMAaABvAHIAagBzAC0AaQBjAG8AbgBzUmVndWxhcgBSAGUAZwB1AGwAYQByYW5jaG9yanMtaWNvbnMAYQBuAGMAaABvAHIAagBzAC0AaQBjAG8AbgBzRm9udCBnZW5lcmF0ZWQgYnkgSWNvTW9vbi4ARgBvAG4AdAAgAGcAZQBuAGUAcgBhAHQAZQBkACAAYgB5ACAASQBjAG8ATQBvAG8AbgAuAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==) format("truetype"); }',i=" [data-anchorjs-icon]::after {   content: attr(data-anchorjs-icon); }";e.className="anchorjs",e.appendChild(document.createTextNode("")),A=document.head.querySelector('[rel="stylesheet"], style'),void 0===A?document.head.appendChild(e):document.head.insertBefore(e,A),e.sheet.insertRule(t,e.sheet.cssRules.length),e.sheet.insertRule(o,e.sheet.cssRules.length),e.sheet.insertRule(i,e.sheet.cssRules.length),e.sheet.insertRule(n,e.sheet.cssRules.length)}}}var anchors=new AnchorJS;

	return function(selector) {
		anchors.options.visible = "hover";
		anchors.options.placement = "right";
		anchors.add(selector);
	};
});


// ---- Debounce ----------------------------------------------------------------------------------

define("debounce", ["jquery"], function($) {

	/*
	 * jQuery throttle / debounce - v1.1 - 3/7/2010
	 * http://benalman.com/projects/jquery-throttle-debounce-plugin/
	 *
	 * Copyright (c) 2010 "Cowboy" Ben Alman
	 * Dual licensed under the MIT and GPL licenses.
	 * http://benalman.com/about/license/
	 */
	(function(b,c){var $=b.jQuery||b.Cowboy||(b.Cowboy={}),a;$.throttle=a=function(e,f,j,i){var h,d=0;if(typeof f!=="boolean"){i=j;j=f;f=c}function g(){var o=this,m=+new Date()-d,n=arguments;function l(){d=+new Date();j.apply(o,n)}function k(){h=c}if(i&&!h){l()}h&&clearTimeout(h);if(i===c&&m>e){l()}else{if(f!==true){h=setTimeout(i?k:l,i===c?e-m:e)}}}if($.guid){g.guid=j.guid=j.guid||$.guid++}return g};$.debounce=function(d,e,f){return f===c?a(d,e,false):a(d,f,e!==false)}})(window);
});



// ---- File Input Module -------------------------------------------------------------------------

// from http://www.abeautifulsite.net/whipping-file-inputs-into-shape-with-bootstrap-3/
define("fileInput", ["jquery"], function($) {
	$(document).on('change', '.btn-file :file', function() {
		var input = $(this),
			numFiles = input.get(0).files ? input.get(0).files.length : 1,
			label = input.val().replace(/\\/g, '/').replace(/.*\//, '');
		input.trigger('fileselect', [numFiles, label]);
	});

	$(document).ready( function() {
		$('.btn-file :file').on('fileselect', function(event, numFiles, label) {
			var input = $(this).parents('.input-group').find(':text'),
				log = numFiles > 1 ? numFiles + ' files selected' : label;

			if (input.length) {
				input.val(log);
			} else {
				if (log) alert(log);
			}
		});
	});
});



// ---- Jansy RowLink Module ----------------------------------------------------------------------

define("rowLink", ["jquery"], function(a) {

/*!
 * Jasny Bootstrap v3.1.0 (http://jasny.github.com/bootstrap)
 * Copyright 2011-2014 Arnold Daniels.
 * Licensed under Apache-2.0 (https://github.com/jasny/bootstrap/blob/master/LICENSE)
 */
var b=function(c,d){this.$element=a(c),this.options=a.extend({},b.DEFAULTS,d),this.$element.on("click.bs.rowlink","td:not(.rowlink-skip)",a.proxy(this.click,this))};b.DEFAULTS={target:"a"},b.prototype.click=function(b){var c=a(b.currentTarget).closest("tr").find(this.options.target)[0];if(a(b.target)[0]===c)return;b.preventDefault();if(c.click)c.click();else if(document.createEvent){var d=document.createEvent("MouseEvents");d.initMouseEvent("click",!0,!0,window,0,0,0,0,0,!1,!1,!1,!1,0,null),c.dispatchEvent(d)}};var c=a.fn.rowlink;a.fn.rowlink=function(c){return this.each(function(){var d=a(this),e=d.data("bs.rowlink");e||d.data("bs.rowlink",e=new b(this,c))})},a.fn.rowlink.Constructor=b,a.fn.rowlink.noConflict=function(){return a.fn.rowlink=c,this},a(document).on("click.bs.rowlink.data-api",'[data-link="row"]',function(b){if(a(b.target).closest(".rowlink-skip").length!==0)return;var c=a(this);if(c.data("bs.rowlink"))return;c.rowlink(c.data()),a(b.target).trigger("click.bs.rowlink")})

});



// ---- Tinysort ----------------------------------------------------------------------------------

/**
 * TinySort is a small script that sorts HTML elements. It sorts by text- or attribute value, or by that of one of it's children.
 * @summary A nodeElement sorting script.
 * @version 2.2.2
 * @license MIT/GPL
 * @author Ron Valstar <ron@ronvalstar.nl>
 * @copyright Ron Valstar <ron@ronvalstar.nl>
 * @namespace tinysort
 */
!function(a,b){"use strict";function c(){return b}"function"==typeof define&&define.amd?define("tinysort",c):a.tinysort=b}(this,function(){"use strict";function a(a,d){function h(){0===arguments.length?q({}):b(arguments,function(a){q(z(a)?{selector:a}:a)}),n=G.length}function q(a){var b=!!a.selector,d=b&&":"===a.selector[0],e=c(a||{},p);G.push(c({hasSelector:b,hasAttr:!(e.attr===g||""===e.attr),hasData:e.data!==g,hasFilter:d,sortReturnNumber:"asc"===e.order?1:-1},e))}function r(){b(a,function(a,b){B?B!==a.parentNode&&(H=!1):B=a.parentNode;var c=G[0],d=c.hasFilter,e=c.selector,f=!e||d&&a.matchesSelector(e)||e&&a.querySelector(e),g=f?E:F,h={elm:a,pos:b,posn:g.length};D.push(h),g.push(h)}),A=E.slice(0)}function s(){E.sort(t)}function t(a,c){var d=0;for(0!==o&&(o=0);0===d&&n>o;){var g=G[o],h=g.ignoreDashes?l:k;if(b(m,function(a){var b=a.prepare;b&&b(g)}),g.sortFunction)d=g.sortFunction(a,c);else if("rand"==g.order)d=Math.random()<.5?1:-1;else{var i=f,p=y(a,g),q=y(c,g),r=""===p||p===e,s=""===q||q===e;if(p===q)d=0;else if(g.emptyEnd&&(r||s))d=r&&s?0:r?1:-1;else{if(!g.forceStrings){var t=z(p)?p&&p.match(h):f,u=z(q)?q&&q.match(h):f;if(t&&u){var v=p.substr(0,p.length-t[0].length),w=q.substr(0,q.length-u[0].length);v==w&&(i=!f,p=j(t[0]),q=j(u[0]))}}d=p===e||q===e?0:q>p?-1:p>q?1:0}}b(m,function(a){var b=a.sort;b&&(d=b(g,i,p,q,d))}),d*=g.sortReturnNumber,0===d&&o++}return 0===d&&(d=a.pos>c.pos?1:-1),d}function u(){var a=E.length===D.length;if(H&&a)I?E.forEach(function(a,b){a.elm.style.order=b}):B.appendChild(v());else{var b=G[0],c=b.place,d="org"===c,e="start"===c,f="end"===c,g="first"===c,h="last"===c;if(d)E.forEach(w),E.forEach(function(a,b){x(A[b],a.elm)});else if(e||f){var i=A[e?0:A.length-1],j=i.elm.parentNode,k=e?j.firstChild:j.lastChild;k!==i.elm&&(i={elm:k}),w(i),f&&j.appendChild(i.ghost),x(i,v())}else if(g||h){var l=A[g?0:A.length-1];x(w(l),v())}}}function v(){return E.forEach(function(a){C.appendChild(a.elm)}),C}function w(a){var b=a.elm,c=i.createElement("div");return a.ghost=c,b.parentNode.insertBefore(c,b),a}function x(a,b){var c=a.ghost,d=c.parentNode;d.insertBefore(b,c),d.removeChild(c),delete a.ghost}function y(a,b){var c,d=a.elm;return b.selector&&(b.hasFilter?d.matchesSelector(b.selector)||(d=g):d=d.querySelector(b.selector)),b.hasAttr?c=d.getAttribute(b.attr):b.useVal?c=d.value||d.getAttribute("value"):b.hasData?c=d.getAttribute("data-"+b.data):d&&(c=d.textContent),z(c)&&(b.cases||(c=c.toLowerCase()),c=c.replace(/\s+/g," ")),c}function z(a){return"string"==typeof a}z(a)&&(a=i.querySelectorAll(a)),0===a.length&&console.warn("No elements to sort");var A,B,C=i.createDocumentFragment(),D=[],E=[],F=[],G=[],H=!0,I=a.length&&(d===e||d.useFlex!==!1)&&-1!==getComputedStyle(a[0].parentNode,null).display.indexOf("flex");return h.apply(g,Array.prototype.slice.call(arguments,1)),r(),s(),u(),E.map(function(a){return a.elm})}function b(a,b){for(var c,d=a.length,e=d;e--;)c=d-e-1,b(a[c],c)}function c(a,b,c){for(var d in b)(c||a[d]===e)&&(a[d]=b[d]);return a}function d(a,b,c){m.push({prepare:a,sort:b,sortBy:c})}var e,f=!1,g=null,h=window,i=h.document,j=parseFloat,k=/(-?\d+\.?\d*)\s*$/g,l=/(\d+\.?\d*)\s*$/g,m=[],n=0,o=0,p={selector:g,order:"asc",attr:g,data:g,useVal:f,place:"org",returns:f,cases:f,forceStrings:f,ignoreDashes:f,sortFunction:g,useFlex:f,emptyEnd:f};return h.Element&&function(a){a.matchesSelector=a.matchesSelector||a.mozMatchesSelector||a.msMatchesSelector||a.oMatchesSelector||a.webkitMatchesSelector||function(a){for(var b=this,c=(b.parentNode||b.document).querySelectorAll(a),d=-1;c[++d]&&c[d]!=b;);return!!c[d]}}(Element.prototype),c(d,{loop:b}),c(a,{plugin:d,defaults:p})}());
