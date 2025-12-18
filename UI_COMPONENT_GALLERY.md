# Liquid Glass UI Component Gallery

## Visual Component Showcase

This document describes the visual appearance and usage of each UI component.

---

## 🎨 Base Components

### GlassView
**Purpose**: Base container for all glass-morphic elements

**Visual Features**:
- Semi-transparent frosted glass background
- Gradient overlay (white opacity 0.1-0.15 with subtle direction)
- Gradient border (light highlights on top-left fading to bottom-right)
- Smooth hover state brightening
- Corner radius: 20pt (customizable)

**Usage**:
```swift
GlassView {
    VStack {
        Text("Content goes here")
    }
    .padding()
}
```

**Typical Colors**: Translucent white/glass effect over dark background

---

## 📊 Metric Display Components

### CircularGaugeView
**Purpose**: Display metrics as circular progress indicators

**Visual Features**:
- Circular gauge with gradient stroke
- Animated value transitions
- Center text showing percentage
- Rotating animation from top (270 degrees)
- Size: 70pt diameter (in dashboard)

**Appearance**: Blue circle for CPU, Red circle for RAM with gradient from bright to dark

**Mock Data Example**: CPU 45%, RAM 68%

**Usage**:
```swift
CircularGaugeView(
    value: 45.5,
    total: 100,
    label: "CPU",
    color: .blue,
    size: 70
)
```

---

### MetricProgressBar
**Purpose**: Linear progress indicator for detailed metrics

**Visual Features**:
- Label on left with icon
- Percentage on right
- Linear gradient fill
- Height: 6pt
- Rounded ends

**Colors**: Gradient from bright color to darker shade

**Example**: Shows CPU System (12.3%), User (33.2%), Idle (54.5%)

---

### ResourceMetricView
**Purpose**: Comprehensive resource metric card

**Visual Features**:
- GlassView container
- Icon + title in header
- Large percentage value (right side)
- Subtitle with description
- Divider separator
- Detailed metrics list below

**Components Shown**:
- For CPU: System %, User %, Idle %
- For RAM: Used GB, Available GB

**Example Data**:
- CPU Usage 45.5% - "System is performing well"
- Memory Usage 68.2% - "11.2 GB of 16.0 GB used"

---

## 🔄 Process Monitoring Components

### ProcessListView
**Purpose**: Display top processes for a specific metric

**Visual Features**:
- GlassView container
- Title with icon
- Divider separator
- Up to 4 process entries
- Animated progress bars

**Each Process Shows**:
- Icon (SF Symbol)
- Process name (truncated if needed)
- Mini progress bar
- Usage percentage (right aligned)

**Example Processes**:
- Safari 45.5%
- Chrome 32.1%
- Xcode 28.7%
- Mail 12.3%

**Colors**: Blue for CPU processes, Red for memory processes

---

## 🌐 Network Components

### NetworkCardView
**Purpose**: Display network interface status and speeds

**Visual Features**:
- Small GlassView container (12pt corner radius)
- Network icon + name
- Connection status indicator (green dot if connected, red if not)
- Upload speed with ↑ arrow (orange color)
- Download speed with ↓ arrow (blue color)

**Status Indicators**:
- Green = Connected (Wi-Fi)
- Red = Disconnected (Ethernet)

**Speed Formatting**:
- Automatic conversion to KB/s, MB/s
- Example: 5.0 MB/s ↓, 512 KB/s ↑

---

## ⚡ Quick Stats Components

### QuickStatsView
**Purpose**: At-a-glance statistics bar

**Visual Features**:
- Horizontal layout
- 4 stat columns (CPU, RAM, Download, Upload)
- Compact icons
- Large usage values
- Small labels below
- Light background (0.05 opacity)

**Example Display**:
```
┌─────────────────────────────┐
│ CPU   RAM    Down   Up      │
│ 45%   68%    5.2MB  512KB   │
└─────────────────────────────┘
```

---

### CompactMetricWidgetView
**Purpose**: Flexible metric display in compact or expanded mode

**Compact Mode**:
- Minimal height
- Icon + percentage
- Tiny progress bar (3pt)
- Label below

**Expanded Mode**:
- Icon + label on left
- Percentage on right
- Larger progress bar (8pt)
- Proportional spacing

---

## 💚 Status & Health Components

### SystemDashboardSummary
**Purpose**: Overall system health evaluation

**Visual Features**:
- GlassView container
- Status icon (varies by health)
- Health label + subtitle
- Quick stats grid with 3 sections:
  - CPU (blue icon + value)
  - Memory (red icon + value)
  - Network (green icon or X if offline)

**Health States**:
- **Healthy** (green checkmark): <60% average usage
- **Warning** (orange triangle): 60-80% average usage
- **Critical** (red X): >80% average usage

**Example**: "System Healthy" / "System Warning" / "System Critical"

---

### StatusIndicatorView
**Purpose**: Status badge with icon and message

**Visual Features**:
- Status icon (varies by state)
- Title + description text
- Rounded background
- Slight transparency
- Status-specific colors

**Three States**:
- Optimal (green) - "System performing optimally"
- Warning (orange) - "Monitor system resources"
- Critical (red) - "Immediate attention needed"

---

### RefreshIndicatorView
**Purpose**: Show update status and refresh timing

**Visual Features**:
- Animated spinning circle (0.7 radius visible)
- "Updating" label
- Time since last update
- Smooth rotation animation

**Display Example**:
- Shows "Just now" / "5m ago" / "1h ago"
- Continuous smooth rotation
- Updates every second

---

## 📈 Layout & Structure Components

### HeaderView
**Purpose**: Dashboard header with branding

**Visual Features**:
- Title "System Monitor" (title2 font)
- Subtitle "Real-time metrics" (caption, secondary color)
- Pulsing status indicator on right
- Animated pulse effect (1.5s loop)

**Status Indicator**:
- Green filled circle (8pt)
- Animated outer ring
- Pulses to show active monitoring

---

### QuickStatItem
**Purpose**: Individual stat in QuickStatsView

**Visual Features**:
- Vertical layout
- Icon (centered)
- Large value text
- Small label below
- Centered alignment

**Colors**: Color-coded by metric type

---

### FooterView
**Purpose**: Application footer with controls

**Visual Features**:
- Top divider
- Update timestamp section (left)
- Update frequency section (right)
- Two buttons: Settings, Quit
- Compact layout

**Display Elements**:
- "Last Updated: 2:34 PM" format
- "Update Rate: Every 1s"
- Button styling (borderless)

---

## 🎬 Animation & Styling Components

### AnimatedStatView
**Purpose**: Metric with pulsing animation

**Visual Features**:
- Vertical layout
- Icon with pulsing scale effect
- Large value (bold)
- Label below
- Repeating 2s animation

**Animation**: Scale 1.0 → 1.1 → 1.0 (easeInOut, repeats)

---

### TransitionHelpers
**Purpose**: Custom transitions for view changes

**Available Transitions**:
1. `glassSlide` - Bottom slide + fade (insertion), bottom slide + fade (removal)
2. `glassScale` - Scale 0.9 + fade (insertion), scale 0.9 + fade (removal)

**Button Style**: `ScaleButtonStyle`
- Scales to 0.95 on press
- Fades opacity to 0.8 on press
- 0.2s animation

---

## 🎨 Theme & Design Components

### ThemeHelper
**Purpose**: Centralized design tokens

**Color Palette**:
```
CPU:     Blue (#5AC8FA)
Memory:  Red (#FF2D55)
Network: Green (#00D084)
Storage: Orange (#FF9500)
System:  Purple (#5856D6)
```

**Corner Radii**:
- Large: 20pt (primary cards)
- Medium: 12pt (secondary cards)
- Small: 8pt (info badges)

**Spacing**:
- XS: 4pt
- SM: 8pt
- MD: 12pt
- LG: 16pt
- XL: 20pt
- XXL: 24pt

---

### BlurView
**Purpose**: Additional blur effect utilities

**Features**:
- NSViewRepresentable blur
- Customizable blur radius
- ModernBlurView wrapper with glass styling
- Background blur effect

---

## 🎪 Content Organization

### CollapsibleSectionView
**Purpose**: Expandable content sections

**Visual Features**:
- Header bar with title + icon
- Chevron indicator (rotates 90° when expanded)
- Smooth expand/collapse animation
- Hidden content with opacity + move transition

**Interaction**:
- Tap header to toggle
- Smooth 0.2s animation
- Indicator rotates to show state

---

### DetailedStatsView
**Purpose**: System statistics panel

**Visual Features**:
- GlassView container
- "System Details" header
- Divider separator
- Vertical list of stats
- Icon + label + value format
- Dividers between items

**Example Stats**:
- Uptime: 42 days, 5 hours
- CPU Temp: 58°C
- Processes: 248
- Threads: 1,024

---

### InfoCardView
**Purpose**: Information badge component

**Visual Features**:
- Horizontal layout
- Icon (left, color-coded)
- Title (bold, small font)
- Description (secondary color)
- GlassView styling

**Example**: 
- Icon: gauge.medium
- Title: "CPU Usage"
- Description: "Processor load and thread information"

---

### SimpleChartView
**Purpose**: Historical data visualization

**Visual Features**:
- Grid background (0.05 opacity lines)
- Line chart path
- Gradient colored line
- Smooth curve drawing
- Height: 80pt

**Grid**: Horizontal lines every 25% (0%, 25%, 50%, 75%, 100%)

---

## 🎯 Main Dashboard View

### ContentView
**Purpose**: Complete dashboard assembly

**Layout (Top to Bottom)**:
1. HeaderView - Title and status
2. QuickStatsView - 4-item stats bar
3. SystemDashboardSummary - Health overview
4. Circular Gauges - CPU and RAM side-by-side
5. ResourceMetricView - CPU details
6. ResourceMetricView - RAM details
7. Network Interfaces - 2 network cards
8. ProcessListView - Top CPU processes
9. ProcessListView - Top RAM processes
10. FooterView - Update info and controls

**Scrolling**: Vertical scrolling for content exceeding 850pt
**Frame**: 380pt width × 850pt height

---

## 📐 Layout Specifications

### Dimensions
- **Popover**: 380 × 850 pt
- **Card Padding**: 12pt
- **Section Spacing**: 14pt
- **Line Height**: 4pt (progress), 6pt (bars), 3pt (compact)

### Typography
- **Title**: .title2, bold
- **Headline**: .headline, semibold
- **Body**: .body, regular
- **Caption**: .caption, regular
- **Caption2**: .caption2, regular

### Colors (Dark Mode)
- **Background**: #1A1A1F / #131318
- **Primary Text**: #FFFFFF
- **Secondary Text**: #8E8E93
- **Glass Overlay**: 0.1-0.15 opacity white

---

## ✨ Interactive States

### Hover Effects
- GlassView brightens by ~5% opacity
- Smooth 0.2s transition
- Available on all card components

### Press Effects
- Button scales to 95% size
- Opacity reduces to 80%
- 0.2s animation timing

### Pulsing Effects
- Status indicator: 1.5s loop
- AnimatedStatView: 2s loop
- Repeats infinitely
- EaseInOut timing

---

## 🎭 Color Usage Guide

### CPU Metrics
- **Primary**: Blue (#5AC8FA)
- **Used for**: Gauges, progress bars, labels, icons

### Memory Metrics
- **Primary**: Red (#FF2D55)
- **Used for**: Gauges, progress bars, labels, icons

### Network Metrics
- **Primary**: Green (#00D084)
- **Download**: Blue (#5AC8FA)
- **Upload**: Orange (#FF9500)

### Status Indicators
- **Healthy**: Green (#00D084)
- **Warning**: Orange (#FF9500)
- **Critical**: Red (#FF2D55)

### UI Elements
- **Primary**: Primary foreground color
- **Secondary**: Reduced opacity (~0.6)
- **Tertiary**: Further reduced opacity (~0.4)

---

## 📱 Responsive Design Notes

- All components use flexible spacing
- Cards scale gracefully with content
- Text truncates appropriately (lineLimit: 1)
- Icons scale with font size
- Progress bars scale with GeometryReader

---

**Complete visual implementation ready for inspection in Xcode Preview Canvas!**
