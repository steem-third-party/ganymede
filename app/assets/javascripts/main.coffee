if document.app == undefined
  document.app = angular.module('Ganymede', ['flash'])
  
document.app.
config(['$httpProvider', ($httpProvider) ->
  $httpProvider.interceptors.push ['$q', ($q) ->
    {
      'request': (config) -> NProgress.start(); return config
      'requestError': (rejection) -> NProgress.done(); return $q.reject rejection
      'response': (response) -> NProgress.done(); return response
      'responseError': (rejection) -> NProgress.done(); return $q.reject rejection
    }
  ]
]).
directive('flash', ['Flash', '$compile', (Flash, $compile) ->
  restrict: 'E'
  scope:
    messages: '=messages'
  controller: ['$scope', '$element', '$attrs', ($scope, $element, $attrs) ->
    angular.forEach $scope.messages, (f) ->
      message = f[1]
      alertType = switch f[0]
        when 'notice' then 'alert-success'
        when 'info' then 'alert-info'
        when 'alert' then 'alert-warning'
        when 'error' then 'alert-danger'
        else f[0]
      Flash.create('success', message, "#{alertType} nga-fast nga-slide-up")
  ]
]).
directive('formErrors', ['$compile', ($compile) ->
  restrict: 'E'
  scope:
    errors: '=errors'
  controller: ['$scope', '$element', '$attrs', ($scope, $element, $attrs) ->
    return if $scope.errors.length == 0
    
    template = '''
      <div role="alert" class="m-x-auto alert alert-danger">
      <h2>Form is invalid</h2>
      <ul>
    '''
      
    angular.forEach $scope.errors, (msg) ->
      template += '<li>' + msg
        
    template += '</ul></div>'
      
    $element.append $compile(template)($scope)
  ]
]).
directive('splatnit', ['$parse', ($parse) ->
  require: '?ngModel'
  link: (scope, element, attrs) ->
    return if attrs.splatnit == 'false'
    
    field = attrs.ngModel
    type = attrs.type
    value = if type == 'number'
      $(element).val() * 1
    else
      $(element).val()
    
    $parse(field).assign(scope, value)
])

$(document).on 'ready page:load', -> angular.bootstrap 'body', ['Ganymede']