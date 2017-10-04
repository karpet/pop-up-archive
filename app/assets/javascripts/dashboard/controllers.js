angular.module('Directory.dashboard.controllers', ['Directory.loader', 'Directory.user', 'Directory.dashboard.models'])
.controller('DashboardCtrl', [ '$scope', 'Item', 'Loader', 'Me', 'Stats', function ItemsCtrl($scope, Item, Loader, Me, Stats) {
  Me.authenticated(function (data) {
  });

  if (window.location.pathname == "/"){
    mixpanel.track(
      "Home Page"
    );
  };

  //tally total minutes in archive for display on homepage
  var minutes = function () {
    Stats.query().then(function (stats) {
      $scope.stats = Math.floor((stats.publicAudio + stats.privateAudio)/60);
    });
  };
  minutes();

  $scope.getStarted = function () {
    mixpanel.track(
      "Clicked Get Started"
    );
  }
}])
