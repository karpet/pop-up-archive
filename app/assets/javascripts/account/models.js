angular.module('Directory.account.models', [])
.factory('Plan', ['Model', function (Model) {
  var Plan = new Model({url:'/api/plans', name: 'plan'});

  Plan.community = function () {
  	return this.get().then(function (plans) {
      var community;
      angular.forEach(plans, function (plan) {
        if (typeof community === 'undefined' && plan.id === "premium_community") {
          community = plan;
          community.is_community = true;
        }
      });
      return community;
  	});
  };

  return Plan;

}])

.factory('SampleAudio', ['Model', '$rootScope', 'Player', function (Model, $rootScope, Player) {
  $rootScope.exampleAudioFile = {
    url:  "https://sometestfile.mp3",
    duration: "00:00:35"
  };

  $rootScope.play = function (file) {
    Player.play(file);
    $rootScope.fileUrl = file;
  };

  $rootScope.pause = function () {
    Player.pause();
  };

  $rootScope.rewind = function () {
    Player.rewind();
  };

  $rootScope.isLoaded = function () {
    return Player.nowPlayingUrl() === $rootScope.fileUrl;
  };

  $rootScope.isPlaying = function () {
    return $rootScope.isLoaded() && !Player.paused();
  };

}])


.factory('Subscribe', ['Model', '$rootScope', 'Plan', '$window', '$modal', '$location', function (Model, $rootScope, Plan, $window, $modal, $location) {
  $rootScope.interval = 'month';
  $rootScope.offer = $rootScope.offer || {};
  $rootScope.community = Plan.community();
  Plan.get().then(function(plans) {
    $rootScope.plans = [];
    plans.forEach(function(plan){

      switch(plan.id){
        case 'premium_community':
        case '1_hour_monthly':
        case '5_hours_monthly':
        case '10_hours_monthly':
        case '20_hours_monthly':
        case '25_hours_monthly':
        case '1_hour_yearly':
        case '5_hours_yearly':
        case '10_hours_yearly':
        case '20_hours_yearly':
        case '25_hours_yearly':
        // case '25_small_business_mo':
        // case '25_small_business_yr':
        // case '20_small_business_mo':
        // case '20_small_business_yr':
        // case '10_small_business_mo':
        // case '10_small_business_yr':
        // case '5_small_business_mo':
        // case '5_small_business_yr':
        // case '1_small_business_mo':
        // case '1_small_business_yr':
          $rootScope.plans.push(plan);
      }
    });
  });

  $rootScope.longInterval = false;
  $rootScope.planOffset = 3;
  $rootScope.togglePlans = function () {
    $rootScope.interval = ( $rootScope.interval == 'year' ? 'month' : 'year');
    $rootScope.longInterval = !$rootScope.longInterval;
    //$rootScope.planOffset = ( $rootScope.planOffset == '2' ? '3' : '2');
  };

  $rootScope.hasFriendCoupon = function($location) {
    if(window.location.search.split('ui=')[1] != null) {
      if((window.location.search.split('ui=')[1].match(/^[0-9]*$/g)).length > 0) {
          console.log(!!(window.location.search.split('ui=')[1].match(/^[0-9]*$/g)))
          return true
       } else {
          return false
       }
    } else {
      return false
    }
  };

  $rootScope.isDisabled = function(plan) {
    if (plan.name == 'Community') {
      return true;
    }
    else {
      return false;
    }
  };

  $rootScope.getCommunity = function() {
    console.log("upgrade/downgrade")
    return Plan.community().then(function (plan) {
      return $rootScope.changePlan(plan)
    })
  }
  //add if then for monthly vs yearly toggle
  $rootScope.shouldDisplay = function() {
    var displayPlans = []
    if ($rootScope.interval === "month") {
      displayPlans = ['1_hour_monthly','5_hours_monthly', '10_hours_monthly', '20_hours_monthly', '25_hours_monthly']
    } else if ($rootScope.interval === "year") {
      displayPlans = ['1_hour_yearly','5_hours_yearly', '10_hours_yearly', '20_hours_yearly', '25_hours_yearly']
    }
    return function(plan) {
      return displayPlans.indexOf(plan.id) > -1
    }
  }

  $rootScope.getInterval = function() {
    return $rootScope.interval;
  };

  $rootScope.isPremiumPlan = function (plan) {
    if (plan.name === "Community"){
      return false;
    } else {
      return true;
    }
  };

  $rootScope.stopUpgrade = false;

  $rootScope.changePlan = function (plan) {

    switch(plan.id){
      case 'enterprise':
        $modal({template: '/assets/plans/form.html', persist: true, show: true, backdrop: 'static'});
        return;
      default:
        subscribe(plan);
    }
  };
}]);
