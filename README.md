
# shinystate

<!-- badges: start -->
<!-- badges: end -->


`shinystate` is a package for managing state in Shiny applications.
When working with large Shiny apps, especially those with deeply nested modules,
 managing state can be difficult.
A common practice is to have a list of reactive values that gets passed to every
 module.
`shinystate` provides an alternative to this method.
It provides a `Store` object which is a simple `{R6}` class to set and get state.
It also provides functions to create and get a store in an applications session
 object (`session$userData`).
This means we can access the store from any of the applications module server
 functions without having to pass the store as an argument.

`shinystate` also provides methods to have more control of an applications reactivity.
A `Store` object can also trigger and respond to developer-defined events.
Since a stores can be made available within any module server, events are also
 available.
You can for example trigger an event in one module and respond to it from another,
 without passing reactive values between them.
This method of event handling was inspired by the [`{gargoyle}`](https://github.com/ColinFay/gargoyle) package.


## Installation

You can install the development version of shinystate from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("asbates/shinystate")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(shiny)
library(shinystate)

app_ui <- function(request) {
  fluidPage(
    select_data_ui("data_select"),
    show_data_ui("data_show")
  )
}

app_server <- function(input, output, session) {
  store <- new_store(
    name = "app",
    states = list(data = "mtcars"),
    events = list("data_selected")
  )
  select_data_server("data_select")
  show_data_server("data_show")
}


select_data_ui <- function(id) {
  ns <- NS(id)
  selectInput(ns("select"),"pick", choices = c("mtcars", "iris"))
}

select_data_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    store <- getStore("app")

    observeEvent(input$select, {
      store$setState("data", input$select)
      store$trigger("data_selected")
    })

  })
}

show_data_ui <- function(id) {
  ns <- NS(id)
  dataTableOutput(ns("table"))
}

show_data_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    store <- getStore("app")

    store$on("data_selected", {
      output$table <- renderDataTable({
        data_name <- store$getState("data")
        get(data_name, "package:datasets")
      })
    })

  })
}
app <- shinyApp(app_ui, app_server)
runApp(app)

```

