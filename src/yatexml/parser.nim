## Parser for LaTeX math expressions
##
## This module implements a recursive descent parser that converts
## tokens into an AST.

import error_handling, ast, lexer, macros as macro_module
import tables, strutils

# Command registry - maps command names to their properties

type
  CommandType = enum
    ctFrac, ctSqrt, ctGreek, ctOperator, ctStyle, ctAccent,
    ctBigOp, ctFunction, ctDelimiter, ctMatrix, ctText, ctSpace, ctColor,
    ctSIunitx, ctSIUnit, ctSIPrefix, ctSIUnitOp, ctMacroDef, ctInfixFrac

  CommandInfo = object
    cmdType: CommandType
    numArgs: int  # Number of required arguments

# Module-level macro registry
var globalMacroRegistry* = macro_module.newMacroRegistry()

# Build command table

proc initCommandTable(): Table[string, CommandInfo] =
  result = initTable[string, CommandInfo]()

  # Fractions
  result["frac"] = CommandInfo(cmdType: ctFrac, numArgs: 2)
  result["cfrac"] = CommandInfo(cmdType: ctFrac, numArgs: 2)  # Continued fractions (same as frac for now)

  # Infix fraction-like commands
  result["over"] = CommandInfo(cmdType: ctInfixFrac, numArgs: 0)
  result["choose"] = CommandInfo(cmdType: ctInfixFrac, numArgs: 0)
  result["atop"] = CommandInfo(cmdType: ctInfixFrac, numArgs: 0)

  # Square roots
  result["sqrt"] = CommandInfo(cmdType: ctSqrt, numArgs: 1)

  # Greek letters (lowercase)
  for letter in ["alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta",
                 "theta", "iota", "kappa", "lambda", "mu", "nu", "xi", "omicron",
                 "pi", "rho", "sigma", "tau", "upsilon", "phi", "chi", "psi", "omega"]:
    result[letter] = CommandInfo(cmdType: ctGreek, numArgs: 0)

  # Greek letters (uppercase)
  for letter in ["Gamma", "Delta", "Theta", "Lambda", "Xi", "Pi", "Sigma",
                 "Upsilon", "Phi", "Psi", "Omega"]:
    result[letter] = CommandInfo(cmdType: ctGreek, numArgs: 0)

  # Greek variants
  for letter in ["varepsilon", "vartheta", "varpi", "varrho", "varsigma", "varphi"]:
    result[letter] = CommandInfo(cmdType: ctGreek, numArgs: 0)

  # Operators
  result["times"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["div"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["pm"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["mp"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["cdot"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["ast"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["star"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["circ"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["bullet"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["oplus"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["otimes"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["ominus"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["cup"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["cap"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["wedge"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["vee"] = CommandInfo(cmdType: ctOperator, numArgs: 0)

  # Relations
  result["ne"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["neq"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["le"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["ge"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["leq"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["geq"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["ll"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["gg"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["equiv"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["sim"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["approx"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["to"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["rightarrow"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["leftarrow"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["leftrightarrow"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["in"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["notin"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["subset"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["supset"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["subseteq"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["supseteq"] = CommandInfo(cmdType: ctOperator, numArgs: 0)

  # Additional symbols
  result["partial"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["vdots"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["cdots"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["ldots"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["dots"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["lvert"] = CommandInfo(cmdType: ctOperator, numArgs: 0)
  result["rvert"] = CommandInfo(cmdType: ctOperator, numArgs: 0)

  # Styles
  result["mathbf"] = CommandInfo(cmdType: ctStyle, numArgs: 1)
  result["mathit"] = CommandInfo(cmdType: ctStyle, numArgs: 1)
  result["mathrm"] = CommandInfo(cmdType: ctStyle, numArgs: 1)
  result["mathbb"] = CommandInfo(cmdType: ctStyle, numArgs: 1)
  result["mathcal"] = CommandInfo(cmdType: ctStyle, numArgs: 1)
  result["mathfrak"] = CommandInfo(cmdType: ctStyle, numArgs: 1)
  result["mathsf"] = CommandInfo(cmdType: ctStyle, numArgs: 1)
  result["mathtt"] = CommandInfo(cmdType: ctStyle, numArgs: 1)

  # Accents
  result["hat"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["bar"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["tilde"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["dot"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["ddot"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["vec"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["widehat"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["widetilde"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["overline"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["underline"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["overbrace"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["underbrace"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["overrightarrow"] = CommandInfo(cmdType: ctAccent, numArgs: 1)
  result["overleftarrow"] = CommandInfo(cmdType: ctAccent, numArgs: 1)

  # Big operators
  result["sum"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["prod"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["int"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["iint"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["iiint"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["oint"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["lim"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["max"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["min"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["bigcup"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)
  result["bigcap"] = CommandInfo(cmdType: ctBigOp, numArgs: 0)

  # Functions
  result["sin"] = CommandInfo(cmdType: ctFunction, numArgs: 0)
  result["cos"] = CommandInfo(cmdType: ctFunction, numArgs: 0)
  result["tan"] = CommandInfo(cmdType: ctFunction, numArgs: 0)
  result["log"] = CommandInfo(cmdType: ctFunction, numArgs: 0)
  result["ln"] = CommandInfo(cmdType: ctFunction, numArgs: 0)
  result["exp"] = CommandInfo(cmdType: ctFunction, numArgs: 0)

  # Delimiters
  result["left"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["right"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["langle"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["rangle"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["lbrace"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["rbrace"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["lfloor"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["rfloor"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["lceil"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["rceil"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["{"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)
  result["}"] = CommandInfo(cmdType: ctDelimiter, numArgs: 0)

  # Matrix environments
  result["begin"] = CommandInfo(cmdType: ctMatrix, numArgs: 0)
  result["end"] = CommandInfo(cmdType: ctMatrix, numArgs: 0)

  # Text mode
  result["text"] = CommandInfo(cmdType: ctText, numArgs: 1)

  # Spacing commands
  result["quad"] = CommandInfo(cmdType: ctSpace, numArgs: 0)
  result["qquad"] = CommandInfo(cmdType: ctSpace, numArgs: 0)
  result[","] = CommandInfo(cmdType: ctSpace, numArgs: 0)
  result[":"] = CommandInfo(cmdType: ctSpace, numArgs: 0)
  result[";"] = CommandInfo(cmdType: ctSpace, numArgs: 0)
  result["!"] = CommandInfo(cmdType: ctSpace, numArgs: 0)

  # Color commands
  result["textcolor"] = CommandInfo(cmdType: ctColor, numArgs: 2)
  result["color"] = CommandInfo(cmdType: ctColor, numArgs: 1)

  # siunitx commands
  result["num"] = CommandInfo(cmdType: ctSIunitx, numArgs: 1)
  result["si"] = CommandInfo(cmdType: ctSIunitx, numArgs: 1)
  result["SI"] = CommandInfo(cmdType: ctSIunitx, numArgs: 2)

  # SI base units
  result["meter"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["second"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["kilogram"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["gram"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)  # For \kilo\gram support
  result["ampere"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["kelvin"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["mole"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["candela"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)

  # SI derived units
  result["hertz"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["newton"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["pascal"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["joule"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["watt"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["coulomb"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["volt"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["farad"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["ohm"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["siemens"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["weber"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["tesla"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["henry"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["lumen"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["lux"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["becquerel"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["gray"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)
  result["sievert"] = CommandInfo(cmdType: ctSIUnit, numArgs: 0)

  # SI prefixes
  result["yocto"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["zepto"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["atto"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["femto"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["pico"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["nano"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["micro"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["milli"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["centi"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["deci"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["deca"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["hecto"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["kilo"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["mega"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["giga"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["tera"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["peta"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["exa"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["zetta"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)
  result["yotta"] = CommandInfo(cmdType: ctSIPrefix, numArgs: 0)

  # Unit operations
  result["per"] = CommandInfo(cmdType: ctSIUnitOp, numArgs: 0)
  result["squared"] = CommandInfo(cmdType: ctSIUnitOp, numArgs: 0)
  result["cubed"] = CommandInfo(cmdType: ctSIUnitOp, numArgs: 0)
  result["tothe"] = CommandInfo(cmdType: ctSIUnitOp, numArgs: 1)

  # Macro definitions
  result["def"] = CommandInfo(cmdType: ctMacroDef, numArgs: 0)  # Special handling
  result["newcommand"] = CommandInfo(cmdType: ctMacroDef, numArgs: 0)  # Special handling

let commandTable = initCommandTable()

# Forward declarations

proc parseExpression(stream: var TokenStream): Result[AstNode]
proc parsePrimary(stream: var TokenStream): Result[AstNode]
proc parseGroup(stream: var TokenStream): Result[AstNode]
proc parseMatrixEnvironment(stream: var TokenStream, matrixType: string): Result[AstNode]

# Greek letter to Unicode mapping

proc greekToUnicode(name: string): string =
  case name
  of "alpha": "\u03B1"
  of "beta": "\u03B2"
  of "gamma": "\u03B3"
  of "delta": "\u03B4"
  of "epsilon": "\u03B5"
  of "zeta": "\u03B6"
  of "eta": "\u03B7"
  of "theta": "\u03B8"
  of "iota": "\u03B9"
  of "kappa": "\u03BA"
  of "lambda": "\u03BB"
  of "mu": "\u03BC"
  of "nu": "\u03BD"
  of "xi": "\u03BE"
  of "omicron": "\u03BF"
  of "pi": "\u03C0"
  of "rho": "\u03C1"
  of "sigma": "\u03C3"
  of "tau": "\u03C4"
  of "upsilon": "\u03C5"
  of "phi": "\u03C6"
  of "chi": "\u03C7"
  of "psi": "\u03C8"
  of "omega": "\u03C9"
  # Uppercase
  of "Gamma": "\u0393"
  of "Delta": "\u0394"
  of "Theta": "\u0398"
  of "Lambda": "\u039B"
  of "Xi": "\u039E"
  of "Pi": "\u03A0"
  of "Sigma": "\u03A3"
  of "Upsilon": "\u03A5"
  of "Phi": "\u03A6"
  of "Psi": "\u03A8"
  of "Omega": "\u03A9"
  # Variants
  of "varepsilon": "\u03F5"
  of "vartheta": "\u03D1"
  of "varpi": "\u03D6"
  of "varrho": "\u03F1"
  of "varsigma": "\u03C2"
  of "varphi": "\u03D5"
  else: "?"

proc operatorToUnicode(name: string): string =
  case name
  of "+": "+"
  of "-": "\u2212"  # Minus sign
  of "*": "\u00D7"  # Multiplication sign
  of "/": "/"
  of "=": "="
  of "<": "<"
  of ">": ">"
  of "times": "\u00D7"
  of "div": "\u00F7"
  of "pm": "\u00B1"
  of "mp": "\u2213"
  of "cdot": "\u22C5"
  of "ast": "\u2217"
  of "star": "\u22C6"
  of "circ": "\u2218"
  of "bullet": "\u2022"
  of "ne", "neq": "\u2260"
  of "le", "leq": "\u2264"
  of "ge", "geq": "\u2265"
  of "ll": "\u226A"
  of "gg": "\u226B"
  of "equiv": "\u2261"
  of "sim": "\u223C"
  of "approx": "\u2248"
  of "to", "rightarrow": "\u2192"
  of "leftarrow": "\u2190"
  of "leftrightarrow": "\u2194"
  of "oplus": "\u2295"
  of "otimes": "\u2297"
  of "ominus": "\u2296"
  of "cup": "\u222A"
  of "cap": "\u2229"
  of "wedge": "\u2227"
  of "vee": "\u2228"
  of "in": "\u2208"
  of "notin": "\u2209"
  of "subset": "\u2282"
  of "supset": "\u2283"
  of "subseteq": "\u2286"
  of "supseteq": "\u2287"
  of "partial": "\u2202"
  of "vdots": "\u22EE"
  of "cdots": "\u22EF"
  of "ldots", "dots": "\u2026"
  of "lvert", "rvert": "|"
  else: name

# Parser implementation

# Helper: Map command name to SI unit kind
proc cmdNameToSIUnit(name: string): SIUnitKind =
  case name
  of "meter": ukMeter
  of "second": ukSecond
  of "kilogram": ukKilogram
  of "gram": ukGram
  of "ampere": ukAmpere
  of "kelvin": ukKelvin
  of "mole": ukMole
  of "candela": ukCandela
  of "hertz": ukHertz
  of "newton": ukNewton
  of "pascal": ukPascal
  of "joule": ukJoule
  of "watt": ukWatt
  of "coulomb": ukCoulomb
  of "volt": ukVolt
  of "farad": ukFarad
  of "ohm": ukOhm
  of "siemens": ukSiemens
  of "weber": ukWeber
  of "tesla": ukTesla
  of "henry": ukHenry
  of "lumen": ukLumen
  of "lux": ukLux
  of "becquerel": ukBecquerel
  of "gray": ukGray
  of "sievert": ukSievert
  else: ukMeter  # fallback

# Helper: Map command name to SI prefix kind
proc cmdNameToSIPrefix(name: string): SIPrefixKind =
  case name
  of "yocto": pkYocto
  of "zepto": pkZepto
  of "atto": pkAtto
  of "femto": pkFemto
  of "pico": pkPico
  of "nano": pkNano
  of "micro": pkMicro
  of "milli": pkMilli
  of "centi": pkCenti
  of "deci": pkDeci
  of "deca": pkDeca
  of "hecto": pkHecto
  of "kilo": pkKilo
  of "mega": pkMega
  of "giga": pkGiga
  of "tera": pkTera
  of "peta": pkPeta
  of "exa": pkExa
  of "zetta": pkZetta
  of "yotta": pkYotta
  else: pkNone

# Helper: Map shorthand unit string to SIUnitKind
proc shorthandToUnit(s: string): SIUnitKind =
  case s
  of "m": ukMeter
  of "s": ukSecond
  of "kg": ukKilogram
  of "g": ukGram
  of "A": ukAmpere
  of "K": ukKelvin
  of "mol": ukMole
  of "cd": ukCandela
  of "Hz": ukHertz
  of "N": ukNewton
  of "Pa": ukPascal
  of "J": ukJoule
  of "W": ukWatt
  of "C": ukCoulomb
  of "V": ukVolt
  of "F": ukFarad
  of "Ω", "ohm": ukOhm
  of "S": ukSiemens
  of "Wb": ukWeber
  of "T": ukTesla
  of "H": ukHenry
  of "lm": ukLumen
  of "lx": ukLux
  of "Bq": ukBecquerel
  of "Gy": ukGray
  of "Sv": ukSievert
  else: ukCustom  # Unknown unit - will be handled as custom

# Helper: Map shorthand prefix character to SIPrefixKind
proc shorthandToPrefix(c: char): SIPrefixKind =
  case c
  of 'y': pkYocto
  of 'z': pkZepto
  of 'a': pkAtto
  of 'f': pkFemto
  of 'p': pkPico
  of 'n': pkNano
  of 'u': pkMicro  # 'u' as ASCII fallback for micro (μ handled separately)
  of 'm': pkMilli
  of 'c': pkCenti
  of 'd': pkDeci
  of 'h': pkHecto
  of 'k': pkKilo
  of 'M': pkMega
  of 'G': pkGiga
  of 'P': pkPeta
  of 'E': pkExa
  of 'Z': pkZetta
  of 'Y': pkYotta
  else: pkNone

# Helper: Map shorthand prefix string to SIPrefixKind (for multi-byte chars)
proc shorthandStrToPrefix(s: string): SIPrefixKind =
  if s.len == 1:
    return shorthandToPrefix(s[0])
  elif s == "μ":
    return pkMicro
  else:
    return pkNone

# Helper: Parse shorthand unit notation like "m.s^{-2}" or "mV.kg"
proc parseShorthandUnits(s: string): tuple[numerator: seq[SIUnitComponent], denominator: seq[SIUnitComponent]] =
  var numerator: seq[SIUnitComponent] = @[]
  var denominator: seq[SIUnitComponent] = @[]

  # Split by dots
  let segments = s.split('.')

  for segment in segments:
    if segment.len == 0:
      continue

    var unitStr = segment
    var power = 1

    # Check for power notation: ^{n} or ^n
    let caretPos = unitStr.find('^')
    if caretPos >= 0:
      var powerStr = unitStr[caretPos + 1 .. ^1]
      unitStr = unitStr[0 ..< caretPos]

      # Remove braces if present
      if powerStr.startsWith("{") and powerStr.endsWith("}"):
        powerStr = powerStr[1 .. ^2]

      try:
        power = parseInt(powerStr)
      except:
        power = 1

    # Try to match known multi-character units first
    var prefix = pkNone
    var unit = ukMeter
    var customUnitStr = ""  # For unknown units
    var matched = false

    # Check for multi-char units (kg, Hz, mol, cd, etc.)
    if unitStr in ["kg", "Hz", "mol", "cd", "Pa", "Wb", "lm", "lx", "Bq", "Gy", "Sv"]:
      unit = shorthandToUnit(unitStr)
      matched = true
    # Check for units with Ω
    elif unitStr.contains("Ω") or unitStr == "ohm":
      # Could be "mΩ" (milliohm) or just "Ω"
      if unitStr.len > 2 and unitStr.endsWith("Ω"):  # mΩ, kΩ, etc. (Ω is 2 bytes)
        let prefixPart = unitStr[0 .. ^3]  # Everything except Ω
        prefix = shorthandStrToPrefix(prefixPart)
        unit = ukOhm
      elif unitStr == "Ω":
        unit = ukOhm
      else:
        unit = ukOhm
      matched = true
    # Check for single-char units (m, s, g, A, K, V, W, C, F, S, T, H, N, J)
    elif unitStr.len == 1:
      unit = shorthandToUnit(unitStr)
      if unit == ukCustom:
        # Unknown single-char unit - preserve it as custom
        customUnitStr = unitStr
      matched = true
    # Check for prefix + single-char unit (km, ms, mA, μV, etc.)
    elif unitStr.len >= 2:
      # Try different prefix lengths (for μ which is 2 bytes in UTF-8)
      var prefixStr = ""
      var unitPart = ""

      # Check if starts with μ (2-byte UTF-8 character)
      if unitStr.startsWith("μ"):
        prefixStr = "μ"
        unitPart = unitStr[2 .. ^1]
      elif unitStr.len == 2:
        prefixStr = $unitStr[0]
        unitPart = $unitStr[1]
      elif unitStr.len > 2:
        # Could be prefix + multi-char unit
        let possibleUnit = unitStr[1 .. ^1]
        if possibleUnit in ["Hz", "Pa", "Wb", "lm", "lx", "Bq", "Gy", "Sv", "mol", "cd"]:
          prefixStr = $unitStr[0]
          unitPart = possibleUnit
        else:
          # Try as single-char prefix + single-char unit
          prefixStr = $unitStr[0]
          unitPart = $unitStr[1]

      if unitPart.len > 0:
        prefix = shorthandStrToPrefix(prefixStr)
        unit = shorthandToUnit(unitPart)
        if unit == ukCustom:
          # Unknown unit - preserve original string as custom (don't use prefix)
          customUnitStr = unitStr
          prefix = pkNone  # Reset prefix since it's part of the custom unit string
        matched = true

    # If no match at all, treat entire string as custom unit
    if not matched:
      customUnitStr = unitStr
      matched = true

    if matched:
      let component = if customUnitStr.len > 0:
        newCustomUnitComponent(customUnitStr, pkNone, abs(power))  # Never use prefix with custom units
      else:
        newSIUnitComponent(prefix, unit, abs(power))

      if power < 0:
        denominator.add(component)
      else:
        numerator.add(component)

  result = (numerator: numerator, denominator: denominator)

# Helper: Parse SI unit expression
proc parseSIUnitExpr(stream: var TokenStream): Result[AstNode] =
  ## Parse a unit expression like \meter\per\second or \kilo\meter
  var numerator: seq[SIUnitComponent] = @[]
  var denominator: seq[SIUnitComponent] = @[]
  var inDenominator = false
  var currentPrefix = pkNone
  var currentPower = 1

  while not stream.match(tkRightBrace) and not stream.isAtEnd():
    let token = stream.peek()

    if token.kind == tkCommand:
      let cmdName = token.value
      if commandTable.hasKey(cmdName):
        let cmdInfo = commandTable[cmdName]

        case cmdInfo.cmdType
        of ctSIPrefix:
          # Store prefix for next unit
          discard stream.advance()
          currentPrefix = cmdNameToSIPrefix(cmdName)

        of ctSIUnit:
          # Add unit component
          discard stream.advance()
          let unitKind = cmdNameToSIUnit(cmdName)
          let component = newSIUnitComponent(currentPrefix, unitKind, currentPower)
          if inDenominator:
            denominator.add(component)
          else:
            numerator.add(component)
          # Reset for next unit
          currentPrefix = pkNone
          currentPower = 1

        of ctSIUnitOp:
          discard stream.advance()
          case cmdName
          of "per":
            inDenominator = true
          of "squared":
            # Apply to last unit
            if inDenominator and denominator.len > 0:
              denominator[^1].power = 2
            elif numerator.len > 0:
              numerator[^1].power = 2
          of "cubed":
            # Apply to last unit
            if inDenominator and denominator.len > 0:
              denominator[^1].power = 3
            elif numerator.len > 0:
              numerator[^1].power = 3
          of "tothe":
            # Parse power argument
            let braceResult = stream.expect(tkLeftBrace)
            if not braceResult.isOk:
              return err[AstNode](ekMismatchedBraces, "Expected { after \\tothe", token.position)

            var powerStr = ""
            while not stream.match(tkRightBrace) and not stream.isAtEnd():
              let powerToken = stream.advance()
              powerStr.add(powerToken.value)

            let closeResult = stream.expect(tkRightBrace)
            if not closeResult.isOk:
              return err[AstNode](ekMismatchedBraces, "Expected } after power", token.position)

            try:
              let power = parseInt(powerStr)
              if inDenominator and denominator.len > 0:
                denominator[^1].power = power
              elif numerator.len > 0:
                numerator[^1].power = power
            except:
              discard  # Invalid power, ignore

          else:
            discard
        else:
          # Non-unit command in unit expression, skip
          discard stream.advance()
      else:
        # Unknown command, skip
        discard stream.advance()
    else:
      # Non-command token - could be shorthand notation
      # Collect all text until right brace (including operators, numbers, ^, {, })
      var shorthandStr = ""
      var braceDepth = 0
      while not stream.isAtEnd():
        let t = stream.peek()

        # Stop at right brace if we're at depth 0 (the closing brace of \si{...})
        if t.kind == tkRightBrace and braceDepth == 0:
          break

        # Stop if we hit a command (unless it's inside braces for powers)
        if t.kind == tkCommand and braceDepth == 0:
          break

        # Track brace depth for power notation like ^{-2}
        if t.kind == tkLeftBrace:
          braceDepth += 1
        elif t.kind == tkRightBrace:
          braceDepth -= 1

        shorthandStr.add(t.value)
        discard stream.advance()

      # If we collected text, try to parse it as shorthand notation
      if shorthandStr.len > 0:
        let (shortNum, shortDenom) = parseShorthandUnits(shorthandStr)
        numerator.add(shortNum)
        denominator.add(shortDenom)
        break  # Shorthand notation replaces the entire unit expression

  return ok(newSIUnit(numerator, denominator))

# Macro-related helper functions

proc parseMacroDef(stream: var TokenStream, cmdName: string, position: int): Result[bool] =
  ## Parse \def or \newcommand and register the macro
  ## Returns ok(true) if macro was successfully defined
  ## This does NOT return an AST node because macro definitions don't produce output

  if cmdName == "def":
    # \def\macroname{body}
    # Expect \macroname
    let macroToken = stream.peek()
    if macroToken.kind != tkCommand:
      return err[bool](ekInvalidArgument, "Expected command after \\def", position)
    let macroName = macroToken.value
    discard stream.advance()

    # Parse body in braces
    let bodyResult = stream.expect(tkLeftBrace)
    if not bodyResult.isOk:
      return err[bool](bodyResult.error)

    # Collect all tokens until matching right brace
    var body: seq[Token] = @[]
    var braceDepth = 1
    while not stream.isAtEnd() and braceDepth > 0:
      let t = stream.peek()
      if t.kind == tkLeftBrace:
        braceDepth += 1
        body.add(t)
        discard stream.advance()
      elif t.kind == tkRightBrace:
        braceDepth -= 1
        if braceDepth > 0:
          body.add(t)
        discard stream.advance()
      else:
        body.add(t)
        discard stream.advance()

    # Register the macro (assumes no arguments for \def)
    macro_module.defineMacro(globalMacroRegistry, macroName, 0, body)
    return ok(true)

  elif cmdName == "newcommand":
    # \newcommand{\macroname}[numargs]{body}
    # Expect left brace
    let braceResult = stream.expect(tkLeftBrace)
    if not braceResult.isOk:
      return err[bool](braceResult.error)

    # Expect \macroname
    let macroToken = stream.peek()
    if macroToken.kind != tkCommand:
      return err[bool](ekInvalidArgument, "Expected command in \\newcommand", position)
    let macroName = macroToken.value
    discard stream.advance()

    # Expect right brace
    let closeResult = stream.expect(tkRightBrace)
    if not closeResult.isOk:
      return err[bool](closeResult.error)

    # Check for optional [numargs]
    var numArgs = 0
    if stream.match(tkLeftBracket):
      discard stream.advance()
      let argToken = stream.peek()
      if argToken.kind != tkNumber:
        return err[bool](ekInvalidArgument, "Expected number in \\newcommand argument count", argToken.position)
      try:
        numArgs = parseInt(argToken.value)
      except:
        return err[bool](ekInvalidArgument, "Invalid argument count in \\newcommand", argToken.position)
      discard stream.advance()
      let closeBracketResult = stream.expect(tkRightBracket)
      if not closeBracketResult.isOk:
        return err[bool](closeBracketResult.error)

    # Parse body in braces
    let bodyBraceResult = stream.expect(tkLeftBrace)
    if not bodyBraceResult.isOk:
      return err[bool](bodyBraceResult.error)

    # Collect all tokens until matching right brace
    var body: seq[Token] = @[]
    var braceDepth = 1
    while not stream.isAtEnd() and braceDepth > 0:
      let t = stream.peek()
      if t.kind == tkLeftBrace:
        braceDepth += 1
        body.add(t)
        discard stream.advance()
      elif t.kind == tkRightBrace:
        braceDepth -= 1
        if braceDepth > 0:
          body.add(t)
        discard stream.advance()
      else:
        body.add(t)
        discard stream.advance()

    # Register the macro
    macro_module.defineMacro(globalMacroRegistry, macroName, numArgs, body)
    return ok(true)

  else:
    return err[bool](ekInvalidCommand, "Unknown macro definition command: \\" & cmdName, position)

proc expandMacroInStream(stream: var TokenStream, macroName: string, macroDef: macro_module.MacroDefinition): Result[seq[Token]] =
  ## Expand a macro by parsing its arguments and substituting them in the body
  ## Returns the expanded tokens

  var args: seq[seq[Token]] = @[]

  # Parse arguments if macro has any
  for i in 0 ..< macroDef.numArgs:
    # Each argument should be in braces
    let braceResult = stream.expect(tkLeftBrace)
    if not braceResult.isOk:
      return err[seq[Token]](braceResult.error)

    # Collect tokens until matching right brace
    var argTokens: seq[Token] = @[]
    var braceDepth = 1
    while not stream.isAtEnd() and braceDepth > 0:
      let t = stream.peek()
      if t.kind == tkLeftBrace:
        braceDepth += 1
        argTokens.add(t)
        discard stream.advance()
      elif t.kind == tkRightBrace:
        braceDepth -= 1
        if braceDepth > 0:
          argTokens.add(t)
        discard stream.advance()
      else:
        argTokens.add(t)
        discard stream.advance()

    args.add(argTokens)

  # Expand the macro
  let expandedTokens = macro_module.expandMacro(globalMacroRegistry, macroDef, args)
  return ok(expandedTokens)

proc parsePrimary(stream: var TokenStream): Result[AstNode] =
  ## Parse a primary expression (atom)
  let token = stream.peek()

  case token.kind
  of tkNumber:
    discard stream.advance()
    return ok(newNumber(token.value))

  of tkIdentifier:
    discard stream.advance()
    return ok(newIdentifier(token.value))

  of tkOperator:
    discard stream.advance()
    let unicode = operatorToUnicode(token.value)
    return ok(newOperator(token.value, unicode))

  of tkLeftBrace:
    return parseGroup(stream)

  of tkLeftParen:
    discard stream.advance()
    let exprResult = parseExpression(stream)
    if not exprResult.isOk:
      return err[AstNode](exprResult.error)
    let closeResult = stream.expect(tkRightParen)
    if not closeResult.isOk:
      return err[AstNode](closeResult.error)
    return ok(newDelimited("(", ")", exprResult.value))

  of tkCommand:
    discard stream.advance()
    let cmdName = token.value

    # Check if it's a known command
    if cmdName in commandTable:
      let cmdInfo = commandTable[cmdName]

      case cmdInfo.cmdType
      of ctFrac:
        # Parse numerator and denominator
        let numResult = parseGroup(stream)
        if not numResult.isOk:
          return err[AstNode](numResult.error)
        let denomResult = parseGroup(stream)
        if not denomResult.isOk:
          return err[AstNode](denomResult.error)
        return ok(newFrac(numResult.value, denomResult.value))

      of ctSqrt:
        # Check for optional argument [n] for nth root
        if stream.match(tkLeftBracket):
          discard stream.advance()
          let indexResult = parseExpression(stream)
          if not indexResult.isOk:
            return err[AstNode](indexResult.error)
          let closeResult = stream.expect(tkRightBracket)
          if not closeResult.isOk:
            return err[AstNode](closeResult.error)
          let baseResult = parseGroup(stream)
          if not baseResult.isOk:
            return err[AstNode](baseResult.error)
          return ok(newRoot(baseResult.value, indexResult.value))
        else:
          let baseResult = parseGroup(stream)
          if not baseResult.isOk:
            return err[AstNode](baseResult.error)
          return ok(newSqrt(baseResult.value))

      of ctGreek:
        let unicode = greekToUnicode(cmdName)
        return ok(newSymbol(cmdName, unicode))

      of ctOperator:
        let unicode = operatorToUnicode(cmdName)
        return ok(newOperator(cmdName, unicode))

      of ctStyle:
        let styleKind = case cmdName
          of "mathbf": skBold
          of "mathit": skItalic
          of "mathrm": skRoman
          of "mathbb": skBlackboard
          of "mathcal": skCalligraphic
          of "mathfrak": skFraktur
          of "mathsf": skSansSerif
          of "mathtt": skMonospace
          else: skRoman

        let argResult = parseGroup(stream)
        if not argResult.isOk:
          return err[AstNode](argResult.error)
        return ok(newStyle(styleKind, argResult.value))

      of ctAccent:
        let accentKind = case cmdName
          of "hat": akHat
          of "bar": akBar
          of "tilde": akTilde
          of "dot": akDot
          of "ddot": akDdot
          of "vec": akVec
          of "widehat": akWidehat
          of "widetilde": akWidetilde
          of "overline": akOverline
          of "underline": akUnderline
          of "overbrace": akOverbrace
          of "underbrace": akUnderbrace
          of "overrightarrow": akOverrightarrow
          of "overleftarrow": akOverleftarrow
          else: akHat

        let argResult = parseGroup(stream)
        if not argResult.isOk:
          return err[AstNode](argResult.error)
        return ok(newAccent(accentKind, argResult.value))

      of ctBigOp:
        let bigopKind = case cmdName
          of "sum": boSum
          of "prod": boProd
          of "int": boInt
          of "iint": boIInt
          of "iiint": boIIInt
          of "oint": boOint
          of "bigcup": boUnion
          of "bigcap": boIntersect
          of "lim": boLim
          of "max": boMax
          of "min": boMin
          else: boSum

        # Parse optional subscript and superscript
        var lower, upper: AstNode = nil

        if stream.match(tkSubscript):
          discard stream.advance()
          let lowerResult = if stream.match(tkLeftBrace): parseGroup(stream)
                            else: parsePrimary(stream)
          if not lowerResult.isOk:
            return err[AstNode](lowerResult.error)
          lower = lowerResult.value

        if stream.match(tkSuperscript):
          discard stream.advance()
          let upperResult = if stream.match(tkLeftBrace): parseGroup(stream)
                             else: parsePrimary(stream)
          if not upperResult.isOk:
            return err[AstNode](upperResult.error)
          upper = upperResult.value

        return ok(newBigOp(bigopKind, lower, upper))

      of ctFunction:
        # Function name becomes identifier in roman style
        return ok(newFunction(cmdName, nil))

      of ctDelimiter:
        # Handle \left and \right delimiters
        if cmdName == "left":
          # Parse the delimiter token
          let delimToken = stream.peek()
          var leftDelim: string

          case delimToken.kind
          of tkLeftParen:
            discard stream.advance()
            leftDelim = "("
          of tkLeftBracket:
            discard stream.advance()
            leftDelim = "["
          of tkLeftVert:
            discard stream.advance()
            leftDelim = "|"
          of tkOperator:
            if delimToken.value == "{":
              discard stream.advance()
              leftDelim = "{"
            elif delimToken.value == "}":
              discard stream.advance()
              leftDelim = "}"
            else:
              return err[AstNode](ekInvalidArgument, "Invalid left delimiter: " & delimToken.value, delimToken.position)
          of tkCommand:
            discard stream.advance()
            case delimToken.value
            of "lbrace", "{": leftDelim = "{"
            of "rbrace", "}": leftDelim = "}"
            of "langle": leftDelim = "⟨"
            of "rangle": leftDelim = "⟩"
            of "lfloor": leftDelim = "⌊"
            of "rfloor": leftDelim = "⌋"
            of "lceil": leftDelim = "⌈"
            of "rceil": leftDelim = "⌉"
            else:
              return err[AstNode](ekInvalidArgument, "Unknown left delimiter: \\" & delimToken.value, delimToken.position)
          else:
            return err[AstNode](ekInvalidArgument, "Expected delimiter after \\left", delimToken.position)

          # Parse the content
          let contentResult = parseExpression(stream)
          if not contentResult.isOk:
            return err[AstNode](contentResult.error)

          # Expect \right
          let rightCmdToken = stream.peek()
          if rightCmdToken.kind != tkCommand or rightCmdToken.value != "right":
            return err[AstNode](ekMismatchedBraces, "Expected \\right after \\left", rightCmdToken.position)
          discard stream.advance()

          # Parse the right delimiter token
          let rightDelimToken = stream.peek()
          var rightDelim: string

          case rightDelimToken.kind
          of tkRightParen:
            discard stream.advance()
            rightDelim = ")"
          of tkRightBracket:
            discard stream.advance()
            rightDelim = "]"
          of tkLeftVert, tkRightVert:
            discard stream.advance()
            rightDelim = "|"
          of tkOperator:
            if rightDelimToken.value == "{":
              discard stream.advance()
              rightDelim = "{"
            elif rightDelimToken.value == "}":
              discard stream.advance()
              rightDelim = "}"
            else:
              return err[AstNode](ekInvalidArgument, "Invalid right delimiter: " & rightDelimToken.value, rightDelimToken.position)
          of tkCommand:
            discard stream.advance()
            case rightDelimToken.value
            of "rbrace", "}": rightDelim = "}"
            of "lbrace", "{": rightDelim = "{"
            of "rangle": rightDelim = "⟩"
            of "langle": rightDelim = "⟨"
            of "rfloor": rightDelim = "⌋"
            of "lfloor": rightDelim = "⌊"
            of "rceil": rightDelim = "⌉"
            of "lceil": rightDelim = "⌈"
            else:
              return err[AstNode](ekInvalidArgument, "Unknown right delimiter: \\" & rightDelimToken.value, rightDelimToken.position)
          else:
            return err[AstNode](ekInvalidArgument, "Expected delimiter after \\right", rightDelimToken.position)

          return ok(newDelimited(leftDelim, rightDelim, contentResult.value))
        else:
          return err[AstNode](ekInvalidCommand, "\\right must be paired with \\left", token.position)

      of ctMatrix:
        # Handle \begin{matrix_type}
        if cmdName == "begin":
          # Expect environment name in braces
          let braceResult = stream.expect(tkLeftBrace)
          if not braceResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected { after \\begin", token.position)

          # Read environment name (multiple identifiers like "pmatrix")
          var envName = ""
          let nameToken = stream.peek()
          if nameToken.kind == tkIdentifier:
            while stream.peek().kind == tkIdentifier and not stream.match(tkRightBrace):
              envName.add(stream.advance().value)
          else:
            return err[AstNode](ekInvalidArgument, "Expected environment name after \\begin{", nameToken.position)

          let closeResult = stream.expect(tkRightBrace)
          if not closeResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected } after environment name", nameToken.position)

          # Check if it's a matrix or alignment environment
          if envName in ["matrix", "pmatrix", "bmatrix", "vmatrix", "Vmatrix", "cases",
                         "align", "aligned", "gather", "gathered"]:
            return parseMatrixEnvironment(stream, envName)
          else:
            return err[AstNode](ekInvalidCommand, "Unknown environment: " & envName, token.position)
        else:
          # \end command should only appear inside matrix parsing
          return err[AstNode](ekInvalidCommand, "Unexpected \\end command", token.position)

      of ctText:
        # Parse \text{content} - content is literal text, not math
        let braceResult = stream.expect(tkLeftBrace)
        if not braceResult.isOk:
          return err[AstNode](ekMismatchedBraces, "Expected { after \\text", token.position)

        # Collect all tokens until right brace as text
        # We need to preserve whitespace, so we build text with spaces between tokens
        var textContent = ""
        var lastPos = braceResult.value.position + 1  # Position after {
        while not stream.match(tkRightBrace) and not stream.isAtEnd():
          let textToken = stream.peek()

          # Add spaces for gaps between last position and current token
          let gap = textToken.position - lastPos
          if gap > 0:
            textContent.add(" ".repeat(gap))

          discard stream.advance()
          case textToken.kind
          of tkIdentifier, tkNumber:
            textContent.add(textToken.value)
            lastPos = textToken.position + textToken.value.len
          of tkOperator:
            textContent.add(textToken.value)
            lastPos = textToken.position + textToken.value.len
          of tkLeftParen:
            textContent.add("(")
            lastPos = textToken.position + 1
          of tkRightParen:
            textContent.add(")")
            lastPos = textToken.position + 1
          of tkLeftBracket:
            textContent.add("[")
            lastPos = textToken.position + 1
          of tkRightBracket:
            textContent.add("]")
            lastPos = textToken.position + 1
          of tkCommand:
            # Handle escaped characters in text mode
            textContent.add("\\")
            textContent.add(textToken.value)
            lastPos = textToken.position + 1 + textToken.value.len
          else:
            # For other tokens, just add their value
            textContent.add(textToken.value)
            lastPos = textToken.position + textToken.value.len

        let closeResult = stream.expect(tkRightBrace)
        if not closeResult.isOk:
          return err[AstNode](ekMismatchedBraces, "Expected } after text content", token.position)

        return ok(newText(textContent))

      of ctSpace:
        # Parse spacing commands
        # Map command name to MathML width specification
        let width = case cmdName
          of "quad": "1em"
          of "qquad": "2em"
          of ",": "0.1667em"    # thin space (3/18 em)
          of ":": "0.2222em"    # medium space (4/18 em)
          of ";": "0.2778em"    # thick space (5/18 em)
          of "!": "-0.1667em"   # negative thin space (-3/18 em)
          else: "0.5em"         # default

        return ok(newSpace(width))

      of ctColor:
        # Parse color commands: \textcolor{color}{content} or \color{color}
        if cmdName == "textcolor":
          # \textcolor{color}{content}
          # First argument: color name
          let colorBraceResult = stream.expect(tkLeftBrace)
          if not colorBraceResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected { after \\textcolor", token.position)

          var colorName = ""
          while not stream.match(tkRightBrace) and not stream.isAtEnd():
            let colorToken = stream.advance()
            colorName.add(colorToken.value)

          let colorCloseResult = stream.expect(tkRightBrace)
          if not colorCloseResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected } after color name", token.position)

          # Second argument: content to color
          let contentResult = parseGroup(stream)
          if not contentResult.isOk:
            return err[AstNode](contentResult.error)

          return ok(newColor(colorName, contentResult.value))

        else:  # \color{color}
          # \color{color} - colors all following content
          let colorBraceResult = stream.expect(tkLeftBrace)
          if not colorBraceResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected { after \\color", token.position)

          var colorName = ""
          while not stream.match(tkRightBrace) and not stream.isAtEnd():
            let colorToken = stream.advance()
            colorName.add(colorToken.value)

          let colorCloseResult = stream.expect(tkRightBrace)
          if not colorCloseResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected } after color name", token.position)

          # Parse rest of expression with this color
          let contentResult = parseExpression(stream)
          if not contentResult.isOk:
            return err[AstNode](contentResult.error)

          return ok(newColor(colorName, contentResult.value))

      of ctSIunitx:
        # Parse siunitx commands: \num{number}, \si{unit}, \SI{value}{unit}
        if cmdName == "num":
          # \num{number}
          let braceResult = stream.expect(tkLeftBrace)
          if not braceResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected { after \\num", token.position)

          var numberStr = ""
          while not stream.match(tkRightBrace) and not stream.isAtEnd():
            let numToken = stream.advance()
            numberStr.add(numToken.value)

          let closeResult = stream.expect(tkRightBrace)
          if not closeResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected } after number", token.position)

          return ok(newNum(numberStr))

        elif cmdName == "si":
          # \si{unit}
          let braceResult = stream.expect(tkLeftBrace)
          if not braceResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected { after \\si", token.position)

          # Parse unit expression
          let unitResult = parseSIUnitExpr(stream)
          if not unitResult.isOk:
            return err[AstNode](unitResult.error)

          let closeResult = stream.expect(tkRightBrace)
          if not closeResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected } after unit", token.position)

          return ok(unitResult.value)

        elif cmdName == "SI":
          # \SI{value}{unit}
          # First argument: value
          let valueBraceResult = stream.expect(tkLeftBrace)
          if not valueBraceResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected { after \\SI", token.position)

          var valueStr = ""
          while not stream.match(tkRightBrace) and not stream.isAtEnd():
            let valueToken = stream.advance()
            valueStr.add(valueToken.value)

          let valueCloseResult = stream.expect(tkRightBrace)
          if not valueCloseResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected } after value", token.position)

          # Second argument: unit
          let unitBraceResult = stream.expect(tkLeftBrace)
          if not unitBraceResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected { for unit", token.position)

          # Parse unit expression
          let unitResult = parseSIUnitExpr(stream)
          if not unitResult.isOk:
            return err[AstNode](unitResult.error)

          let unitCloseResult = stream.expect(tkRightBrace)
          if not unitCloseResult.isOk:
            return err[AstNode](ekMismatchedBraces, "Expected } after unit", token.position)

          return ok(newSIValue(valueStr, unitResult.value))

        else:
          return err[AstNode](ekInvalidCommand, "Unknown siunitx command: \\" & cmdName, token.position)

      of ctMacroDef:
        # Handle \def and \newcommand - these don't produce AST nodes
        let defResult = parseMacroDef(stream, cmdName, token.position)
        if not defResult.isOk:
          return err[AstNode](defResult.error)

        # Macro definitions don't produce output, so parse the next expression
        return parsePrimary(stream)

      of ctInfixFrac:
        # Infix fractions (\over, \choose, \atop) are handled in parseExpression
        # If we reach here, it's an error (no left operand)
        return err[AstNode](
          ekInvalidCommand,
          "Infix command \\" & cmdName & " requires a left operand",
          token.position
        )

      of ctSIUnit, ctSIPrefix, ctSIUnitOp:
        # These should only appear within \si or \SI contexts
        # If they appear outside, treat as error
        return err[AstNode](
          ekInvalidCommand,
          "Unit command \\" & cmdName & " can only be used within \\si or \\SI",
          token.position
        )
    else:
      # Unknown command - check if it's a macro
      if macro_module.hasMacro(globalMacroRegistry, cmdName):
        let macroDef = macro_module.getMacro(globalMacroRegistry, cmdName)

        # Expand the macro
        let expandResult = expandMacroInStream(stream, cmdName, macroDef)
        if not expandResult.isOk:
          return err[AstNode](expandResult.error)

        # Create a new token stream from the expanded tokens
        let expandedTokens = expandResult.value
        var expandedStream = newTokenStream(expandedTokens)

        # Parse the expanded expression (use parseExpression to handle scripts)
        return parseExpression(expandedStream)
      else:
        # Not a macro - treat as identifier
        return ok(newIdentifier(cmdName))

  of tkSubscript, tkSuperscript:
    # Leading subscript or superscript (e.g., _2F_3 for hypergeometric functions)
    # Create with empty/phantom base
    discard stream.advance()
    let scriptResult = if stream.match(tkLeftBrace): parseGroup(stream)
                       else: parsePrimary(stream)
    if not scriptResult.isOk:
      return err[AstNode](scriptResult.error)

    # Use empty row as phantom base
    let emptyBase = newRow(@[])
    if token.kind == tkSubscript:
      return ok(newSub(emptyBase, scriptResult.value))
    else:
      return ok(newSup(emptyBase, scriptResult.value))

  of tkEof:
    return err[AstNode](ekUnexpectedEof, "Unexpected end of input", token.position)

  else:
    return err[AstNode](
      ekUnexpectedToken,
      "Unexpected token: " & $token.kind,
      token.position
    )

proc parseMatrixEnvironment(stream: var TokenStream, matrixType: string): Result[AstNode] =
  ## Parse a matrix environment: rows separated by \\, columns by &
  var rows: seq[seq[AstNode]] = @[]
  var currentRow: seq[AstNode] = @[]

  # Check if this is an alignment environment (needs expression-level parsing)
  let isAlignmentEnv = matrixType in ["align", "aligned", "gather", "gathered"]

  # Track if we're at the start of a new cell
  var startOfCell = true

  # Parse matrix content until we hit \end
  while not stream.isAtEnd():
    let token = stream.peek()

    # Check for \end command
    if token.kind == tkCommand and token.value == "end":
      # Consume \end
      discard stream.advance()

      # Expect environment name in braces
      let braceResult = stream.expect(tkLeftBrace)
      if not braceResult.isOk:
        return err[AstNode](ekMismatchedBraces, "Expected { after \\end", token.position)

      # Read environment name
      let nameToken = stream.peek()
      var endEnvName = ""
      if nameToken.kind == tkIdentifier:
        while stream.peek().kind == tkIdentifier and not stream.match(tkRightBrace):
          endEnvName.add(stream.advance().value)
      else:
        return err[AstNode](ekInvalidArgument, "Expected environment name after \\end{", nameToken.position)

      let closeResult = stream.expect(tkRightBrace)
      if not closeResult.isOk:
        return err[AstNode](ekMismatchedBraces, "Expected } after environment name", nameToken.position)

      # Verify environment names match
      if endEnvName != matrixType:
        return err[AstNode](ekInvalidArgument, "Environment mismatch: \\begin{" & matrixType & "} ended with \\end{" & endEnvName & "}", token.position)

      # Save current row if any
      if currentRow.len > 0:
        rows.add(currentRow)

      # Return matrix node
      return ok(newMatrix(rows, matrixType))

    # Check for line break (\\)
    elif token.kind == tkLineBreak:
      discard stream.advance()

      # Save current row
      if currentRow.len > 0:
        rows.add(currentRow)
        currentRow = @[]

      startOfCell = true

    # Check for column separator (&)
    elif token.kind == tkAmpersand:
      discard stream.advance()
      startOfCell = true

    # Regular expression - parse it
    elif startOfCell:
      # For alignment environments, parse entire cell as one expression
      # For matrices, parse as before (accumulate primaries)
      if isAlignmentEnv:
        # Parse the entire cell expression (stops at & or \\)
        let cellResult = parseExpression(stream)
        if not cellResult.isOk:
          # Empty cell is okay - add empty row
          if cellResult.error.kind == ekUnexpectedEof:
            currentRow.add(newRow(@[]))
            startOfCell = false
          else:
            return err[AstNode](cellResult.error)
        else:
          currentRow.add(cellResult.value)
          startOfCell = false
      else:
        # Original logic for matrices: accumulate expressions per cell
        var cellExpressions: seq[AstNode] = @[]

        # Collect all expressions until & or \\
        while not stream.isAtEnd():
          let t = stream.peek()
          if t.kind in [tkAmpersand, tkLineBreak] or (t.kind == tkCommand and t.value == "end"):
            break

          let exprResult = parsePrimary(stream)
          if not exprResult.isOk:
            return err[AstNode](exprResult.error)

          # Check for scripts after the primary
          var node = exprResult.value
          while stream.match(tkSubscript) or stream.match(tkSuperscript):
            if stream.match(tkSubscript):
              discard stream.advance()
              let subResult = if stream.match(tkLeftBrace): parseGroup(stream)
                              else: parsePrimary(stream)
              if not subResult.isOk:
                return err[AstNode](subResult.error)

              # Check if followed by superscript
              if stream.match(tkSuperscript):
                discard stream.advance()
                let supResult = if stream.match(tkLeftBrace): parseGroup(stream)
                                else: parsePrimary(stream)
                if not supResult.isOk:
                  return err[AstNode](supResult.error)
                node = newSubSup(node, subResult.value, supResult.value)
              else:
                node = newSub(node, subResult.value)

            elif stream.match(tkSuperscript):
              discard stream.advance()
              let supResult = if stream.match(tkLeftBrace): parseGroup(stream)
                              else: parsePrimary(stream)
              if not supResult.isOk:
                return err[AstNode](supResult.error)
              node = newSup(node, supResult.value)

          # Check for factorial operator
          if stream.match(tkOperator) and stream.peek().value == "!":
            discard stream.advance()
            node = newRow(@[node, newOperator("factorial", "!", "postfix")])

          cellExpressions.add(node)

        # Add cell to row
        if cellExpressions.len == 0:
          currentRow.add(newRow(@[]))
        elif cellExpressions.len == 1:
          currentRow.add(cellExpressions[0])
        else:
          currentRow.add(newRow(cellExpressions))

        startOfCell = false
    else:
      # Skip any other tokens (shouldn't happen)
      discard stream.advance()

  return err[AstNode](ekUnexpectedEof, "Matrix environment not closed with \\end{" & matrixType & "}", 0)

proc parseGroup(stream: var TokenStream): Result[AstNode] =
  ## Parse a group {...}
  let openResult = stream.expect(tkLeftBrace)
  if not openResult.isOk:
    return err[AstNode](openResult.error)

  var children: seq[AstNode] = @[]

  while not stream.match(tkRightBrace) and not stream.isAtEnd():
    let exprResult = parsePrimary(stream)
    if not exprResult.isOk:
      return err[AstNode](exprResult.error)

    # Check for scripts after the primary
    var node = exprResult.value
    while stream.match(tkSubscript) or stream.match(tkSuperscript):
      if stream.match(tkSubscript):
        discard stream.advance()
        let subResult = if stream.match(tkLeftBrace): parseGroup(stream)
                        else: parsePrimary(stream)
        if not subResult.isOk:
          return err[AstNode](subResult.error)

        # Check if followed by superscript
        if stream.match(tkSuperscript):
          discard stream.advance()
          let supResult = if stream.match(tkLeftBrace): parseGroup(stream)
                          else: parsePrimary(stream)
          if not supResult.isOk:
            return err[AstNode](supResult.error)
          node = newSubSup(node, subResult.value, supResult.value)
        else:
          node = newSub(node, subResult.value)

      elif stream.match(tkSuperscript):
        discard stream.advance()
        let supResult = if stream.match(tkLeftBrace): parseGroup(stream)
                        else: parsePrimary(stream)
        if not supResult.isOk:
          return err[AstNode](supResult.error)
        node = newSup(node, supResult.value)

    # Check for factorial operator
    if stream.match(tkOperator) and stream.peek().value == "!":
      discard stream.advance()
      node = newRow(@[node, newOperator("factorial", "!", "postfix")])

    children.add(node)

    # Check for infix fraction commands (\over, \choose, \atop) - same as in parseExpression
    if stream.match(tkCommand):
      let cmdName = stream.peek().value
      if cmdName in commandTable and commandTable[cmdName].cmdType == ctInfixFrac:
        discard stream.advance()  # consume the command

        # Take all children so far as the numerator/left operand
        let leftNode = if children.len == 1: children[0] else: newRow(children)

        # Parse the rest as the denominator/right operand (until closing brace)
        var rightChildren: seq[AstNode] = @[]
        while not stream.match(tkRightBrace) and not stream.isAtEnd():
          let primResult = parsePrimary(stream)
          if not primResult.isOk:
            return err[AstNode](primResult.error)

          var rightNode = primResult.value
          while stream.match(tkSubscript) or stream.match(tkSuperscript):
            if stream.match(tkSubscript):
              discard stream.advance()
              let subResult = if stream.match(tkLeftBrace): parseGroup(stream)
                              else: parsePrimary(stream)
              if not subResult.isOk:
                return err[AstNode](subResult.error)
              if stream.match(tkSuperscript):
                discard stream.advance()
                let supResult = if stream.match(tkLeftBrace): parseGroup(stream)
                                else: parsePrimary(stream)
                if not supResult.isOk:
                  return err[AstNode](supResult.error)
                rightNode = newSubSup(rightNode, subResult.value, supResult.value)
              else:
                rightNode = newSub(rightNode, subResult.value)
            elif stream.match(tkSuperscript):
              discard stream.advance()
              let supResult = if stream.match(tkLeftBrace): parseGroup(stream)
                              else: parsePrimary(stream)
              if not supResult.isOk:
                return err[AstNode](supResult.error)
              rightNode = newSup(rightNode, supResult.value)

          # Check for factorial operator
          if stream.match(tkOperator) and stream.peek().value == "!":
            discard stream.advance()
            rightNode = newRow(@[rightNode, newOperator("factorial", "!", "postfix")])

          rightChildren.add(rightNode)

        let rightNode = if rightChildren.len == 1: rightChildren[0] else: newRow(rightChildren)

        # Create the appropriate node based on the command
        let resultNode = case cmdName
          of "over": newFrac(leftNode, rightNode)
          of "choose": newBinomial(leftNode, rightNode)
          of "atop": newAtop(leftNode, rightNode)
          else: leftNode  # shouldn't happen

        # Expect closing brace
        let closeResult = stream.expect(tkRightBrace)
        if not closeResult.isOk:
          return err[AstNode](closeResult.error)

        return ok(resultNode)

  let closeResult = stream.expect(tkRightBrace)
  if not closeResult.isOk:
    return err[AstNode](closeResult.error)

  # If only one child, return it directly; otherwise wrap in row
  if children.len == 1:
    return ok(children[0])
  else:
    return ok(newRow(children))

proc parseExpression(stream: var TokenStream): Result[AstNode] =
  ## Parse a full expression
  var children: seq[AstNode] = @[]

  while not stream.isAtEnd() and
        not stream.match(tkRightBrace) and
        not stream.match(tkRightParen) and
        not stream.match(tkRightBracket) and
        not stream.match(tkLineBreak) and
        not stream.match(tkAmpersand):

    # Stop if we encounter \right (for delimiter parsing) or \end (for environments)
    if stream.match(tkCommand) and (stream.peek().value == "right" or stream.peek().value == "end"):
      break

    let primResult = parsePrimary(stream)
    if not primResult.isOk:
      return err[AstNode](primResult.error)

    # Check for scripts
    var node = primResult.value
    while stream.match(tkSubscript) or stream.match(tkSuperscript):
      if stream.match(tkSubscript):
        discard stream.advance()
        let subResult = if stream.match(tkLeftBrace): parseGroup(stream)
                        else: parsePrimary(stream)
        if not subResult.isOk:
          return err[AstNode](subResult.error)

        # Check if followed by superscript
        if stream.match(tkSuperscript):
          discard stream.advance()
          let supResult = if stream.match(tkLeftBrace): parseGroup(stream)
                          else: parsePrimary(stream)
          if not supResult.isOk:
            return err[AstNode](supResult.error)
          node = newSubSup(node, subResult.value, supResult.value)
        else:
          node = newSub(node, subResult.value)

      elif stream.match(tkSuperscript):
        discard stream.advance()
        let supResult = if stream.match(tkLeftBrace): parseGroup(stream)
                        else: parsePrimary(stream)
        if not supResult.isOk:
          return err[AstNode](supResult.error)
        node = newSup(node, supResult.value)

    # Check for factorial operator
    if stream.match(tkOperator) and stream.peek().value == "!":
      discard stream.advance()
      node = newRow(@[node, newOperator("factorial", "!", "postfix")])

    children.add(node)

    # Check for infix fraction commands (\over, \choose, \atop)
    if stream.match(tkCommand):
      let cmdName = stream.peek().value
      if cmdName in commandTable and commandTable[cmdName].cmdType == ctInfixFrac:
        discard stream.advance()  # consume the command

        # Take all children so far as the numerator/left operand
        let leftNode = if children.len == 1: children[0] else: newRow(children)

        # Parse the rest as the denominator/right operand
        let rightResult = parseExpression(stream)
        if not rightResult.isOk:
          return err[AstNode](rightResult.error)

        # Create the appropriate node based on the command
        case cmdName
        of "over":
          return ok(newFrac(leftNode, rightResult.value))
        of "choose":
          # Binomial coefficient: wrapped in parentheses, no fraction line
          return ok(newBinomial(leftNode, rightResult.value))
        of "atop":
          # Stacked without line: like frac but no line
          return ok(newAtop(leftNode, rightResult.value))
        else:
          discard  # shouldn't happen

  # If only one child, return it directly; otherwise wrap in row
  if children.len == 0:
    return err[AstNode](ekUnexpectedEof, "Empty expression", 0)
  elif children.len == 1:
    return ok(children[0])
  else:
    return ok(newRow(children))

proc parse*(tokens: seq[Token]): Result[AstNode] =
  ## Parse a sequence of tokens into an AST
  var stream = newTokenStream(tokens)
  return parseExpression(stream)

proc parse*(source: string): Result[AstNode] =
  ## Lex and parse a LaTeX string
  let lexResult = lex(source)
  if not lexResult.isOk:
    return err[AstNode](lexResult.error)

  return parse(lexResult.value)
