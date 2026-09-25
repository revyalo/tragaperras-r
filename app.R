required_packages <- c("shiny", "ggplot2")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop(
    "Install the app dependencies first: install.packages(c(",
    paste(sprintf("\"%s\"", missing_packages), collapse = ", "),
    "))"
  )
}

invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))

machine <- create_machine()
theory <- theoretical_summary(machine)

metric_card <- function(title, output_id, suffix = NULL) {
  shiny::div(
    class = "metric-card",
    shiny::div(class = "metric-title", title),
    shiny::div(class = "metric-value", shiny::textOutput(output_id, inline = TRUE), suffix)
  )
}

ui <- shiny::fluidPage(
  shiny::tags$head(
    shiny::tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    shiny::includeCSS("www/style.css")
  ),
  shiny::div(
    class = "page-shell",
    shiny::div(
      class = "hero",
      shiny::div(
        shiny::span(class = "eyebrow", "PROBABILIDAD · MONTE CARLO · R"),
        shiny::h1("Tragaperras estadística"),
        shiny::p(
          "Una máquina transparente: cada premio se puede explicar, enumerar y verificar."
        )
      ),
      shiny::div(class = "hero-mark", "70%")
    ),
    shiny::tabsetPanel(
      id = "main_tab",
      type = "tabs",
      shiny::tabPanel(
        "Jugar",
        shiny::div(
          class = "dashboard-grid game-layout",
          shiny::div(
            class = "panel game-panel",
            shiny::div(
              class = "panel-heading",
              shiny::div(
                shiny::span(class = "section-kicker", "TIRADA DE 1 EUR"),
                shiny::h2("Prueba la máquina")
              ),
              shiny::actionButton("reset_game", "Reiniciar", class = "btn-secondary")
            ),
            shiny::uiOutput("reels"),
            shiny::uiOutput("spin_message"),
            shiny::actionButton("spin", "Girar rodillos", class = "spin-button")
          ),
          shiny::div(
            class = "side-stack",
            shiny::div(
              class = "metrics-row compact",
              metric_card("Saldo", "balance_value", " EUR"),
              metric_card("Último premio", "last_prize", " EUR")
            ),
            shiny::div(
              class = "panel",
              shiny::span(class = "section-kicker", "ULTIMAS TIRADAS"),
              shiny::tableOutput("recent_spins")
            )
          )
        )
      ),
      shiny::tabPanel(
        "Simulación",
        shiny::div(
          class = "control-strip",
          shiny::selectInput(
            "simulation_n",
            "Número de tiradas",
            choices = c("10.000" = 10000, "100.000" = 100000, "1.000.000" = 1000000),
            selected = 100000
          ),
          shiny::numericInput("simulation_seed", "Semilla", value = 2026, min = 1, step = 1),
          shiny::actionButton("run_simulation", "Ejecutar simulación", class = "run-button"),
          shiny::downloadButton("download_simulation", "Descargar CSV", class = "download-button")
        ),
        shiny::uiOutput("simulation_placeholder"),
        shiny::conditionalPanel(
          condition = "output.simulation_ready",
          shiny::div(
            class = "metrics-row",
            metric_card("RTP observado", "observed_rtp", "%"),
            metric_card("RTP teórico", "theoretical_rtp", "%"),
            metric_card("Premios", "observed_hit_rate", "%"),
            metric_card("Beneficio banca", "house_profit", " EUR")
          ),
          shiny::div(
            class = "chart-grid",
            shiny::div(class = "panel", shiny::h3("Convergencia del RTP"), shiny::plotOutput("rtp_plot")),
            shiny::div(class = "panel", shiny::h3("Teoria frente a simulación"), shiny::plotOutput("frequency_plot"))
          ),
          shiny::div(class = "panel", shiny::h3("Resultados por categoría"), shiny::tableOutput("simulation_table"))
        )
      ),
      shiny::tabPanel(
        "Modelo",
        shiny::div(
          class = "metrics-row",
          metric_card("Resultados posibles", "outcome_count"),
          metric_card("RTP exacto", "model_rtp", "%"),
          metric_card("Ventaja de la banca", "house_edge", "%"),
          metric_card("Probabilidad de premio", "hit_rate", "%")
        ),
        shiny::div(
          class = "model-grid",
          shiny::div(
            class = "panel",
            shiny::span(class = "section-kicker", "MODELO EXACTO"),
            shiny::h2("Las 625 combinaciones cuentan"),
            shiny::p(
              "La aplicación enumera 5^4 resultados ordenados. La probabilidad de cada uno es el producto de las probabilidades de sus cuatro símbolos; no depende de una aproximacion."
            ),
            shiny::tableOutput("probability_table")
          ),
          shiny::div(
            class = "panel",
            shiny::span(class = "section-kicker", "TABLA OPTIMIZADA"),
            shiny::h2("Premios enteros, objetivo medible"),
            shiny::p(
              "El buscador recorre tablas con una jerarquía de premios válida y ordena las candidatas por distancia al RTP objetivo."
            ),
            shiny::tableOutput("optimizer_table")
          )
        )
      )
    ),
    shiny::div(
      class = "footer-note",
      "Proyecto educativo. El RTP describe el promedio a largo plazo y no garantiza el resultado de una sesion."
    )
  )
)

server <- function(input, output, session) {
  balance <- shiny::reactiveVal(100)
  last_spin <- shiny::reactiveVal(NULL)
  history <- shiny::reactiveVal(data.frame(
    Tirada = integer(), Resultado = character(), Premio = numeric()
  ))

  output$balance_value <- shiny::renderText(sprintf("%.2f", balance()))
  output$last_prize <- shiny::renderText({
    spin <- last_spin()
    sprintf("%.2f", if (is.null(spin)) 0 else spin$prize)
  })
  output$reels <- shiny::renderUI({
    spin <- last_spin()
    emojis <- if (is.null(spin)) rep("?", machine$reels) else spin$emoji
    shiny::div(
      class = "reels",
      lapply(emojis, function(emoji) shiny::div(class = "reel", emoji))
    )
  })
  output$spin_message <- shiny::renderUI({
    spin <- last_spin()
    if (is.null(spin)) {
      return(shiny::div(class = "spin-message muted", "Pulsa el boton para realizar la primera tirada."))
    }
    css_class <- if (spin$prize > 0) "spin-message win" else "spin-message loss"
    shiny::div(
      class = css_class,
      shiny::strong(spin$label),
      shiny::span(sprintf("Premio: %.2f EUR", spin$prize))
    )
  })

  shiny::observeEvent(input$spin, {
    if (balance() < machine$stake) {
      shiny::showNotification("No queda saldo suficiente. Reinicia la partida.", type = "warning")
      return()
    }
    spin <- spin_machine(machine)
    last_spin(spin)
    balance(balance() + spin$net)
    previous <- history()
    history(rbind(
      data.frame(
        Tirada = nrow(previous) + 1L,
        Resultado = paste(spin$emoji, collapse = " "),
        Premio = spin$prize,
        check.names = FALSE
      ),
      previous
    ))
  })

  shiny::observeEvent(input$reset_game, {
    balance(100)
    last_spin(NULL)
    history(data.frame(Tirada = integer(), Resultado = character(), Premio = numeric()))
  })

  output$recent_spins <- shiny::renderTable({
    data <- history()
    if (!nrow(data)) {
      return(data.frame(Estado = "Todavía no hay tiradas"))
    }
    head(data, 6L)
  }, striped = TRUE, bordered = FALSE, spacing = "s", rownames = FALSE)

  output$outcome_count <- shiny::renderText(theory$outcomes)
  output$model_rtp <- shiny::renderText(sprintf("%.6f", 100 * theory$rtp))
  output$house_edge <- shiny::renderText(sprintf("%.6f", 100 * theory$house_edge))
  output$hit_rate <- shiny::renderText(sprintf("%.4f", 100 * theory$hit_rate))
  output$probability_table <- shiny::renderTable({
    data.frame(
      Resultado = theory$categories$label,
      Probabilidad = sprintf("%.6f %%", theory$categories$percentage),
      Premio = sprintf("%.0f EUR", theory$categories$prize),
      check.names = FALSE
    )
  }, striped = TRUE, rownames = FALSE)
  output$optimizer_table <- shiny::renderTable({
    candidates <- find_integer_paytable(machine, target_rtp = 0.70, max_results = 5)
    data.frame(
      `4 pandas` = candidates$four_pandas,
      `3 pandas` = candidates$three_pandas,
      `4 comunes` = candidates$four_common,
      `3 comunes` = candidates$three_common,
      `RTP` = sprintf("%.6f %%", 100 * candidates$rtp),
      check.names = FALSE
    )
  }, striped = TRUE, rownames = FALSE)

  simulation <- shiny::reactiveVal(NULL)
  shiny::observeEvent(input$run_simulation, {
    shiny::withProgress(message = "Simulando tiradas...", value = 0, {
      shiny::incProgress(0.2)
      result <- simulate_spins(
        machine,
        n = as.integer(input$simulation_n),
        seed = as.integer(input$simulation_seed)
      )
      shiny::incProgress(0.8)
      simulation(result)
    })
  })
  output$simulation_ready <- shiny::reactive(!is.null(simulation()))
  shiny::outputOptions(output, "simulation_ready", suspendWhenHidden = FALSE)
  output$simulation_placeholder <- shiny::renderUI({
    if (is.null(simulation())) {
      shiny::div(
        class = "empty-state",
        shiny::div(class = "empty-icon", "∿"),
        shiny::h3("La simulación está preparada"),
        shiny::p("Elige el numero de tiradas y una semilla reproducible.")
      )
    }
  })

  simulation_metrics <- shiny::reactive({
    shiny::req(simulation())
    simulation_summary(simulation(), machine)
  })
  output$observed_rtp <- shiny::renderText(sprintf("%.4f", 100 * simulation_metrics()$observed_rtp))
  output$theoretical_rtp <- shiny::renderText(sprintf("%.4f", 100 * theory$rtp))
  output$observed_hit_rate <- shiny::renderText(sprintf("%.4f", 100 * simulation_metrics()$observed_hit_rate))
  output$house_profit <- shiny::renderText(format(
    round(simulation_metrics()$house_profit, 2),
    big.mark = ".",
    decimal.mark = ",",
    nsmall = 2
  ))

  output$rtp_plot <- shiny::renderPlot({
    data <- simulation()
    shiny::req(data)
    cumulative_rtp <- cumsum(data$prize) / (seq_len(nrow(data)) * machine$stake)
    keep <- unique(round(seq(1, nrow(data), length.out = min(2500L, nrow(data)))))
    plot_data <- data.frame(spin = keep, rtp = cumulative_rtp[keep])
    ggplot2::ggplot(plot_data, ggplot2::aes(spin, 100 * rtp)) +
      ggplot2::geom_hline(yintercept = 100 * theory$rtp, color = "#f4c95d", linewidth = 0.9) +
      ggplot2::geom_line(color = "#4ee1a0", linewidth = 0.8) +
      ggplot2::labs(x = "Tirada", y = "RTP acumulado (%)") +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(
        panel.grid.minor = ggplot2::element_blank(),
        plot.background = ggplot2::element_rect(fill = "transparent", color = NA),
        panel.background = ggplot2::element_rect(fill = "transparent", color = NA)
      )
  }, bg = "transparent")

  output$frequency_plot <- shiny::renderPlot({
    summary <- simulation_metrics()$categories
    plot_data <- rbind(
      data.frame(label = summary$label, source = "Teórica", probability = summary$probability),
      data.frame(label = summary$label, source = "Observada", probability = summary$observed_probability)
    )
    ggplot2::ggplot(
      plot_data,
      ggplot2::aes(stats::reorder(label, probability), 100 * probability, fill = source)
    ) +
      ggplot2::geom_col(position = "dodge") +
      ggplot2::coord_flip() +
      ggplot2::scale_fill_manual(values = c("Teórica" = "#f4c95d", "Observada" = "#4ee1a0")) +
      ggplot2::labs(x = NULL, y = "Probabilidad (%)", fill = NULL) +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(
        legend.position = "top",
        panel.grid.minor = ggplot2::element_blank(),
        plot.background = ggplot2::element_rect(fill = "transparent", color = NA),
        panel.background = ggplot2::element_rect(fill = "transparent", color = NA)
      )
  }, bg = "transparent")

  output$simulation_table <- shiny::renderTable({
    summary <- simulation_metrics()$categories
    data.frame(
      Resultado = summary$label,
      Teórica = sprintf("%.6f %%", 100 * summary$probability),
      Observada = sprintf("%.6f %%", 100 * summary$observed_probability),
      Frecuencia = format(summary$observed_count, big.mark = "."),
      check.names = FALSE
    )
  }, striped = TRUE, rownames = FALSE)

  output$download_simulation <- shiny::downloadHandler(
    filename = function() sprintf("simulación-%s.csv", Sys.Date()),
    content = function(file) {
      shiny::req(simulation())
      utils::write.csv(simulation(), file, row.names = FALSE)
    }
  )
}

shiny::shinyApp(ui, server)
