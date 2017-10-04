angular.module('Directory.dashboard.models', ['RailsModel'])
.factory('Stats', ['Model', '$http', function (Model, $http) {
  var Stats = Model({url:'/api/stats', name: 'stats'});
  return Stats;
}])