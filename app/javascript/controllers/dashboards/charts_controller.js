import { Controller } from "@hotwired/stimulus"
import ApexCharts from "apexcharts"

export default class extends Controller {
  static targets = ["teamGoals"]
  static values = {
    teamGoals: Object
  }

  connect() {
    console.log("Charts controller connected")
    this.initializeChart()
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener('resize', this.handleResize)

    // Add event listener for dashboard refresh
    this.handleDashboardRefresh = this.handleDashboardRefresh.bind(this)
    document.addEventListener('dashboardRefreshed', this.handleDashboardRefresh)

  }

  disconnect() {
    console.log("Charts controller disconnected")
    this.destroyChart()
    window.removeEventListener('resize', this.handleResize)
  }

  handleDashboardRefresh() {
    console.log("Dashboard refreshed, reinitializing chart")
    // Add a small delay before initializing the chart
    setTimeout(() => {
      this.initializeChart()
      // Force a resize after initialization
      this.handleResize()
    }, 200)
  }

  initializeChart() {
    console.log("Initializing chart")
    this.destroyChart() // Ensure any existing chart is destroyed before creating a new one
    if (this.hasTeamGoalsValue) {
      this.initializeTeamGoalsChart()
    } else {
      console.warn("Chart data not available yet")
    }
  }

  destroyChart() {
    console.log("Destroying chart")
    if (this.teamGoalsChart) {
      this.teamGoalsChart.destroy()
      this.teamGoalsChart = null
    }
  }

  initializeTeamGoalsChart() {
    console.log("Initializing team goals chart")
    if (this.teamGoalsTarget) {
      const options = this.getTeamGoalsChartOptions()
      this.teamGoalsChart = new ApexCharts(this.teamGoalsTarget, options)
      this.teamGoalsChart.render()
    } else {
      console.warn("Team goals target not found")
    }
  }

  getTeamGoalsChartOptions() {
    const { series, annotations, maxYAxis } = this.teamGoalsValue

    return {
      series,
      chart: {
        type: "line",
        height: '100%',
        width: '100%',
        parentHeightOffset: 0,
        toolbar: {
          show: false
        }
      },
      stroke: {
        curve: 'stepline',
        width: [0, 2]
      },
      plotOptions: {
        bar: {
          columnWidth: '60%'
        }
      },
      xaxis: {
        type: 'datetime',
        min: new Date(new Date().getFullYear(), new Date().getMonth(), 1).getTime(), // First day of current month
        max: new Date().getTime() // Today
      },
      yaxis: {
        title: {
          text: 'Ventas acumuladas'
        },
        min: 0,
        max: maxYAxis,
        tickAmount: 5,
        labels: {
          formatter: (value) => `S/ ${parseFloat(value).toFixed(0)}`
        }
      },
      annotations: {
        yaxis: annotations.yaxis.map(annotation => {
          const yValue = parseFloat(annotation.y);
          return {
            y: yValue,
            borderColor: '#00E396',
            label: {
              borderColor: '#00E396',
              style: {
                color: '#fff',
                background: '#00E396'
              },
              text: `${annotation.label.text} (S/ ${yValue.toFixed(0)})`
            }
          };
        })
      },
      dataLabels: {
        enabled: false
      },
      colors: ["#4f46e5", "#00E396"],
      title: {
        text: '',
        align: 'center',
        style: { color: "#333333" }
      },
      tooltip: {
        shared: true,
        intersect: false,
        x: {
          format: 'dd MMM'
        },
        y: {
          formatter: (value) => `S/ ${parseFloat(value).toFixed(2)}`
        }
      },
      legend: {
        horizontalAlign: 'left'
      }
    }
  }

  handleResize() {
    if (this.teamGoalsChart) {
      this.teamGoalsChart.updateOptions({
        chart: {
          width: '100%'
        }
      })
    }
  }

  teamGoalsValueChanged() {
    console.log("Team goals value changed")
    this.updateTeamGoalsChart()
  }

  updateTeamGoalsChart() {
    console.log("Updating team goals chart")
    if (this.teamGoalsChart) {
      const options = this.getTeamGoalsChartOptions()
      this.teamGoalsChart.updateOptions(options)
    } else {
      this.initializeTeamGoalsChart()
    }
  }
}