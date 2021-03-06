#' Create a ggplot
#'
#' @param data a data.frame
#' @param x Variable to map in x
#' @param y Variable to map in y
#' @param fill Variable to map in fill
#' @param color Variable to map in color
#' @param size Variable to map in size
#' @param facet Variable to call in facet_wrap
#' @param type Geom to use
#' @param params additionnal params, like title, xlabel...
#' @param ... not use
#'
#' @return a ggplot object
#' @noRd
#' 
#' @importFrom ggplot2 ggplot aes_ scale_fill_hue scale_fill_gradient scale_fill_brewer
#'  scale_fill_distiller scale_color_hue scale_color_gradient scale_color_brewer 
#'  scale_color_distiller labs coord_flip geom_smooth theme element_text facet_wrap
#'  scale_colour_viridis_d scale_colour_viridis_c scale_fill_viridis_d scale_fill_viridis_c
#'
#'
#' @examples
#' if (interactive()) {
#' 
#' data("diamonds", package = "ggplot2")
#' 
#' ggtry(data = diamonds, x = "carat")
#' ggtry(data = diamonds, x = "cut")
#' 
#' }
ggtry <- function(data, x = NULL, y = NULL, fill = NULL, color = NULL, size = NULL, group = NULL, facet = NULL, type = "auto", params = list(), ...) {

  check_vars <- c(x, y, fill, color, size, facet)
  if ((is.null(check_vars) || !all(check_vars %in% names(data))) & !inherits(data, what = "sf")) {
    return(ggplot())
  }
  
  args <- list(...)

  vars <- list(x = x, y = y)
  vars <- dropNulls(vars)

  if (!is.null(vars$x)) {
    xtype <- col_type(data[[vars$x]])
  } else {
    xtype <- NULL
  }
  if (!is.null(vars$y)) {
    ytype <- col_type(data[[vars$y]])
  } else {
    ytype <- NULL
  }
  if (!is.null(fill)) {
    filltype <- col_type(data[[fill]])
  } else {
    filltype <- NULL
  }
  if (!is.null(color)) {
    colortype <- col_type(data[[color]])
  } else {
    colortype <- NULL
  }

  # geom
  chartgeom <- guess_geom(
    xtype = xtype, 
    ytype = ytype, 
    type = type, 
    sfobj = inherits(data, what = "sf")
  )

  # aes
  chartaes <- guess_aes(
    x = x, 
    y = y, 
    fill = fill, 
    color = color, 
    size = size, 
    group = group, 
    geom = chartgeom, 
    xtype = xtype, 
    ytype = ytype
  )

  # Initialize chart
  p <- ggplot2::ggplot(data = data)
  p <- p + do.call(ggplot2::aes_, chartaes)

  paramsgeom <- list()

  # Bins for histogram
  if (chartgeom == "histogram" & !is.null(params$bins)) {
    paramsgeom$bins <- params$bins
  }
  
  if (chartgeom == "violin" & !is.null(params$scale)) {
    paramsgeom$scale <- params$scale
  }

  if (chartgeom %in% c("density", "violin") & !is.null(params$adjust)) {
    paramsgeom$adjust <- params$adjust
  }

  if (chartgeom %in% c("bar", "histogram", "boxplot", "violin", "density") & is.null(fill)) {
    paramsgeom$fill <- params$fill_color %||% "#0C4C8A"
  }
  if (chartgeom %in% c("line", "point") & is.null(color)) {
    paramsgeom$color <- params$fill_color %||% "#0C4C8A"
  }
  
  if (chartgeom %in% c("line", "point") & is.null(size)) {
    paramsgeom$size <- params$size %||% 1.6
  }

  if (chartgeom %in% c("bar")) {
    paramsgeom$position <- params$position %||% "dodge"
  }
  if (chartgeom %in% c("line", "area")) {
    paramsgeom$position <- params$position %||% "identity"
  }

  # scale fill
  # Default
  params_scale_fill <- NULL
  if (!is.null(fill)) {
    if (!is.null(params$palette)) {
      if (params$palette == "ggplot2") {
        if (filltype == "discrete") {
          params_scale_fill <- ggplot2::scale_fill_hue()
        } else {
          params_scale_fill <- ggplot2::scale_fill_gradient()
        }
      } else if (params$palette %in% c("viridis", "plasma", "magma", "cividis", "inferno")) {
        if (filltype == "discrete") {
          params_scale_fill <- ggplot2::scale_fill_viridis_d(option  = params$palette)
        } else {
          params_scale_fill <- ggplot2::scale_fill_viridis_c(option  = params$palette)
        }
      } else {
        if (filltype == "discrete") {
          params_scale_fill <- ggplot2::scale_fill_brewer(palette = params$palette)
        } else {
          params_scale_fill <- ggplot2::scale_fill_distiller(palette = params$palette)
        }
      }
    }
  }

  # scale color
  # Default
  params_scale_color <- NULL
  if (!is.null(color)) {
    if (!is.null(params$palette)) {
      if (params$palette == "ggplot2") {
        if (colortype == "discrete") {
          params_scale_color <- ggplot2::scale_color_hue()
        } else {
          params_scale_color <- ggplot2::scale_color_gradient()
        }
      } else if (params$palette %in% c("viridis", "plasma", "magma", "cividis", "inferno")) {
        if (colortype == "discrete") {
          params_scale_color <- ggplot2::scale_colour_viridis_d(option  = params$palette)
        } else {
          params_scale_color <- ggplot2::scale_colour_viridis_c(option  = params$palette)
        }
      } else {
        if (colortype == "discrete") {
          params_scale_color <- ggplot2::scale_color_brewer(palette = params$palette)
        } else {
          params_scale_color <- ggplot2::scale_color_distiller(palette = params$palette)
        }
      }
    }
  }


  if (chartgeom %in% c("point") & is.null(color)) {
    paramsgeom$color <- params$fill_color %||% "#0C4C8A"
  }

  # Add geom
  p <- p + do.call(paste0("geom_", chartgeom), paramsgeom)
  p <- p + ggplot2::labs(
    title = params$title, x = params$x %|e|% x, y = params$y %|e|% y,
    caption = params$caption, subtitle = params$subtitle
  )

  # Add facet
  if (!is.null(facet)) {
    p <- p + facet_wrap(facet)
  }
  
  if (!is.null(params_scale_fill)) {
    p <- p + params_scale_fill
  }
  if (!is.null(params_scale_color)) {
    p <- p + params_scale_color
  }

  # Flip coordinates for geom_bar
  if (chartgeom %in% c("bar")) {
    if (!is.null(params$flip) && params$flip) {
      p <- p + ggplot2::coord_flip()
    }
  }

  # Add smooth if geom_point
  if (chartgeom %in% c("point")) {
    if (!is.null(params$smooth_add) && params$smooth_add) {
      p <- p + ggplot2::geom_smooth(span = params$smooth_span)
    }
  }

  if (is.null(params$legend_position))
    params$legend_position <- "right"

  fun_theme <- params$theme %||% "theme_minimal"
  # themes <- ggplot_theme(c("ggplot2", "ggthemes"))
  p <- p + do.call.tommy(fun_theme, list(base_size = 12))
  p <- p + theme(plot.title = element_text(lineheight = .8, face = "bold"),
                 legend.position = params$legend_position)

  return(p)
}


# https://stackoverflow.com/questions/10022436/do-call-in-combination-with
# thanks Tommy

do.call.tommy <- function(what, args, ...) {
  if(is.character(what)){
    fn <- strsplit(what, "::")[[1]]
    what <- if(length(fn)==1) {
      get(fn[[1]], envir=parent.frame(), mode="function")
    } else {
      get(fn[[2]], envir=asNamespace(fn[[1]]), mode="function")
    }
  }
  
  do.call(what, as.list(args), ...)
}



#' Try to guess the appropriate aes
#'
#' @param x Variable to map in x
#' @param y Variable to map in y
#' @param fill Variable to map in fill
#' @param color Variable to map in color
#' @param size Variable to map in size
#' @param geom The geom to use
#' @param xtype Type of x variable
#' @param ytype Type of y variable
#'
#' @return result of a call to aes
#' @noRd
#'
#' @importFrom ggplot2 aes_
#' @importFrom stats as.formula
#' 
#' 
#' @examples 
#' guess_aes(x = "carat", xtype = "continuous")
#' 
#' guess_aes(x = "color", xtype = "discrete")
#' 
guess_aes <- function(x = NULL, y = NULL, fill = NULL, color = NULL, size = NULL, group = NULL, geom = "auto", xtype = NULL, ytype = NULL) {

  vars <- list(x = x, y = y, fill = fill, color = color, size = size, group = group)
  vars <- dropNulls(vars)

  # if (is.null(vars$fill)) {
  #   vars$fill <- "fill"
  # }
  # if (is.null(vars$color)) {
  #   if (type != "boxplot") {
  #     vars$color <- "color"
  #   }
  # }

  vars <- lapply(
    X = vars,
    FUN = function(x) {
      stats::as.formula(paste0("~", backticks(x)))
    }
  )

  # one var
  if (is.null(vars$x) & !is.null(vars$y) & geom == "line") {
    vars$x <- stats::as.formula(paste0("~seq_along(", y, ")"))
  }
  if (!is.null(vars$x) & is.null(vars$y) & geom %in% c("boxplot", "violin")) {
    vars$y <- vars$x
    vars$x <- ""
  }

  if (is.null(vars$x) & !is.null(vars$y) & geom %nin% c("boxplot", "violin")) {
    tmp <- vars$y
    vars$y <- vars$x
    vars$x <- tmp
  }

  # two var
  if (!is.null(vars$x) & !is.null(vars$y) & geom %in% c("boxplot", "violin")) {
    if (xtype == "continuous" & (!is.null(ytype) && ytype == "discrete")) {
      tmp <- vars$y
      vars$y <- vars$x
      vars$x <- tmp
    }
  }

  if (!is.null(vars$x) & !is.null(vars$y) & geom == "bar") {
    if (xtype == "continuous" & ytype == "discrete") {
      vars$weight <- vars$x
      vars$x <- vars$y
      vars$y <- NULL
    }
    if (xtype == "discrete" & ytype == "continuous") {
      vars$weight <- vars$y
      vars$y <- NULL
    }
  }

  return(vars)
}



#' Try to choose the proper geom accordingly to the variables
#'
#' @param xtype Type of the x variable (continuous, discrete, time).
#' @param ytype Type of the y variable (continuous, discrete, time).
#' @param type Type of chart
#'
#' @return a string containing the name of a geom
#' @noRd
#'
#' @importFrom ggplot2 geom_blank
#' 
#' @examples
#' 
#' guess_geom(xtype = "continuous")
#' 
#' guess_geom(xtype = "discrete")
#' 
#' guess_geom(xtype = "continuous", ytype = "continuous")
#' 
guess_geom <- function(xtype = NULL, ytype = NULL, type = "auto", sfobj = FALSE) {

  geom_cat <- ggplot_geom_vars()

  if (is.null(xtype) & !is.null(ytype)) {
    if (all(ytype %nin% "continuous")) {
      xtype <- ytype
      ytype <- "empty"
    } else {
      xtype <- "empty"
    }
  }
  if (!is.null(xtype) & is.null(ytype)) {
    ytype <- "empty"
  }

  restype <- geom_cat[geom_cat$x == xtype & geom_cat$y %in% ytype, ]

  if (type == "auto") {
    restype <- restype[restype$auto == 1, ]
  } else {
    restype <- restype[restype$geom == type, ]
  }

  if (nrow(restype) == 0) {
    if (sfobj) {
      geom <- "sf"
    } else {
      geom <- "blank"
    }
  } else {
    geom <- restype$geom
  }

  return(geom)
}




#' Possible geoms according to data type
#'
#' @param data a \code{data.frame}.
#' @param x character, variable name for x-axis.
#' @param y character, variable name for y-axis.
#'
#' @return character, geoms possible
#' @noRd
#'
#' @examples
#' 
#' data("mpg", package = "ggplot2")
#' 
#' # continuous
#' possible_geom(data = mpg, x = "cyl")
#' 
#' # discrete
#' possible_geom(data = mpg, x = "manufacturer")
#' 
#' # two continuous variables
#' possible_geom(data = mpg, x = "cyl", y = "displ")
#' 
possible_geom <- function(data, x = NULL, y = NULL) {

  vars <- list(x = x, y = y)
  vars <- dropNulls(vars)

  if (!is.null(vars$x)) {
    xtype <- col_type(data[[vars$x]], no_id = TRUE)
  } else {
    xtype <- NULL
  }
  if (!is.null(vars$y)) {
    ytype <- unlist(lapply(data[vars$y], col_type, no_id = TRUE))
  } else {
    ytype <- NULL
  }

  geom_cat <- ggplot_geom_vars()

  if (is.null(xtype) & !is.null(ytype)) {
    if (all(ytype %nin% "continuous")) {
      xtype <- ytype
      ytype <- "empty"
    } else {
      xtype <- "empty"
    }
  }
  if (!is.null(xtype) & is.null(ytype)) {
    ytype <- "empty"
  }

  geoms <- geom_cat[geom_cat$x == xtype & geom_cat$y %in% ytype, "geom"]
  
  if (inherits(data, what = "sf")) {
    geoms <- c(geoms, "sf")
  } 
  
  return(geoms)
}





#' @importFrom ggplot2 theme_bw theme_classic theme_dark theme_gray theme_grey 
#'  theme_light theme_linedraw theme_minimal theme_void
#' @importFrom ggthemes theme_base theme_calc theme_economist theme_economist_white 
#'  theme_excel theme_few theme_fivethirtyeight theme_foundation theme_gdocs theme_hc 
#'  theme_igray theme_map theme_pander theme_par theme_solarized theme_solarized_2 
#'  theme_solid theme_stata theme_tufte theme_wsj
ggplot_theme <- function(package = "ggplot2") {
  themes <- list(
    ggplot2 = c(
      "theme_bw", "theme_classic", "theme_dark", "theme_gray",
      "theme_grey", "theme_light", "theme_linedraw", "theme_minimal",
      "theme_void"
    ),
    ggthemes = c(
      "theme_base", "theme_calc", "theme_economist", "theme_economist_white",
      "theme_excel", "theme_few", "theme_fivethirtyeight", "theme_foundation",
      "theme_gdocs", "theme_hc", "theme_igray", "theme_map", "theme_pander",
      "theme_par", "theme_solarized", "theme_solarized_2", "theme_solid",
      "theme_stata", "theme_tufte", "theme_wsj"
    )
  )
  themes <- themes[package]
  themes <- lapply(X = names(themes), FUN = function(x) paste(x, themes[[x]], sep = "::"))
  res <- unlist(themes, use.names = FALSE)
  names(res) <- gsub(".*::theme_", "", res)
  res
}



#' @importFrom ggplot2 geom_histogram geom_density geom_bar geom_sf 
#' geom_boxplot geom_bar geom_point geom_line geom_tile geom_violin
#' geom_area
ggplot_geom_vars <- function() {
  x <- matrix(
    data = c(
      "continuous",  "empty",       "histogram", "1", 
      "continuous",  "empty",       "boxplot",   "0", 
      "continuous",  "empty",       "violin",    "0", 
      "continuous",  "empty",       "density",   "0", 
      "discrete",    "empty",       "bar",       "1", 
      "time",        "empty",       "histogram", "1",
      "continuous",  "discrete",    "boxplot",   "0", 
      "continuous",  "discrete",    "violin",    "0", 
      "continuous",  "discrete",    "bar",       "1",
      "discrete",    "continuous",  "boxplot",   "0", 
      "discrete",    "continuous",  "violin",    "0", 
      "discrete",    "continuous",  "bar",       "1",
      "continuous",  "continuous",  "point",     "1",
      "continuous",  "continuous",  "line",      "0", 
      "continuous",  "continuous",  "area",      "0",
      "discrete",    "discrete",    "tile",      "1",
      "time",        "continuous",  "line",      "1", 
      "time",        "continuous",  "area",      "0", 
      "empty",       "continuous",  "line",      "1",
      "empty",       "continuous",  "area",      "0",
      "continuous",  "continuous",  "tile",      "0",
      "discrete",    "time",        "tile",      "0",
      "time",        "discrete",    "tile",      "0"
    ), ncol = 4, byrow = TRUE
  )
  x <- data.frame(x, stringsAsFactors = FALSE)
  names(x) <- c("x", "y", "geom", "auto")
  x$auto <- as.numeric(x$auto)
  return(x)
}






