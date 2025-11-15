import ../src/yatexml

when defined(js):
  proc latexToMathML*(latex: cstring, displayStyle: bool): cstring {.exportc.} =
    ## Convert LaTeX to MathML with configurable display style
    ##
    ## Parameters:
    ##   latex: LaTeX math expression
    ##   displayStyle: true for block/display math ($$...$$, \[...\])
    ##                 false for inline math ($...$, \(...\))
    let options = MathMLOptions(displayStyle: displayStyle, prettyPrint: false, indentSize: 2)
    let res = latexToMathML($latex, options)
    if res.isOk():
      result = cstring(res.value)
    else:
      result = cstring"ERROR"

else:
  proc latexToMathML*(latex: string, displayStyle: bool): string  =
    ## Convert LaTeX to MathML with configurable display style
    ##
    ## Parameters:
    ##   latex: LaTeX math expression
    ##   displayStyle: true for block/display math ($$...$$, \[...\])
    ##                 false for inline math ($...$, \(...\))
    let options = MathMLOptions(displayStyle: displayStyle, prettyPrint: false, indentSize: 2)
    let res = latexToMathML($latex, options)
    if res.isOk():
      result = res.value
    else:
      result = "ERROR"

  proc main(tex: string, asBlock: bool = false) =
    ## Converts the given input latex to MathML and prints the generated MathML code.
    echo latexToMathML(tex, asBlock)

  when isMainModule:
    import cligen
    dispatch main, noAutoEcho=true
