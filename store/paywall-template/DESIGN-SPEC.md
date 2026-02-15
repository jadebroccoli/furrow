# Furrow Pro Paywall — Design Specification

Use this spec to configure the paywall in RevenueCat's dashboard editor or recreate it in Figma for import via the RevenueCat Figma plugin.

---

## Color Tokens

### Light Mode

| Element | Hex | Notes |
|---------|-----|-------|
| Background | `#FFF8F0` | Cream/off-white |
| Card background | `#FFFDF7` | Slightly lighter cream |
| Selected card bg | `#F5FFF5` | Very faint green tint |
| Headline text | `#1A1C18` | Near-black |
| Body text | `#3D3D3D` | Dark gray |
| Subtitle / muted | `#7A8B6F` | Sage green |
| CTA button bg | `#2D5A27` | Deep forest green |
| CTA button text | `#FFFFFF` | White |
| Checkmark icons | `#66BB6A` | Seedling green |
| "Best Value" badge bg | `#D4A017` | Harvest gold |
| "Best Value" badge text | `#FFFDF7` | Cream |
| Selected card border | `#2D5A27` | Forest green |
| Unselected card border | `#E0D8CC` | Warm gray |
| Price breakdown text | `#8B6914` | Warm brown |
| Footer links | `#7A8B6F` | Sage green |
| Hero gradient top | `#2D5A27` | Forest green |
| Hero gradient mid | `#3D7A35` | Medium green |
| Hero gradient bottom | `#66BB6A` | Seedling green |

### Dark Mode

| Element | Hex | Notes |
|---------|-----|-------|
| Background | `#1A1C18` | Dark surface |
| Card background | `#121410` | Near-black |
| Selected card bg | `#1E2A1A` | Dark green tint |
| Headline text | `#FFF8F0` | Cream |
| Body text | `#D4D0C8` | Light warm gray |
| Subtitle / muted | `#A8B89A` | Light sage |
| CTA button bg | `#66BB6A` | Seedling green |
| CTA button text | `#121410` | Near-black |
| Checkmark icons | `#66BB6A` | Seedling green |
| "Best Value" badge bg | `#D4A017` | Harvest gold |
| "Best Value" badge text | `#121410` | Near-black |
| Selected card border | `#66BB6A` | Seedling green |
| Unselected card border | `#2A2C26` | Dark warm gray |
| Price breakdown text | `#CBB979` | Light gold |
| Footer links | `#A8B89A` | Light sage |
| Hero gradient top | `#1B3A17` | Very dark green |
| Hero gradient mid | `#2D5A27` | Forest green |
| Hero gradient bottom | `#3D7A35` | Medium green |

---

## Typography

**Font family:** Nunito (Google Fonts)
Upload Nunito-Regular.ttf, Nunito-SemiBold.ttf, Nunito-Bold.ttf, and Nunito-ExtraBold.ttf to RevenueCat's font uploader.

| Element | Size | Weight | Letter Spacing |
|---------|------|--------|----------------|
| Headline | 28px | ExtraBold (800) | 0 |
| Subtitle | 16px | Regular (400) | 0 |
| Feature text | 15px | SemiBold (600) | 0 |
| Price (large) | 22px | ExtraBold (800) | 0 |
| Price period | 12px | Regular (400) | 0 |
| Price breakdown | 11px | SemiBold (600) | 0 |
| Pricing card label | 12px | Bold (700) | 0.5px |
| "Best Value" badge | 10px | ExtraBold (800) | 0.5px |
| CTA button | 17px | ExtraBold (800) | 0.3px |
| Footer links | 12px | SemiBold (600) | 0 |
| Checkmarks | 20px | — | — |

---

## Layout & Spacing

| Property | Value |
|----------|-------|
| Phone viewport | 390 x 844 (iPhone 14 logical) |
| Hero image height | 280px |
| Hero bottom fade | 80px gradient to background |
| Content horizontal padding | 24px |
| Headline to subtitle gap | 8px |
| Subtitle to features gap | 24px |
| Feature item gap | 12px |
| Feature icon to text gap | 12px |
| Features to pricing gap | 28px |
| Pricing cards gap | 10px |
| Pricing to CTA gap | 20px |
| CTA horizontal margin | 24px each side |
| CTA vertical padding | 16px |
| Footer padding | 16px top, 34px bottom |
| Footer link gap | 6px (with dot separators) |

---

## Corner Radii

| Element | Radius |
|---------|--------|
| Pricing cards | 16px |
| CTA button | 12px |
| "Best Value" badge | 20px (pill) |
| Close button | 50% (circle) |

---

## RevenueCat Component Mapping

When building in the RevenueCat WYSIWYG editor, use these components:

| Design Element | RevenueCat Component |
|---------------|---------------------|
| Hero area | **Image** (full width, fit mode: Fill) + **Stack** with gradient overlay |
| Close button | Built-in (automatic) |
| Headline + subtitle | **Text** components in a **Stack** |
| Feature list | **Feature List** component (or **Stack** with **Text** + **Icon** rows) |
| Pricing cards | **Package** components in a horizontal **Stack** |
| "Best Value" badge | Package component's badge/label property |
| CTA button | **Purchase Button** component |
| Footer links | **Text** components (Restore is built-in functionality) |
| Light/dark variants | Use the editor's light/dark mode toggle to configure both |

---

## Image Assets

| Asset | Dimensions | Format | Max Size |
|-------|-----------|--------|----------|
| Hero image | 1170 x 840 (@3x) | PNG or SVG | < 1 MB |
| App icon (optional) | 256 x 256 | PNG | < 500 KB |

Use `hero-placeholder.svg` as a starting point. Replace with final botanical artwork when ready.

---

## Figma Layer Naming (for RevenueCat plugin export)

If recreating in Figma for plugin export, name these layers:

```
Paywall (top-level Auto Layout frame)
├── Hero (Auto Layout frame, image fill)
├── Content (Auto Layout frame, vertical)
│   ├── Headline (Text)
│   ├── Subtitle (Text)
│   ├── Features (Auto Layout frame, vertical)
│   │   ├── Feature Row (Auto Layout, horizontal) × 4
│   ├── Packages (Auto Layout frame, horizontal)
│   │   ├── Package(monthly)      ← RevenueCat convention
│   │   ├── Package(yearly)       ← RevenueCat convention
│   │   └── Package(lifetime)     ← RevenueCat convention
├── Purchase Button(purchase)     ← RevenueCat convention
└── Footer (Auto Layout frame, horizontal)
    ├── Restore Purchases (Text)
    ├── Terms (Text)
    └── Privacy (Text)
```

**Important:** Use Figma Auto Layout for all frames so the RevenueCat plugin can import correctly.

---

## Copy

| Element | Text |
|---------|------|
| Headline | Grow without limits |
| Subtitle | Unlock unlimited plants, seasons, frost alerts & more with Furrow Pro. |
| Feature 1 | Unlimited plants & seasons |
| Feature 2 | Frost alerts for every location |
| Feature 3 | Full harvest tracking & journal |
| Feature 4 | Priority support |
| Monthly label | MONTHLY |
| Monthly price | $2.99 |
| Monthly period | /month |
| Yearly label | YEARLY |
| Yearly price | $19.99 |
| Yearly period | /year |
| Yearly breakdown | $1.67/mo — Save 44% |
| Yearly badge | BEST VALUE |
| Lifetime label | LIFETIME |
| Lifetime price | $49.99 |
| Lifetime period | one time |
| Lifetime breakdown | Pay once, grow forever |
| CTA button | Start Growing Pro |
| Footer restore | Restore Purchases |
| Footer terms | Terms |
| Footer privacy | Privacy |

*Note: Prices shown are display fallbacks. RevenueCat will dynamically insert the real prices from your configured products.*
