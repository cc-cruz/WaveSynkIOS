# WaveSynk iOS Brand Guide

Welcome to the WaveSynk iOS Brand Guide! This document outlines the visual design, typography, UI components, and tone of our iOS app. It is meant to ensure consistency across the WaveSynk user experience while following Apple’s best practices for usability and accessibility. Please keep this guide handy whenever implementing or refining the WaveSynk iOS interface.

---

## 1. Color Palette

### Brand Colors
WaveSynk’s palette captures the energy of music and the fluidity of sound waves. The core tones:

- **Primary Electric Teal**: `#00CCCC` (a vibrant teal inspired by audio waveforms)
- **Secondary Deep Navy**: `#000033` (rich, grounding navy for dark backdrops)
- **Accent Pulse Orange**: `#FF9900` (optional accent for calls to action, limited use)
- **Neutrals**: White (`#FFFFFF`) and Black (`#000000`), used for text or backgrounds where appropriate

These colors reflect WaveSynk’s brand ethos—dynamic, bold, and clean. Use Electric Teal or Navy for primary backgrounds and interactive elements, and Pulse Orange as a high-visibility accent.

### Light & Dark Mode
- **Light Mode**: White or very light gray backgrounds, Navy or Teal text/icons for contrast.
- **Dark Mode**: Navy or near-black backgrounds with white or lighter teal text/icons.
- **Adjusting Vibrancy**: Slightly brighten the Teal or dim the Orange in Dark Mode so elements remain easy on the eyes. 
- **System Semantic Colors**: Whenever possible, use Apple’s semantic colors (e.g. `UIColor.systemBackground`, `Color.primary`, etc.) to automatically adapt in light/dark contexts.

### Contrast & Accessibility
- Maintain a minimum 4.5:1 contrast ratio for text and icons. 
- If Electric Teal or Orange is used on white, ensure the shade is sufficiently dark or the font size is large enough to pass WCAG guidelines.
- Never rely on color alone to convey status—use icons, labels, or patterns in tandem with color.

---

## 2. Typography

### Primary Font
- **San Francisco (SF Pro)**: Use Apple’s system font family for all primary text. This ensures optimal legibility, works seamlessly with Dynamic Type, and aligns with iOS conventions.

### Secondary / Brand Fonts
- If WaveSynk has a custom display font (for instance, a stylized “WaveSynk” wordmark), use it sparingly for:
  - **Main headers** (e.g. app name on the splash screen)
  - **Promotional banners** or highlight sections
- Keep all standard body copy in SF Pro for readability and accessibility.

### Usage & Sizing
- **Text Styles**: Use iOS Text Styles (`Large Title`, `Title`, `Body`, `Caption`, etc.) so that text scales automatically with user settings.
- **Minimum Size**: Keep body text around 17pt. Avoid going below ~11pt for secondary labels.
- **Line Spacing & Padding**: Ensure comfortable spacing; iOS built-in text styles typically handle this.  
- **Dynamic Type**: Enable automatic text size adjustments and ensure the layout reflows gracefully when the user opts for larger text.

---

## 3. UI Components & Design System

### Buttons
- **Primary Action**: Filled with Electric Teal or Pulse Orange background, white text for high contrast.
- **Secondary**: Outlined or subtly tinted with Teal or Navy stroke, white or black text depending on background.
- **Minimum Tap Target**: 44×44 points to meet iOS accessibility standards.
- **Corner Radius**: ~8pt for modern, approachable look.

### Cards & Lists
- **Reusable Card Views**: For songs, playlists, or featured content. Each card includes:
  - A prominent image/album art
  - Title (e.g. track or playlist name)
  - Subtitle or short descriptor
- **Spacing**: Use consistent spacing or padding (16pt typically). Consider subtle shadows or separators for clarity.
- **Lists**: SwiftUI’s `List` or `LazyVStack` (or UIKit’s `UITableView`) with lazy loading for performance.  

### Navigation & Layout
- **Navigation**: 
  - Use standard iOS navigation bars. 
  - Consider Large Title for major screens (e.g. “Discover” or “My Library”).
  - The nav bar background can be Navy with white text icons for dark styling.
- **Tab Bar**: 
  - Ideal for primary sections (e.g. Home, Search, Library, Profile).
  - Icons can be SF Symbols tinted Electric Teal or White (in Dark Mode) when active.
- **Layout Margins**: Default 16pt from screen edges; ensure consistency and alignment.

### Animations & Interactions
- **Subtle & Smooth**: Fade in album art, gently animate transitions. Keep durations around 200–300ms.
- **Feedback**: Provide clear button press states and consider haptic taps for key actions (like “Play”).
- **Respect ‘Reduce Motion’**: Disable non-essential animations or parallax if the user opts to reduce motion in iOS settings.

---

## 4. Brand Messaging, Tone & Philosophy

### WaveSynk Voice
- **Energetic & Empowering**: Reflect the excitement of discovering new music and connecting with waves of sound.
- **Friendly Expert**: Offer helpful tips without being overly technical.  
- **Concise & Clear**: Mobile screens are small; keep text impactful and to the point.

### Consistency
- Use a unified tone across all app sections—titles, settings, alerts, etc.
- Reference the user as “you” for a personal touch, or use inclusive language like “we sync together” if it aligns with the brand.
- Keep button labels action-oriented (e.g. “Start Listening” vs. “Begin” or “OK”).

---

## 5. Accessibility & Localization

### Inclusive Design (WCAG)
- **Contrast**: 4.5:1 minimum for normal text. Teal on White or White on Navy usually passes easily; verify with an accessibility checker.
- **VoiceOver**: Label all tappable elements (buttons, icons) with descriptive text (e.g. “Play Song,” “Add to Favorites”).
- **Reduce Motion**: Provide simplified animations for users who enable “Reduce Motion.”
- **Haptic & Sound Cues**: Ensure any audio feedback is optional and accompanied by a visual or haptic equivalent.

### Localization
- **Externalized Strings**: Use `NSLocalizedString` or SwiftUI’s localization for all UI text. 
- **Auto Layout**: Anticipate longer strings in languages like German or French.
- **RTL Support**: Verify the interface flips properly in right-to-left languages (Arabic, Hebrew).
- **Date/Number Formatting**: Use the user’s locale for numeric data, date/time displays, etc.

---

## 6. Performance & Optimization

### Smooth Performance
- **Async Tasks**: Offload data fetching or large computations from the main thread to keep UI responsive.
- **60fps Goal**: Aim for fluid scrolling and transitions. Avoid blocking the main thread.
- **Loading Indicators**: Show a spinner or skeleton view if content retrieval exceeds ~500ms.

### Image & Media Optimization
- **Asset Catalog**: Store icons and static images in app catalogs with correct `@1x/@2x/@3x` for crisp rendering.
- **Compression & Caching**: Use efficient formats (e.g. HEIC, WebP) where possible and cache downloaded content to prevent re-fetching.
- **Lazy Loading**: Only load images or data as needed in scrollable lists.

### Data Loading
- **Pagination**: If showing large lists (e.g. song libraries), fetch data incrementally (infinite scroll or page-by-page).
- **Prefetching**: Use SwiftUI’s `.task`, Combine, or UIKit’s prefetch APIs to load upcoming data. 
- **Profiling**: Test on real devices, including older iPhones, to ensure minimal memory leaks and fast startup times.

---

## 7. Summary & Best Practices

WaveSynk on iOS should feel:
1. **Visually Unified**: Consistent use of color, typography, and layout.
2. **Intuitive & Accessible**: Clear navigation and high-contrast text/icons, with VoiceOver compatibility.
3. **Performant & Smooth**: Responsive interactions, optimized media handling, and minimal load times.
4. **On-Brand & Engaging**: Energetic, friendly tone that resonates with music lovers while reflecting WaveSynk’s identity.

By adhering to these guidelines, we ensure a top-tier user experience that captures the WaveSynk spirit: dynamic, user-friendly, and in sync with Apple’s design standards.

---

_Last Updated: February 17, 2025_

