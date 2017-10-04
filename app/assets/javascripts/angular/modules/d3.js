angular.module('d3', [])
  .factory('d3Service', ['$document', '$q', '$rootScope',
    function($document, $q, $rootScope) {
      var d = $q.defer();
      // d3.min.js loaded along with other js in vendor/assets

      // any other d3 set up here

      return {
        d3: function() {
          d.resolve(window.d3);
          return d.promise; 
        }
      };
}]);
