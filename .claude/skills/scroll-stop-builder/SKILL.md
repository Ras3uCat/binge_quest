---
name: scroll-stop-builder
description: >
  Specialized skill for this project to build high-performance, scroll-driven video animation 
  components (Apple-style) for client websites. Uses frame extraction via FFmpeg and canvas-based 
  rendering. Inherits branding from client.json/discovery docs and styling from frontend-design.
  Trigger when the user says "scroll-stop build", "scroll-driven video", "video on scroll",
  or asks to add a "mesmerizing scroll effect" to a service or product section.
---

# Scroll-Stop Builder Skill (Project Context)

This skill is specifically for creating **scroll-driven video animation components** within this 
client-delivery project. It is NOT for building standalone websites from scratch, but for 
generating high-end, high-performance modules that integrate into our existing Flutter/Web architecture.

## Phase 1: Brand & Content Discovery (Project Source)

Instead of a generic interview, you MUST use the existing project documentation to define the UI:

1.  **Branding Source**: Read `execution/frontend/app/client.json`.
    *   Use `COLOR_PRIMARY`, `COLOR_ACCENT`, and `COLOR_SURFACE` for the component's theme.
    *   Use `CLIENT_NAME` for any text references.
2.  **Personality & Vibe**: Consult `planning/client/01_discovery.md`.
    *   Check the "Visual Brand" section (Personality, Hero Style, etc.) to ensure the animation's cards and overlays match the client's expected "feel" (luxury, minimal, bold, etc.).
3.  **Content Sourcing**:
    *   Ask the user which product or service this animation is for.
    *   Pull relevant descriptions and specs from the existing service page or the client's discovery notes.

---

## Phase 2: Technical Prerequisites

- **FFmpeg** must be installed on the local system.
- The user provides a video file (MP4, MOV, WebM).
- **Video Flow**: The video should ideally start on a clean background that matches the site's `COLOR_SURFACE` (usually white or a specific tinted dark). If it doesn't, coordinate with the user on a transition or re-export.

---

## Phase 3: Design System Integration

All UI elements (annotation cards, progress bars, loaders) must follow the **`frontend-design`** skill rules:

- **Typography**: Inherit `FONT_PRIMARY` and `FONT_SECONDARY` from the client's design tokens.
- **Aesthetic**: 
    - Use **Glassmorphism** for annotation cards (`backdrop-filter: blur(20px)`, subtle borders).
    - Use **Tinted Whites** for text in dark themes (never pure `#FFF`).
    - Use **Tactical Accents** (sigils, geometric grids) to maintain project DNA where appropriate.
- **Responsiveness**: Use the "Compact Mobile" pattern (single-line cards at viewport bottom) as defined in the technical section below.

---

## Technical Implementation Pipeline

### 1. Frame Extraction
Extract frames to a local directory for preloading. Aim for 60-150 frames.
```bash
mkdir -p "assets/animations/{SLUG}/frames"
ffmpeg -i "{VIDEO_PATH}" -vf "fps={TARGET_FPS},scale=1920:-2" -q:v 2 "assets/animations/{SLUG}/frames/frame_%04d.jpg"
```

### 2. Canvas-Based Rendering (Retina)
Always account for `devicePixelRatio` to keep the animation crisp on high-res displays.
```javascript
canvas.width = window.innerWidth * window.devicePixelRatio;
canvas.height = window.innerHeight * window.devicePixelRatio;
```

### 3. Snap-Stop Logic
Implement the "Freeze" effect where the scroll briefly locks at each annotation card's `data-show` position to allow the user to read the content without missing the frame alignment.

---

## Build Output

When this skill is triggered, you will produce:
1.  **The Extraction Script**: A shell command for the user to run to generate the frames.
2.  **The Component Code**: A modular widget or HTML/JS section that integrates into the current project's page structure.
3.  **The Integration Plan**: Instructions on where to place the assets and how to link the component to the active client theme.

## Error Recovery & Optimization
- **Choppy Scroll**: Check if frame preloading is complete.
- **Blurry Canvas**: Verify `devicePixelRatio` scaling.
- **Mobile cards**: Ensure they don't block the core object in the video; use `bottom: 5vh` offset.
