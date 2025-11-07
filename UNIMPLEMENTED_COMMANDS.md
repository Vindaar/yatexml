# Unimplemented LaTeX Commands

This document lists all LaTeX commands that appear in the Wikipedia test suite (`yatexml_wikipedia_dynamic.html`) but are not yet implemented in yatexml. Commands are organized by category for easier prioritization.

**Total Unimplemented Commands: 342**

**Last Updated:** 2025-11-07

---

## 1. Greek Letters (Capital Variants) - 11 commands

These are capital Greek letters that don't have special mathematical meanings in standard LaTeX.

```latex
\Alpha      \Beta       \Chi        \Epsilon    \Eta
\Iota       \Kappa      \Omicron    \Rho        \Tau
\Zeta
```

**Note:** Standard LaTeX uses `A`, `B`, `E`, `Z`, `H`, `I`, `K`, `O`, `P`, `T` for these. The backslash versions are from packages like `unicode-math`.

---

## 2. Greek Letter Variants - 17 commands

Variant forms of Greek letters with different glyphs.

```latex
\varDelta       \varGamma       \varLambda      \varOmega
\varPhi         \varPi          \varSigma       \varTheta
\varUpsilon     \varXi          \varkappa       \varpropto
\vartriangle    \vartriangleleft \vartriangleright
\varsubsetneq   \varsubsetneqq  \varsupsetneq   \varsupsetneqq
```

---

## 3. Trigonometric Functions - 12 commands

```latex
\sin        \cos        \tan        \cot        \sec        \csc
\sinh       \cosh       \tanh       \coth
\arcsin     \arccos     \arctan
```

**Priority:** HIGH - These are extremely common in mathematical expressions.

---

## 4. Mathematical Functions - 14 commands

```latex
\arg        \deg        \det        \dim        \exp        \gcd
\hom        \inf        \ker        \log        \sup
\liminf     \limsup     \lcm
```

**Priority:** HIGH - Commonly used in calculus, algebra, and analysis.

---

## 5. Arrows (Single) - 29 commands

### Basic Arrows
```latex
\gets                   \hookleftarrow          \hookrightarrow
\leftarrowtail          \rightarrowtail         \looparrowleft
\looparrowright         \curvearrowleft         \curvearrowright
\circlearrowleft        \circlearrowright
\twoheadleftarrow       \twoheadrightarrow
```

### Long Arrows
```latex
\Longleftarrow          \Longrightarrow         \Longleftrightarrow
\longleftrightarrow
```

### Triple Arrows
```latex
\Lleftarrow             \Rrightarrow
```

### Other Arrow Variants
```latex
\rightsquigarrow        \leftrightsquigarrow
```

**Priority:** MEDIUM - Used in logic, category theory, and mappings.

---

## 6. Arrows (Double/Multiple) - 10 commands

```latex
\leftleftarrows         \rightrightarrows       \leftrightarrows
\rightleftarrows        \upuparrows             \downdownarrows
```

**Priority:** LOW - Less commonly used.

---

## 7. Harpoons - 10 commands

```latex
\leftharpoonup          \leftharpoondown        \rightharpoonup
\rightharpoondown       \leftrightharpoons      \rightleftharpoons
\upharpoonleft          \upharpoonright         \downharpoonleft
\downharpoonright
```

**Priority:** MEDIUM - Used in chemistry and physics.

---

## 8. Three-Times Symbols - 3 commands

```latex
\leftthreetimes         \rightthreetimes        \ltimes         \rtimes
```

---

## 9. Relations - Advanced Equality/Similarity - 35 commands

### Similarity Relations
```latex
\asymp          \simeq          \approxeq       \cong
\backsim        \backsimeq      \thicksim       \thickapprox
\bumpeq         \Bumpeq         \doteq          \doteqdot
\risingdotseq   \fallingdotseq  \circeq         \eqcirc
\eqsim
```

### Inequality Variants
```latex
\leqq           \geqq           \leqslant       \geqslant
\eqslantless    \eqslantgtr     \lesssim        \gtrsim
\lessapprox     \gtrapprox      \lessdot
\lneq           \gneq           \lneqq          \gneqq
\lnapprox       \gnapprox       \lnsim          \gnsim
\lessgtr        \gtrless        \lesseqgtr      \gtreqless
\lesseqqgtr     \gtreqqless
\lvertneqq      \gvertneqq
```

**Priority:** MEDIUM - Used in advanced mathematics.

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

## 11. Relations - Set Theory - 12 commands

```latex
\sqsubset       \sqsupset       \sqsubseteq     \sqsupseteq
\sqcap          \sqcup
\Subset         \Supset         \subseteqq      \supseteqq
\subsetneq      \supsetneq      \subsetneqq     \supsetneqq
```

**Priority:** MEDIUM - Common in set theory and lattice theory.

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

## 13. Binary Operators - 25 commands

### Circle Operators
```latex
\odot           \oslash         \bigodot        \bigoplus
\bigotimes      \bigcirc        \circledast     \circledcirc
\circleddash    \circledS
```

### Triangle Operators
```latex
\bigtriangleup  \bigtriangledown \triangleleft   \triangleright
\trianglelefteq \trianglerighteq \blacktriangle  \blacktriangledown
\blacktriangleleft \blacktriangleright
```

### Other Binary Operators
```latex
\barwedge       \doublebarwedge \curlyvee       \curlywedge
\veebar         \divideontimes  \ltimes         \rtimes
\centerdot      \dotplus        \intercal       \smallsetminus
\setminus       \bigstar        \bigsqcup       \biguplus
\bigvee         \bigwedge
```

**Priority:** MEDIUM - Used in algebra and logic.

---

## 14. Special Symbols - 23 commands

### Mathematical Symbols
```latex
\ell            \hbar           \imath          \jmath
\wp             \eth            \mho            \digamma
\beth           \daleth         \gimel
\complement     \emptyset       \empty          \nexists
```

### Geometric Symbols
```latex
\sphericalangle \measuredangle  \between        \pitchfork
```

### Logic Symbols
```latex
\because        \therefore      \And            \Or
```

### Corners
```latex
\ulcorner       \urcorner       \llcorner       \lrcorner
```

**Priority:** MEDIUM to HIGH - Depends on field (`\ell`, `\hbar` are very common in physics).

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

## 19. Delimiters and Norms - 4 commands

```latex
\lVert          \rVert          \mid            \parallel
```

**Priority:** HIGH - `\lVert` and `\rVert` are used for norms, very common in analysis.

**Note:** `\mid` is used for "such that" in set notation: {x | x > 0}

---

## 20. Dots and Ellipses - 1 command

```latex
\lll
```

**Note:** Also written as `\llless` (much less than).

---

## 21. Other Relations - 7 commands

```latex
\ni             \propto         \varpropto      \parallel
\shortparallel  \shortmid       \Perp
```

**Priority:** MEDIUM - `\ni` (reverse element of) and `\propto` (proportional to) are common.

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

### HIGH Priority (Very Common) - ~50 commands
- Trigonometric functions (12)
- Mathematical functions (14)
- Fractions: `\dfrac`, `\tfrac`, `\binom`
- Delimiters: `\lVert`, `\rVert`, `\mid`
- Common symbols: `\ell`, `\hbar`, `\imath`, `\jmath`
- Positioning: `\overset`, `\underset`
- Styling: `\boldsymbol`, `\not`

### MEDIUM Priority (Moderately Common) - ~150 commands
- Arrows (39)
- Harpoons (10)
- Advanced relations (35)
- Set theory relations (12)
- Negated relations (44)
- Binary operators (25)
- Special symbols subset
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

### Phase 1: Functions (HIGH Impact, Easy)
Add all trigonometric and mathematical functions - these are extremely common and trivial to implement.

### Phase 2: Fraction Variants (HIGH Impact, Medium Difficulty)
Implement `\dfrac`, `\tfrac`, `\binom` and variants.

### Phase 3: Essential Symbols (HIGH Impact, Easy)
Add `\ell`, `\hbar`, `\imath`, `\jmath`, `\lVert`, `\rVert`, `\mid`.

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
