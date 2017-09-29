#= require jquery
#= require jquery-ujs
#= require tether
#= require bootstrap
#= require turbolinks
#= require angular
#= require angular-flash-alert
#= require angular-ui-bootstrap
#= require angular-ui-bootstrap-tpls
#= require nprogress
#= require Chart.bundle
#= require chartkick
#= require main
#= require_tree .

NProgress.configure
  showSpinner: true,
  ease: 'ease',
  speed: 100,
  minimum: 0.08

# Turbolinks.enableTransitionCache() # Causes momenary jump while new page loads.
#Turbolinks.ProgressBar.disable() if Turbolinks.ProgressBar
$(document).on 'ajaxStart page:fetch', -> NProgress.start()
$(document).on 'submit', 'form', -> NProgress.start()
$(document).on 'ajaxStop page:change', -> NProgress.done()
$(document).on 'page:receive', -> NProgress.set(0.7)
$(document).on 'page:restore', -> NProgress.remove()
  
$(document).on 'page:change', ->
  if !!(fieldset = $('fieldset:has(.field_with_errors)'))
    fieldset.addClass('has-danger') 
  if !!(any = $('.field_with_errors'))
    any.addClass('has-danger') 
  if !!(input = $('.field_with_errors > input'))
    input.addClass('form-control-danger') 
  if !!(label = $('.field_with_errors > label'))
    label.addClass('control-danger') 
