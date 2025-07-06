import { Controller } from "@hotwired/stimulus"
import ApexCharts from "apexcharts"

export default class extends Controller {
  static targets = ["teamGoals", "teamGoalsJardindelzen"]
  static values = {
    teamGoals: Object,
    teamGoalsJardindelzen: Object
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
    }, 400)
  }

  initializeChart() {
    console.log("Initializing chart")
    this.destroyChart() // Ensure any existing chart is destroyed before creating a new one
    
    // Only initialize teamGoals chart if both the value and target exist
    if (this.hasTeamGoalsValue && this.hasTeamGoalsTarget) {
      this.initializeTeamGoalsChart()
    } else if (this.hasTeamGoalsValue) {
      console.warn("Team goals target not found, but value exists")
    }
    
    // Only initialize teamGoalsJardindelzen chart if both the value and target exist
    if (this.hasTeamGoalsJardindelzenValue && this.hasTeamGoalsJardindelzenTarget) {
      this.initializeTeamGoalsJardindelzenChart()
    } else if (this.hasTeamGoalsJardindelzenValue) {
      console.warn("Jardín del Zen team goals target not found, but value exists")
    }
  }

  destroyChart() {
    console.log("Destroying chart")
    if (this.teamGoalsChart) {
      this.teamGoalsChart.destroy()
      this.teamGoalsChart = null
    }
    
    if (this.teamGoalsJardindelzenChart) {
      this.teamGoalsJardindelzenChart.destroy()
      this.teamGoalsJardindelzenChart = null
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
  
  initializeTeamGoalsJardindelzenChart() {
    console.log("Initializing Jardín del Zen team goals chart")
    if (this.teamGoalsJardindelzenTarget) {
      const options = this.getTeamGoalsJardindelzenChartOptions()
      this.teamGoalsJardindelzenChart = new ApexCharts(this.teamGoalsJardindelzenTarget, options)
      this.teamGoalsJardindelzenChart.render()
    } else {
      console.warn("Jardín del Zen team goals target not found")
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
        },
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
  
  getTeamGoalsJardindelzenChartOptions() {
    const { series, annotations, maxYAxis } = this.teamGoalsJardindelzenValue
    
    // Get current date to determine which half of the month we're in
    const currentDate = new Date();
    const currentDay = currentDate.getDate();
    
    // Set min and max dates for x-axis based on which half of the month we're in
    let minDate, maxDate;
    if (currentDay <= 15) {
      // First half of the month (1st to 15th)
      minDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1).getTime();
      maxDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 15).getTime();
    } else {
      // Second half of the month (16th to end)
      minDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 16).getTime();
      maxDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0).getTime();
    }

    return {
      series,
      chart: {
        type: "line",
        height: '100%',
        width: '100%',
        parentHeightOffset: 0,
        toolbar: {
          show: false
        },
      },
      stroke: {
        curve: 'smooth',
        width: 3
      },
      xaxis: {
        type: 'datetime',
        min: minDate, // First day of current 15-day period
        max: maxDate  // Last day of current 15-day period
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
      colors: ["#00E396"],
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

  teamGoalsValueChanged() {
    console.log("Team goals value changed")
    if (this.hasTeamGoalsTarget) {
      this.updateTeamGoalsChart()
    }
  }
  
  teamGoalsJardindelzenValueChanged() {
    console.log("Jardín del Zen team goals value changed")
    if (this.hasTeamGoalsJardindelzenTarget) {
      this.updateTeamGoalsJardindelzenChart()
    }
  }

  updateTeamGoalsChart() {
    console.log("Updating team goals chart")
    if (this.teamGoalsChart) {
      const options = this.getTeamGoalsChartOptions()
      this.teamGoalsChart.updateOptions(options)
    } else if (this.hasTeamGoalsTarget) {
      this.initializeTeamGoalsChart()
    }
  }
  
  updateTeamGoalsJardindelzenChart() {
    console.log("Updating Jardín del Zen team goals chart")
    if (this.teamGoalsJardindelzenChart) {
      const options = this.getTeamGoalsJardindelzenChartOptions()
      this.teamGoalsJardindelzenChart.updateOptions(options)
    } else if (this.hasTeamGoalsJardindelzenTarget) {
      this.initializeTeamGoalsJardindelzenChart()
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
    
    if (this.teamGoalsJardindelzenChart) {
      this.teamGoalsJardindelzenChart.updateOptions({
        chart: {
          width: '100%'
        }
      })
    }
  }
}