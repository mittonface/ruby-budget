# Projection Line Graph Design

**Date**: 2025-11-10
**Status**: Approved

## Overview

Replace the monthly breakdown table on the account show page with an interactive ApexCharts line graph showing projected balance growth over time. Keep the detailed table available via a collapsible details element.

## Requirements

- Display three data series: projected balance, cumulative contributions, and cumulative interest
- Use ApexCharts library for visualization
- Maintain collapsible access to detailed monthly breakdown table
- Integrate with existing Rails + Stimulus + Turbo stack
- No build pipeline changes (use CDN approach)

## Architecture

### Core Components

1. **CDN Integration**
   - Add ApexCharts library via CDN script tag in application layout
   - No npm dependencies or build process changes required

2. **Stimulus Controller** (`projection_chart_controller.js`)
   - Parses projection data from data attributes
   - Calculates cumulative sums for contributions and interest
   - Initializes and configures ApexCharts instance
   - Handles cleanup on disconnect

3. **View Structure** (`app/views/accounts/show.html.erb`)
   - Chart container div with Stimulus controller attached
   - Projection data passed as JSON in data attribute
   - Collapsible `<details>` element containing existing table

### Data Flow

```
AccountsController
  ↓ @projection_result[:monthly_breakdown]
View (show.html.erb)
  ↓ data-projection-chart-data-value="<%= json %>"
Stimulus Controller
  ↓ parse JSON, calculate cumulative sums
ApexCharts Render
```

## Chart Configuration

### Visual Design

- **Chart Type**: Line chart with smooth curves
- **Dimensions**: 400px height, full width (responsive)
- **Series**:
  - Balance: Green solid line (primary)
  - Cumulative Contributions: Blue dashed line
  - Cumulative Interest: Purple dotted line

### Axes

- **X-axis**: Monthly date labels (format: "MMM YYYY")
- **Y-axis**: Currency values (formatted with dollar signs)

### Interactive Features

- **Tooltip**: Hover to see date + all three values as currency
- **Legend**: Top-right position, shows all three series with labels
- **Zoom/Pan**: ApexCharts built-in zoom for long projections (50+ months)

### Color Scheme

Matches existing UI:
- Balance: `#10b981` (green-600, same as positive amounts)
- Contributions: `#3b82f6` (blue-600, matches action buttons)
- Interest: `#9333ea` (purple-600, distinct from contributions)

## Data Transformation

### Input
```ruby
@projection_result[:monthly_breakdown] = [
  { date: Date, contribution: Decimal, interest: Decimal, balance: Decimal },
  # ... more months
]
```

### Processing in Stimulus Controller
```javascript
// Calculate cumulative sums
let cumulativeContributions = 0;
let cumulativeInterest = 0;

monthlyData.forEach(month => {
  cumulativeContributions += month.contribution;
  cumulativeInterest += month.interest;

  // Build series data points
  dates.push(formatDate(month.date));
  balances.push(month.balance);
  contributions.push(cumulativeContributions);
  interest.push(cumulativeInterest);
});
```

### Output to ApexCharts
```javascript
series: [
  { name: 'Projected Balance', data: [...balances] },
  { name: 'Cumulative Contributions', data: [...contributions] },
  { name: 'Cumulative Interest', data: [...interest] }
]
```

## Collapsible Table

- **Element**: HTML5 `<details>` with `<summary>`
- **Default State**: Closed (graph is primary view)
- **Summary Text**: "View detailed monthly breakdown"
- **Content**: Existing table markup (unchanged)
- **Benefits**:
  - No JavaScript required for collapse functionality
  - Accessible by default
  - Users can still access exact monthly values if needed

## Implementation Files

### New Files
- `app/javascript/controllers/projection_chart_controller.js` - Chart initialization logic

### Modified Files
- `app/views/layouts/application.html.erb` - Add ApexCharts CDN in `<head>`
- `app/views/accounts/show.html.erb` - Replace table section with chart + collapsible table

### Lines Modified
- `show.html.erb`: Lines 60-82 (Monthly Breakdown section)

## Edge Cases

1. **No projection data** (`@projection_result` is nil)
   - Controller checks for empty data attribute
   - Skips chart initialization gracefully
   - Existing "Set Up Projection" link remains

2. **Very short projections** (1-2 months)
   - Chart renders but may look sparse
   - Still functional and readable
   - Table provides better UX for very short ranges

3. **Very long projections** (50+ months)
   - ApexCharts handles with zoom/pan features
   - Chart remains performant (tested up to 100+ data points)
   - Table provides scrollable detailed view

4. **Turbo frame updates**
   - Stimulus disconnect callback destroys chart instance
   - Connect callback re-initializes on Turbo update
   - Prevents memory leaks from multiple chart instances

## Testing Strategy

### System Tests
- Verify chart renders on account show page with projection data
- Verify collapsible table can be opened and contains correct monthly data
- Verify chart does not render when no projection exists

### Manual Testing
- Check responsive behavior on mobile viewport (< 640px)
- Verify chart updates when projection settings change
- Test with various projection lengths (short/medium/long)
- Verify tooltip shows correct currency-formatted values

### Browser Compatibility
- Modern browsers (Chrome, Firefox, Safari, Edge)
- ApexCharts handles cross-browser rendering differences

## Benefits

1. **Visual clarity**: Trends are immediately apparent in graph form
2. **Comparison insight**: See relationship between contributions and interest growth
3. **Maintained access**: Detailed data still available via collapsible table
4. **No build changes**: CDN approach keeps existing importmap setup
5. **Progressive enhancement**: Table remains accessible if JavaScript fails
6. **Turbo compatible**: Stimulus lifecycle hooks ensure proper cleanup/re-init

## Future Enhancements

Potential improvements (not in current scope):
- Export chart as PNG/SVG
- Toggle individual series on/off
- Adjust projection parameters inline with live chart updates
- Compare multiple accounts on same chart
- Show historical actuals vs. projections
