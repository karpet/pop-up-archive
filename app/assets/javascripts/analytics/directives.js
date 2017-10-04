angular.module('Directory.analytics.directives',['d3'])
  .directive('bubbleChart', ['d3Service', function (d3Service) {
    return {
      restrict: 'E',
      scope: { 
        data: '=data',
        collections: '=collections'
      },
      link: function (scope, element, attrs) {
        var data = scope.data;
        var collections = scope.collections;

        d3Service.d3().then(function () {
          var node,
              maxRadius = 80,
              nameTextSize = 12,
              countTextSize = 10,
              height = 700,
              width = 700,
              collisionPadding = 4,
              minCollisionRadius = 12,
              jitter = 0.6,
    
              center = {
                x: width / 2,
                y: height / 2
              };

          var rScale = d3.scale.sqrt().range([0, maxRadius]);
          var rValue = function (d) { return d.count };
          var textValue = function (d) { return d.name };
          var idValue = function (d) { return d.name };

          var setUpVis = function () {
            var svg = d3.select(element[0]).append('svg');
            svg.attr({width: width, height: height});

            var node = svg.append('g');
            node = node.selectAll('.bubble-node');
          }

          //`gravity` pulls circles toward center
          var gravity = function (alpha) {
            cx = width / 2;
            cy = height / 2;
            //uneven gravity gives vis a landscape layout
            ax = alpha;
            ay = alpha/1.5;

            return function (d) {
              d.x += (cx - d.x) * ax;
              d.y += (cy - d.y) * ay;
            }
          }

          // `collide` keeps circles from overlapping each other
          var collide = function(jitter) {
            return function(d) {
              scope.data.forEach(function(d2) {
                if (d !== d2) {
                  var x = d.x - d2.x;
                  var y = d.y - d2.y;
                  var distance = Math.sqrt((x * x) + (y * y));
                  minDistance = d.forceR + d2.forceR + collisionPadding;
                  if (distance < minDistance) {
                    distance = (distance - minDistance) / distance * jitter;
                    var moveX = x * distance;
                    var moveY = y * distance;
                    d.x -= moveX;
                    d.y -= moveY;
                    d2.x += moveX;
                    d2.y += moveY;
                  }
                }
              });
            };
          }

          var tick = function (e) {
            var dampenedAlpha = e.alpha * 0.8;
            node
              .each(gravity(dampenedAlpha))
              .each(collide(jitter))
              .attr('transform', function (d) {
                return "translate(" + d.x + "," + d.y + ")"
              })
          }

          var force = d3.layout.force()
                        .gravity(0)
                        .charge(0)
                        .size([width, height])
                        .on("tick", tick)
                        .start();

          var updateNodes = function (data) {
            node.exit().remove();

            //need to add a 'g' for each data point in order to attach
            //both a circle and a text object
            nodeEnter = node.enter().append('g')
              .attr('class', 'bubble-node')
              .attr('transform', function (d) {
                return "translate(" + d.x + "," + d.y + ")"
              });

            nodeEnter
              .append('a')
              .attr('xlink:href', function (d) {
                col_ids=[];
                for (var i = collections.length - 1; i >= 0; i--) {
                  col_ids.push(collections[i].collection.id);
                };
                return '/search?query="' + encodeURIComponent(idValue(d)) + '",collection_id%3A(' + col_ids.join('%20OR%20') + ')';
              } )
              .append('circle');
            nodeEnter.append('text').attr('class', 'name');
            nodeEnter.append('text').attr('class', 'count');

          }

          var partialText = function (d) {
            var text = d.name.substring(0, (d.radius * 3) / nameTextSize + 1);
            return (d.name.length <= text.length ? text : text + "\u2026");
          }

          var showFullText = function (event) {
            document.getElementById(event.name).style.zIndex = "1";
            node.selectAll('.name')
              .text(function (d) {
                if (event.name == d.name) {
                  return d.name
                } else {
                  return partialText(d);
                }
              })
          }

          var updateStyles = function (force) {

            node
              .selectAll('circle')
              .call(force.drag)
              .attr('id', function (d) { return d.name })
              .attr('r', function (d) {
                return d.radius;
              })
              .attr('fill', function (d) {
                if (d.type == 'tag') {
                  return '#5970B1';
                } else {
                  return '#F25A4C';
                }
              })
              .on('mouseenter', showFullText);

            node.selectAll('text')
              .style("text-anchor", "middle")
              .style("color", "#333");


            node.selectAll(".name")
              .text(function (d) {
                  return partialText(d);
              })
              .style("font-size", nameTextSize + "px");

            node.selectAll(".count")
              .attr("dy", "1.2em")
              .text(function(d) {
                  return d.count;
              })
              .style("font-size", countTextSize + "px");
          }


          var recalculateDomain = function (data) {
            var maxDomainValue = d3.max(data, function (d) {
              return rValue(d);
            })

            rScale.domain([0, maxDomainValue]);
          }

          scope.$watch('data', function (data) {
            //need to remove and redraw the svg on every update
            d3.selectAll('svg').remove();
            var svg = d3.select(element[0]).append('svg');
            svg.attr({width: width, height: height});
            node = svg.append('g');
            node = node.selectAll('.bubble-node');

            recalculateDomain(data);

            //calculate display values
            data.forEach(function (d, i) {
              d.radius = rScale(rValue(d));
              d.forceR = Math.max(minCollisionRadius, rScale(rValue(d)));
            });

            // nodes with longer names get drawn last
            data.sort(function (d1, d2) {
              return d1.name.length - d2.name.length;
            })

            // assign data and trigger the force layout's start
            node = node.data(data, function (d) {
              return idValue(d);
            });
            force.nodes(data).start();

            updateNodes(data);
            updateStyles(force);

          })


        })

      }
    }
  }])