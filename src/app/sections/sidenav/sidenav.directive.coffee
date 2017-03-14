
angular.module('AltexoApp')

.directive 'altexoSidenav', -> {
  restrict: 'A'
  templateUrl: 'sections/sidenav/sidenav.pug'
  link: ($scope, $element, attrs) ->
    console.log '>> SIDENAV', $scope, $element, attrs
}
