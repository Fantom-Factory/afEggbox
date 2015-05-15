
**************************************************************************
** DocLoc
**************************************************************************

**
** DocLoc models a filename / linenumber
**
const class DocLoc
{
  const static DocLoc unknown := DocLoc("Unknown", 0)

  ** Construct with file and line number (zero if unknown)
  new make(Str file, Int line)
  {
    this.file = file
    this.line = line
  }

  ** Filename location
  const Str file

  ** Line number or zero if unknown
  const Int line

  ** Return string representation
  override Str toStr()
  {
    if (line <= 0) return file
    return "$file [Line $line]"
  }
}

**************************************************************************
** DocFandoc
**************************************************************************

**
** Wrapper for Fandoc string for a chapter, type, or slot
**
const class DocFandoc
{
  ** Construct from `loc` and `text`
  new make(DocLoc loc, Str text)
  {
    this.loc = loc
    this.text = text
  }

  ** Return the first sentence of fandoc
  DocFandoc firstSentence()
  {
    DocFandoc(loc, firstSentenceStrBuf.toStr)
  }

  ** Return the first sentence of fandoc as a StrBuf
  @NoDoc StrBuf firstSentenceStrBuf()
  {
    buf := StrBuf()
    for (i:=0; i<text.size; i++)
    {
      ch := text[i]
      peek := i<text.size-1 ? text[i+1] : -1
      if (ch == '.' && (peek == ' ' || peek == '\n'))
      {
        buf.addChar(ch)
        break;
      }
      else if (ch == '\n')
      {
        if (peek == -1 || peek == ' ' || peek == '\n') break
        else buf.addChar(' ')
      }
      else buf.addChar(ch)
    }
    if (buf.size > 1 && buf[-1] == ':') buf.remove(-1)
    return buf
  }

  ** Location of fandoc in source file
  const DocLoc loc

  ** Plain text fandoc string
  const Str text
}

