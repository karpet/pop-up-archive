angular.module('Directory.analytics.controllers', ['Directory.loader', 'Directory.user', 'Directory.collections.models', 'Directory.analytics.models', 'ngTutorial', 'Directory.storage', 'Directory.analytics.directives'])
.controller('AnalyticsCtrl', ['$scope', '$location', 'Collection', 'AnalyticsData', 'Loader', 'Search', 'Me', function ($scope, $location, Collection, AnalyticsData, Loader, Search, Me) {

  $scope.$location = $location;
  $scope.facet = $location.search().query || 'tags';
  $scope.analyticsData = new AnalyticsData($scope.facet);

  Me.authenticated(function (me) {
    $scope.currentUser = me
    Loader.page(Collection.get(), 'Collections', $scope).then(function (data) {
      $scope.collections = data;
      $scope.fetchCollections();
    });
  })

   $scope.fetchCollections = function () {
    angular.forEach($scope.currentUser.collectionIds, function (collection) {
      $scope.fetchCollectionObject(collection).then(function (data) {
        var collObj = data
        $scope.fetchCollection(collection).then(function (data) {
          $scope.analyticsData.createCollection(collObj, data);
        })
      })
    })
  }

  $scope.fetchCollection = function (collection) {
    var searchParams = {
      'filters[collection_id]': collection
    }

    return Loader.page(Search.query(searchParams));
  }

  $scope.fetchCollectionObject = function (collectionId) {
    return Collection.get({id:collectionId})
  }

  $scope.toggleCollection = function (collection) {
    if (collection.selected) {
      $scope.analyticsData.deselectCollection(collection);
    } else {
      $scope.analyticsData.selectCollection(collection);
    }
  }
}])
