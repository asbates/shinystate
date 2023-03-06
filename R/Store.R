#' R6 Class Implementing a Store
#'
#' @description A `Store` is an R6 object for storing and managing the state of
#' a Shiny application. This includes event handling.
#'
#' @examples
#' states <- list(data = "mtcars")
#' events <- list("data_changed")
#' store <- Store$new(name = "app", states = states, events = events)
#' store$getState("data")
#' store$setState("data", "iris")
#' store$getState("data")
#'
#' @export
Store <- R6::R6Class(
  "Store",
  public = list(
    #' @description Initialize a `Store` object.
    #' @param name The name of the store.
    #' @param states A named list of states and their values.
    #' @param events A list of event names to manage with the store.
    initialize = function(name, states, events = NULL) {

      for (state_name in names(states)) {
        private$states[[state_name]] <- states[[state_name]]
      }

      if (!is.null(events)) {
        for (event in events) {
          private$events[[event]] <- shiny::reactiveVal(0)
        }
      }

      invisible(self)
    },
    #' @description Get the value of a state.
    #' @param name The name of the state.
    #' @return The value of the state.
    getState = function(name) {
      private$states[[name]]
    },
    #' @description Set the value of a state.
    #' @param name The name of the state.
    #' @param value The value of the state.
    #' @return Self invisibly.
    setState = function(name, value) {
      private$states[[name]] <- value
      invisible(self)
    },
    #' @description Trigger an event.
    #' @param event The name of the event.
    trigger = function(event) {
      private$events[[event]]( private$events[[event]]() + 1 )
    },
    #' @description Respond to an event.
    #' @param event The name of the event.
    #' @param expression The expression to run when the event occurs.
    on = function(event, expression) {
      shiny::observeEvent(
        private$events[[event]](),
        { substitute(expression) },
        handler.quoted = TRUE,
        handler.env = parent.frame(),
        ignoreInit = TRUE
      )
    }
  ),
  private = list(
    states = NULL,
    events = NULL
  )
)

#' Create a new store for the given Shiny session.
#'
#' @description Creates a [`Store`] object for the given session. Store names
#'  must be unique within a session. The store is created in the `userData`
#'  environment of the given session.
#'
#' @param name The name of the store.
#' @param states A named list of states and their values.
#' @param events An optional list of event names to manage with the store.
#' @param session The Shiny session to save the store in.
#'
#' @return A [`Store`] object.
#'
#' @examples
#' states <- list(data = "mtcars")
#' events <- list("data_changed")
#' session <- shiny::MockShinySession$new()
#' store <- new_store(name = "app", states = states, events = events, session = session)
#' store$getState("data")
#'
#' @export
new_store <- function(name, states, events = NULL, session = shiny::getDefaultReactiveDomain()) {
  if (exists(name, session$userData)) {
    stop("A store with this name already exists", call. = FALSE)
  }
  store <- Store$new(name, states, events)
  session$userData[[name]] <- store
  store
}

#' Get a store in the given Shiny session.
#'
#' @description Gets an existing store for the given session.
#'
#' @param name The name of the store.
#' @param session The Shiny session to retrieve the store from.
#'
#' @return A [`Store`] object.
#'
#' @examples
#' states <- list(data = "mtcars")
#' events <- list("data_changed")
#' session <- shiny::MockShinySession$new()
#' new_store(name = "app", states = states, events = events, session = session)
#' # in a module server:
#' store <- getStore("app", session)
#' @export
getStore <- function(name, session = shiny::getDefaultReactiveDomain()) {
  if (!exists(name, session$userData)) {
    stop("That store does not exist.", call. = FALSE)
  }
  session$userData[[name]]
}
