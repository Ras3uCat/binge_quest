# Frontend Design System Layer
**Skill Name** frontend-design
**Description** Create distinctive, production-grade frontend interfaces with intentional, high-end design quality.
Used when building UI, screens, components, dashboards, or visual experiences.

**Design Thinking Workflow (MANDATORY BEFORE CODING)**
- **Purpose**
    - What problem does this UI solve?
    - Who is using it?
- **Tone Selection (Pick ONE Bold Direction)**
    - Choose a strong visual identity:
    - Brutalist / Raw
    - Retro-Futuristic
    - Editorial / Magazine
    - Luxury / High-End
    - Soft / Organic
    - Geometric / Art Deco
    - Playful / Toy-like
    - Industrial / Tactical
    - Minimal Zen
    - Maximalist Chaos
    - The design must commit fully to the chosen tone.
- **Differentiation Anchor**
    - Define one unforgettable visual element, such as:
        - signature animation (see `scroll-stop-builder` skill for specialized video-scroll effects)
        - geometric layout system
        - bold type treatment
        - interactive gesture
        - layered glassmorphism
        - asymmetric layout

- **Flutter-Specific Design Translation**
    - Since this is Flutter (not HTML), map aesthetics to:
        - Web Concept	Flutter Equivalent
        - CSS variables	EColors, ThemeData, extensions
        - Grid layouts	GridView, CustomMultiChildLayout
        - Overlapping layouts	Stack + Positioned
        - Animations	AnimatedContainer, TweenAnimationBuilder, AnimationController
        - Scroll effects	CustomScrollView, Slivers
    - Hover effects	MouseRegion (desktop/web)
    - Glass / blur	BackdropFilter
    - Gradients	LinearGradient, ShaderMask

- **Identity System Layer (Augmented Template)**
    - This project serves as a template. Balance the `ras3uCat` DNA with the client's vision.
    - **Identity Source**: Always refer to `planning/BRAND_KIT.md` for the current active brand tokens.
    - **Glimpses of Ras3uCat**: Even when rebranding, maintain "tactical glances" (sigils in corners, geometric grids, modular progress bars) to preserve project identity.

- **Style Toggles & Config (ThemeExtensions)**
    - Use `BrandTheme` extension to control visual modes.
    - **Toggleability**:
        - `enableNeon`: Controls if text/borders have glowing neon effects (default true for Ras3uCat, may be false for clients).
        - `enableGlow`: Global toggle for shadow blurs and bloom.
        - `enableGeometricMotifs`: Toggle for triangle/grid background painters.
    - If a client brand is "Minimalist", turn off neon/geometric but keep the layout precision.

- **Modular Branding & Swappable Widgets**
    - Never hardcode brand-specific details. Use abstract interfaces.
    - **Reusability**: Build widgets like `EBrandButton` or `EBrandCard` that adapt based on the active brand configuration.
    - **Swappability**: Ensure the architecture allows replacing a `NeonButton` with a `MinimalGlassButton` by simply swapping the component reference in the design system.

- **Aesthetic Execution Rules**
    - **Typography**
        - Use distinctive font pairings (refer to `BRAND_KIT.md`).
        - Avoid default system fonts. Use size contrast aggressively.
    - **Color System**
        - Define palette in `EColors`.
        - **Rule**: Never use pure white for body text in dark themes; use tinted variants (e.g., `cyanTintedWhite`).
        - Priority: Dominant base + sharp accents. Avoid evenly distributed palettes.
    - **Synergy with Latest Trends**
        - While staying "Tactical", incorporate:
            - Bento-grid layouts for dashboards.
            - Layered glassmorphism with grain textures.
            - Dynamic micro-interactions that feel "mechanical" or "systemic".

- **Motion & Interaction**
    - Prioritize:
        - Page load entrance sequences (staggered).
        - Meaningful micro-interactions (hover = activation).
        - **Avoid**: Random motion or "bouncy" easing. Stick to precise, linear-to-ease motions.

- **Spatial Composition**
    - Avoid boring center-column layouts. Use:
        - Asymmetry and diagonal flow.
        - Overlapping elements with `Stack`.
        - Negative space for "Luxury" or dense blocks for "Editorial".

- **Output Requirements When This Skill Is Triggered**
    - When generating UI:
        - 1. Check `BRAND_KIT.md` for active tokens.
        - 2. Implement swappable widgets using semantic naming.
        - 3. Follow Flutter architecture rules first.
        - 4. Provide: Screen, Modular Widgets, Controller, Constants.
        - 5. Include "Sync complete △ M3OW" (or rebranding equivalent) in footers.

- **Philosophy**
    - Your apps should feel like:
        - A crafted product, not a template.
        - A designed experience, not just a UI.
        - A brand, not just a screen.
        - **Swappable yet soulful.**

- **Final Rule**
    - Engineering quality is required.
    - Design excellence is expected.
    - Both must exist together.

## Companion Skill: ui-ux-pro-max
Before choosing a color palette, typography pairing, or UI style, run the search tool for data-backed recommendations:

```bash
# Style suggestions
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<intent>" --stack flutter --domain style

# Color palette
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<intent>" --stack flutter --domain color

# Font pairing
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<intent>" --stack flutter --domain typography

# Full design system (one shot)
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<intent>" --stack flutter --design-system
```

Use results to inform Tone Selection and Color System decisions above. The skill output is advisory — `EColors`, `BRAND_KIT.md` tokens, and E-prefix constants always take precedence.