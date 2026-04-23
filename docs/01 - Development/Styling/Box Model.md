---
tags: [development, css]
---

# Box Model

Every element in CSS is a rectangular box composed of four areas:

- **Content** — where text and images appear
- **Padding** — transparent space around the content
- **Border** — surrounds padding and content
- **Margin** — transparent space outside the border

## Visual Representation

```
┌─────────────────────────────────────┐ ← Margin
│  ┌─────────────────────────────────┐  │
│  │  ┌─────────────────────────────┐ │  │
│  │  │  ┌─────────────────────────┐ │ │  │
│  │  │  │        Content         │ │ │  │
│  │  │  └─────────────────────────┘ │ │  │
│  │  └─────────────────────────────┘ │  │ ← Padding
│  └─────────────────────────────────┘  │ ← Border
└─────────────────────────────────────┘
```

## References

- [CSS Box Model — MDN](https://developer.mozilla.org/en-US/docs/Learn/CSS/Building_blocks/The_box_model)
- [CSS Box Model — w3schools](https://www.w3schools.com/Css/css_boxmodel.asp)