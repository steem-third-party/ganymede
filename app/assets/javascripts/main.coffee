if document.app == undefined
  document.app = angular.module('Ganymede', ['flash', 'ui.bootstrap'])
  
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
]).
directive('mvests', ['$http', '$compile', ($http, $compile) ->
  restrict: 'E'
  controller: ['$scope', '$element', ($scope, $element) ->
    config = {cache: true}
    success = (response) ->
      data = response.data
      if !!data
        $element.html $compile("<code>#{data}</code>")($scope)
    error = (response) ->
      status = response.status
      statusText = response.statusText
      data = response.data
      template = """
        <code>Unable to get MVESTS.</code>
        <button class="btn btn-sm btn-danger" type="button" data-toggle="collapse" data-target="#collapseError" aria-expanded="false" aria-controls="collapseError">
          #{status} - #{statusText} ...
        </button>
        <div class="collapse" id="collapseError">
          <div class="card card-block">
            #{data}
          </div>
        </div>
      """
      $element.html $compile(template)($scope)
    $http.get('/mvests', config).then success, error
  ]
])

$(document).on 'ready page:load', -> angular.bootstrap 'body', ['Ganymede']
