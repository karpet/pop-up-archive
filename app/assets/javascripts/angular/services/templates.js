// override some AngularStrap templates

angular.module('mgcrea.ngStrap.dropdown').run([ '$templateCache', function($templateCache) {
    $templateCache.put('dropdown/dropdown.tpl.html', '<ul tabindex="-1" class="dropdown-menu" role="menu"><li role="presentation" ng-class="{divider: item.divider}" ng-repeat="item in content"><a role="menuitem" tabindex="-1" ng-href="{{item.href}}" ng-if="!item.divider && item.href && !item.method" target="{{item.target || \'\'}}" ng-bind="item.text"></a> <a tabindex="-1" ng-href="{{item.href}}" data-method="{{item.method || \'\'}}" ng-if="!item.divider && item.href && item.method" target="{{item.target || \'\'}}">{{item.text}}</a> <a role="menuitem" tabindex="-1" href="javascript:void(0)" ng-if="!item.divider && item.click" ng-click="$eval(item.click);$hide()" ng-bind="item.text"></a></li></ul>');
} ]);

// useful for embedded HTML within popover content
angular.module('mgcrea.ngStrap.popover').run([ '$templateCache', function($templateCache) {
    $templateCache.put('popover/popover-html.tpl.html', '<div class="popover" style="min-width:150px"><div class="arrow"></div><button type="button" class="close" ng-click="$hide()" aria-hidden="true">&times;</button><h3 class="popover-title" ng-bind="title" ng-show="title"></h3><div class="popover-content" ng-bind-html="content"></div></div>');
} ]);
