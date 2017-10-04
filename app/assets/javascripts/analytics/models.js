angular.module('Directory.analytics.models', ['RailsModel', 'Directory.collections.models'])
.factory('AnalyticsData', function () {

  //A wrapper for the search result data for each collection
  function AnalyticsDataCollection (collection, search, facetName) {
    this.collection = collection;
    this.search = search;
    this.results = this.search.results;
    this.setCurrentFacet(facetName);
  };

  AnalyticsDataCollection.prototype.setCurrentFacet = function (facetName) {
    this.currentFacet = this.search.getFacet(facetName);
    this.calculateData();
  };

  //Count up the entries for display for the current facet
  AnalyticsDataCollection.prototype.calculateData = function () {
    var data;
    if (this.currentFacet && this.currentFacet.name === 'tags') {
      data = {'tags': {}, 'entity': {}};
      angular.forEach(this.search.facets.tags.buckets, function(entry) {
        // console.log("entry : " + entry.key + " " + entry)
        var count = entry.docCount;
        var term = entry.key;
        data['tags'][term] = count;
      }, this);


      angular.forEach(this.search.facets.entities.buckets, function (entry) {
        var count = entry.docCount;
        var term = entry.key;
        data['entity'][term] = count;
      }, this)
    }
    this.currentData = data;
  };

  //An aggregate wrapper for all the individual AnalyticsDataCollection objects
  function AnalyticsData(facetName) {
    this.facetName = facetName;
    this.dataCollections = [];
    this.data = {};
    this.dataForVis = [];
  }

  AnalyticsData.prototype.createCollection = function (collection, data) {
    var dataCollection = new AnalyticsDataCollection(collection, data, this.facetName);
    this.dataCollections.push(dataCollection);
    this.selectCollection(dataCollection);
  };

  AnalyticsData.prototype.selectCollection = function (dataCollection) {

    angular.forEach(dataCollection.currentData, function (item, type) {
      this.data[type] = this.data[type] || {};
      angular.forEach(dataCollection.currentData[type],
        function (count, name) {
          var count = this.data[type][name] || 0;
          this.data[type][name] = dataCollection.currentData[type][name] + count;
          }, this)
    }, this)

    dataCollection.selected = true;
    this.calculateData();
  };

  AnalyticsData.prototype.deselectCollection = function (dataCollection) {

    angular.forEach(dataCollection.currentData, function (item, type) {
      angular.forEach(dataCollection.currentData[type], function (count, name) {
        if (this.data[type][name] - count == 0) {
          delete this.data[type][name];
        } else {
          this.data[type][name] -= count;
        }
      }, this)
    }, this)

    dataCollection.selected = false;
    this.calculateData();
  };

  //Format the aggregate count for use in the d3 vis directive
  AnalyticsData.prototype.calculateData = function () {
    var _dataForVis = [];

    angular.forEach(this.data, function (item, type) {
      angular.forEach(item, function (count, name) {
        _dataForVis.push({
          'name': name,
          'count': count,
          'type': type
        })
      })
    }, this)

    _dataForVis = _dataForVis.sort(function (a, b) {
      return b.count - a.count;
    })

    this.dataForVis = _dataForVis.slice(0, 25);
  };

  return AnalyticsData;
});
