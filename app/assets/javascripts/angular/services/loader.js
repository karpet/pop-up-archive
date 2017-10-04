angular.module('Directory.loader', ['ngLoadingIndicators'])
.factory('Loader', ['$q', 'loading', '$timeout', function ($q, loading, $timeout) {

  function camelize (key) {
    if (!angular.isString(key)) {
      return key;
    }
    return key.replace(/_[\w\d]/g, function (match, index, string) {
      return index === 0 ? match : string.charAt(index + 1).toUpperCase();
    });
  }

  function resolveData($scope, deferred, cacheKey) {
    return function (data) {
      if ($scope) {
        angular.forEach(data, function (response) {
          var setName;

          if (angular.isArray(response) && response.length > 0) {
            setName = camelize(response[0].constructor.rootPluralName);
          } else if (angular.isArray(response)) {
            setName="collections";
          } else if (typeof response !== 'undefined') {
            setName = camelize(response.constructor.rootName);
          }

          if (setName) {
            $scope[setName] = response;
          }
        });
      }

      if (data.length == 1) {
        data = data[0];
      }

      if (deferred) {
        deferred.resolve(data);
      }

      return data;
    }
  }

  function load () {
    var argumentsArray = Array.prototype.slice.call(arguments);
    var $scope;
    var cacheKey;
    if (typeof argumentsArray[argumentsArray.length-1].$parent !== 'undefined') {
      $scope = argumentsArray.pop();
    }
    if (typeof argumentsArray[argumentsArray.length-1] === 'string') {
      cacheKey = argumentsArray.pop();
    }

    var deferred = $q.defer();
    var promise = deferred.promise;

    $q.all(argumentsArray).then(resolveData($scope, deferred, cacheKey), function (data) {
      console.error(data);
      deferred.reject(data);
    });

    return promise;
  }

  function loadPage () {
    loading.page(true)
    return load.apply(this, arguments).then(function (data) {
      loading.page(false);
      return data;
    }, function (data) {
      loading.page(false);
      return $q.reject(data);
    });
  }

  var Loader = load;
  Loader.page = loadPage;

  return Loader;
}]);
