# Unimplemented LaTeX Commands

This document lists all LaTeX commands that appear in the Wikipedia test suite (`yatexml_wikipedia_dynamic.html`) but are not yet implemented in yatexml. Commands are organized by category for easier prioritization.

**Total Unimplemented Commands: 135**

**Last Updated:** 2025-11-07

---

## 1. Greek Letters (Capital Variants) - 0 commands (Completed)

All wikipedia-observed capital Greek aliases (`\Alpha`, `\Beta`, …, `\Zeta`) are now implemented directly in the parser and Unicode helpers. Keeping this section for history; no outstanding work remains here.

---

## 2. Greek Letter Variants - 0 commands (Completed)

The unicode-math variants (`\varGamma`, `\varDelta`, …, `\varsupsetneqq`) now emit the appropriate glyphs and relations, so this category is complete as of 2025-11-07.

---

## 3. Trigonometric Functions - 0 commands (Completed)

All 13 trigonometric functions (basic, hyperbolic, and inverse) are now implemented. The commands included: `\sin`, `\cos`, `\tan`, `\cot`, `\sec`, `\csc`, `\sinh`, `\cosh`, `\tanh`, `\coth`, `\arcsin`, `\arccos`, `\arctan`.

**Priority:** n/a – section complete.

---

## 4. Mathematical Functions - 0 commands (Completed)

All 14 mathematical functions are now implemented. The commands included: `\arg`, `\deg`, `\det`, `\dim`, `\exp`, `\gcd`, `\hom`, `\inf`, `\ker`, `\log`, `\sup`, `\liminf`, `\limsup`, `\lcm`.

**Priority:** n/a – section complete.

---

## 5. Arrows (Single) - 0 commands (Completed)

All 29 single/long/triple arrow variants (hooked tails, loops, circle arrows, squiggles, and the `\Long...` forms) are now parsed as operators with the correct Unicode glyphs, matching TeX spacing semantics.

**Priority:** n/a – section complete.

---

## 6. Arrows (Double/Multiple) - 0 commands (Completed)

The paired arrow macros (`\leftleftarrows`, `\rightrightarrows`, `\leftrightarrows`, `\rightleftarrows`, `\upuparrows`, `\downdownarrows`) now map directly to their multi-arrow glyphs in MathML.

**Priority:** n/a – section complete.

---

## 7. Harpoons - 0 commands (Completed)

All 10 harpoon commands have been implemented: `\leftharpoonup`, `\leftharpoondown`, `\rightharpoonup`, `\rightharpoondown`, `\leftrightharpoons`, `\rightleftharpoons`, `\upharpoonleft`, `\upharpoonright`, `\downharpoonleft`, `\downharpoonright`.

**Priority:** n/a – section complete.

---

## 8. Three-Times Symbols - 0 commands (Completed)

All 4 three-times and semidirect product symbols have been implemented: `\leftthreetimes`, `\rightthreetimes`, `\ltimes`, `\rtimes`.

**Priority:** n/a – section complete.

---

## 9. Relations - Advanced Equality/Similarity - 0 commands (Completed)

All 35 similarity/equality variants (e.g., `\asymp`, `\approxeq`, `\risingdotseq`, `\lesseqqgtr`) now map to their MathML glyphs with correct Unicode variation selectors where needed, matching TeX’s spacing semantics.

**Priority:** n/a – section complete.

---

## 10. Relations - Ordering - 16 commands

```latex
\prec           \succ           \preceq         \succeq
\preccurlyeq    \succcurlyeq    \precsim        \succsim
\precapprox     \succapprox     \precnapprox    \succnapprox
\precneqq       \succneqq       \precnsim       \succnsim
```

**Priority:** LOW - Used in order theory.

---

## 11. Relations - Set Theory - 0 commands (Completed)

All 14 set theory relation commands have been implemented: `\sqsubset`, `\sqsupset`, `\sqsubseteq`, `\sqsupseteq`, `\sqcap`, `\sqcup`, `\Subset`, `\Supset`, `\subseteqq`, `\supseteqq`, `\subsetneq`, `\supsetneq`, `\subsetneqq`, `\supsetneqq`.

**Priority:** n/a – section complete.

---

## 12. Relations - Negated - 44 commands

```latex
\nless          \nleq           \nleqq          \nleqslant
\ngeq           \ngeqq          \ngeqslant
\nprec          \npreceq        \nsucc          \nsucceq
\nsubseteq      \nsubseteqq     \nsupseteq      \nsupseteqq
\nsim           \ncong
\nleftarrow     \nrightarrow    \nLeftarrow     \nRightarrow
\nleftrightarrow \nLeftrightarrow
\ntriangleleft  \ntriangleright \ntrianglelefteq \ntrianglerighteq
\nparallel      \nshortparallel \nshortmid
\nvdash         \nVdash         \nvDash          \nVDash
```

**Priority:** MEDIUM - Negations are common in logic and proofs.

---

## 13. Binary Operators - 0 commands (Completed)

All 23 binary operator commands have been implemented:
- Circle operators: `\odot`, `\oslash`, `\bigcirc`, `\circledast`, `\circledcirc`, `\circleddash`, `\circledS`
- Triangle operators: `\bigtriangleup`, `\bigtriangledown`, `\triangleleft`, `\triangleright`, `\trianglelefteq`, `\trianglerighteq`, `\blacktriangle`, `\blacktriangledown`, `\blacktriangleleft`, `\blacktriangleright`
- Other: `\barwedge`, `\doublebarwedge`, `\curlyvee`, `\curlywedge`, `\veebar`, `\divideontimes`, `\centerdot`, `\dotplus`, `\intercal`, `\smallsetminus`, `\setminus`, `\bigstar`

Note: `\ltimes` and `\rtimes` were already completed in section 8. Large operators like `\bigodot`, `\bigoplus`, `\bigotimes`, `\bigsqcup`, `\biguplus`, `\bigvee`, `\bigwedge` are tracked in section 15.

**Priority:** n/a – section complete.

---

## 14. Special Symbols - 2 commands remaining

All 21 essential special symbols have been implemented, including mathematical symbols (`\ell`, `\hbar`, `\imath`, `\jmath`, `\wp`, `\eth`, `\mho`, `\digamma`, `\beth`, `\daleth`, `\gimel`, `\complement`, `\empty`, `\nexists`), geometric symbols (`\sphericalangle`, `\measuredangle`, `\between`, `\pitchfork`), logic symbols (`\because`, `\therefore`), and corner symbols (`\ulcorner`, `\urcorner`, `\llcorner`, `\lrcorner`).

### Remaining commands:
```latex
\And            \Or
```

**Note:** `\And` and `\Or` are package-specific variants; their exact meaning depends on context.

**Priority:** n/a – most symbols complete.

---

## 15. Large Operators - 8 commands

```latex
\coprod         \bigoplus       \bigotimes      \bigodot
\biguplus       \bigsqcup       \bigvee         \bigwedge
\iiiint         \oiint          \oiiint
```

**Priority:** MEDIUM - Used for multiple integrals and algebraic operations.

---

## 16. Fractions and Binomials - 5 commands

```latex
\dfrac          \tfrac          \binom          \dbinom         \tbinom
```

**Priority:** HIGH - `\dfrac` and `\tfrac` are very common (display/text-style fractions).

**Note:** `\binom` is the binomial coefficient, commonly used in combinatorics.

---

## 17. Accents - 6 commands

```latex
\acute          \grave          \breve          \check
\dddot          \wideparen
```

**Priority:** MEDIUM - `\acute` and `\grave` are common in analysis; others less so.

---

## 18. Special Shapes and Symbols - 12 commands

```latex
\Box            \Diamond        \lozenge        \blacklozenge
\blacksquare    \triangleq      \triangledown   \vartriangle
\smile          \frown          \Vdash          \vDash
\dashv          \multimap       \multimapinv
```

**Priority:** LOW to MEDIUM - Depends on field (modal logic uses `\Box` and `\Diamond`).

---

## 19. Delimiters and Norms - 0 commands (Completed)

All 4 delimiter and norm commands have been implemented: `\lVert` (‖), `\rVert` (‖), `\mid` (∣), and `\parallel` (∥).

**Priority:** n/a – section complete.

---

## 20. Dots and Ellipses - 0 commands (Completed)

The `\lll` command (also written as `\llless`, meaning "much less than") has been implemented.

**Priority:** n/a – section complete.

---

## 21. Other Relations - 0 commands (Completed)

All 7 relation commands have been implemented: `\ni` (reverse element of ∋), `\propto` (proportional to ∝), `\varpropto`, `\parallel` (∥), `\shortparallel`, `\shortmid`, and `\Perp` (⫫).

**Priority:** n/a – section complete.

---

## 22. Special Commands - 17 commands

### Positioning
```latex
\overset        \underset       \sideset        \limits
```

### Styling
```latex
\boldsymbol
```

### Text Size
```latex
\tiny           \normalsize     \large
```

### Color
```latex
\definecolor
```

### Spacing/Phantom
```latex
\mathrlap
```

### Cancellation
```latex
\cancel         \sout
```

### Others
```latex
\not            \backslash
\Bbbk           \Finv           \Game
\coh            \incoh          \sincoh         \shneg          \shpos
```

**Priority:** MIXED
- HIGH: `\overset`, `\underset`, `\boldsymbol`, `\not`
- MEDIUM: `\cancel`, `\limits`
- LOW: Size commands, obscure symbols

---

## 23. Miscellaneous Uppercase Symbols - 4 commands

```latex
\Cap            \Cup            \Lsh            \Rsh
```

These are variants of cap, cup, and shifts.

---

## Summary by Priority

### HIGH Priority (Very Common) - ~7 commands remaining
- Trigonometric functions (0) ✓ Completed
- Mathematical functions (0) ✓ Completed
- Delimiters and norms (0) ✓ Completed
- Common special symbols (0) ✓ Completed
- Fractions: `\dfrac`, `\tfrac`, `\binom` (5)
- Positioning: `\overset`, `\underset` (2)
- Styling: `\boldsymbol`, `\not` (2+, package-dependent)

### MEDIUM Priority (Moderately Common) - ~58 commands remaining
- Arrows (39) - Most already implemented
- Harpoons (0) ✓ Completed
- Advanced relations (35) - Most already implemented
- Other relations (0) ✓ Completed
- Three-times symbols (0) ✓ Completed
- Additional inequalities (0) ✓ Completed
- Set theory relations (0) ✓ Completed
- Binary operators (0) ✓ Completed
- Negated relations (44)
- Large operators (8)
- Accents (6)

### LOW Priority (Specialized) - ~142 commands
- Ordering relations (16)
- Greek variants (28)
- Obscure symbols
- Size commands
- Specialized operators

---

## Implementation Notes

### Quick Wins (Easy to Implement)

Many of these are simple operator/symbol mappings that just need:
1. Registration in command table
2. Unicode mapping in `operatorToUnicode`

Examples:
- Trigonometric functions: Already have function infrastructure
- Simple symbols: Just need Unicode character mapping
- Binary operators: Follow existing operator patterns

### More Complex

These require special handling:
- `\dfrac`, `\tfrac`: Display/text style fractions (need style context)
- `\binom`, `\dbinom`, `\tbinom`: Binomial coefficients (similar to fractions)
- `\overset`, `\underset`: Stacking elements (new MathML structure)
- `\boldsymbol`: Bold symbols (styling)
- `\cancel`, `\sout`: Strike-through (uses `<menclose>`)
- `\limits`: Limit placement control for operators
- `\sideset`: Position indices on big operators
- Greek capitals: Need decision on whether to support

---

## Implementation Strategy

### Phase 1: Functions (HIGH Impact, Easy) ✓ COMPLETED
All trigonometric and mathematical functions have been implemented (27 commands: 13 trig + 14 math).

### Phase 2: Fraction Variants (HIGH Impact, Medium Difficulty)
Implement `\dfrac`, `\tfrac`, `\binom` and variants.

### Phase 3: Essential Symbols (HIGH Impact, Easy) ✓ COMPLETED
All essential symbols implemented (25 commands): delimiters/norms (`\lVert`, `\rVert`, `\mid`, `\parallel`) and special mathematical symbols (`\ell`, `\hbar`, `\imath`, `\jmath`, `\wp`, Hebrew letters, geometric symbols, logic symbols, corners).

### Phase 4: Positioning (HIGH Impact, Medium Difficulty)
Implement `\overset`, `\underset` for stacking.

### Phase 5: Binary Operators & Relations (MEDIUM Impact, Easy)
Batch-add all the binary operators and relation symbols.

### Phase 6: Arrows (MEDIUM Impact, Easy)
Batch-add all arrow variants.

### Phase 7: Advanced Features (MEDIUM Impact, Complex)
- `\boldsymbol`
- `\cancel`, `\sout`
- `\limits`, `\nolimits`
- `\sideset`

### Phase 8: Completeness (LOW Impact, Easy)
Add remaining obscure symbols for comprehensive coverage.

---

## Testing Strategy

For each batch of commands:
1. Add test cases to verify proper MathML generation
2. Test with Wikipedia examples
3. Cross-reference with TeMML output for correctness
4. Verify both C and JS backends work

---

## Related Files

- **Parser:** `src/yatexml/parser.nim` - Command registration
- **Unicode Mappings:** `src/yatexml/parser.nim` - `operatorToUnicode` function
- **MathML Generation:** `src/yatexml/mathml_generator.nim` - Output generation
- **Tests:** `tests/test_all.nim` - Test suite
- **Wikipedia Tests:** `yatexml_wikipedia_dynamic.html` - Real-world examples
