import { Controller } from "@hotwired/stimulus"

/**
 * Projection Chart Controller
 *
 * Renders an ApexCharts line chart showing projected account balance over time.
 *
 * Expected data format (array of monthly projection objects):
 * [
 *   {
 *     date: "2024-01-01",        // ISO date string
 *     balance: "1000.00",        // String or number, projected balance
 *     contribution: "100.00",    // String or number, monthly contribution
 *     interest: "5.00"           // String or number, interest earned
 *   },
 *   ...
 * ]
 */
export default class extends Controller {
  static values = {
    data: Array
  }

  connect() {
    // Check if ApexCharts library is available
    if (typeof ApexCharts === 'undefined') {
      console.error('ApexCharts library not loaded')
      return
    }

    if (!this.hasDataValue || this.dataValue.length === 0) {
      return
    }

    this.renderChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  renderChart() {
    const monthlyData = this.dataValue

    // Validate data structure
    const hasRequiredProperties = monthlyData.every(month =>
      month.hasOwnProperty('date') &&
      month.hasOwnProperty('balance') &&
      month.hasOwnProperty('contribution') &&
      month.hasOwnProperty('interest')
    )

    if (!hasRequiredProperties) {
      console.error('Invalid data format: missing required properties (date, balance, contribution, interest)')
      return
    }

    // Extract dates and build series data
    const dates = []
    const balances = []
    const cumulativeContributions = []
    const cumulativeInterest = []

    let contributionSum = 0
    let interestSum = 0

    monthlyData.forEach(month => {
      dates.push(this.formatDate(month.date))
      balances.push(parseFloat(month.balance))

      contributionSum += parseFloat(month.contribution)
      interestSum += parseFloat(month.interest)

      cumulativeContributions.push(contributionSum)
      cumulativeInterest.push(interestSum)
    })

    const options = {
      series: [
        {
          name: 'Projected Balance',
          data: balances,
          color: '#10b981'
        },
        {
          name: 'Cumulative Contributions',
          data: cumulativeContributions,
          color: '#3b82f6'
        },
        {
          name: 'Cumulative Interest',
          data: cumulativeInterest,
          color: '#9333ea'
        }
      ],
      chart: {
        type: 'line',
        height: 400,
        toolbar: {
          show: true,
          tools: {
            download: true,
            zoom: true,
            zoomin: true,
            zoomout: true,
            pan: true,
            reset: true
          }
        },
        animations: {
          enabled: true,
          speed: 800
        }
      },
      stroke: {
        width: [3, 2, 2],
        curve: 'smooth',
        dashArray: [0, 5, 5]
      },
      xaxis: {
        categories: dates,
        labels: {
          rotate: -45,
          rotateAlways: false,
          formatter: function(value, _timestamp, opts) {
            // Only show every 4th label
            return opts.dataPointIndex % 4 === 0 ? value : ''
          }
        }
      },
      yaxis: {
        labels: {
          formatter: (value) => {
            return '$' + value.toLocaleString('en-US', {
              minimumFractionDigits: 2,
              maximumFractionDigits: 2
            })
          }
        }
      },
      tooltip: {
        shared: true,
        intersect: false,
        y: {
          formatter: (value) => {
            return '$' + value.toLocaleString('en-US', {
              minimumFractionDigits: 2,
              maximumFractionDigits: 2
            })
          }
        }
      },
      legend: {
        position: 'top',
        horizontalAlign: 'right'
      },
      markers: {
        size: 0,
        hover: {
          size: 5
        }
      }
    }

    this.chart = new ApexCharts(this.element, options)
    this.chart.render()
  }

  formatDate(dateString) {
    const date = new Date(dateString)
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    return `${monthNames[date.getMonth()]} ${date.getFullYear()}`
  }
}
