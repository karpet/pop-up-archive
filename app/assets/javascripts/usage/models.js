angular.module('Directory.usage.models', [])
.factory('Usage', ['$http', '$location', '$q', 'Model', function ($http, $location, $q, Model) {
  var Usage = Model({url:'/api/usage', name: 'usage'});

  return Usage;
}]);
