
**
** DocType models the documentation of a `sys::Type`.
**
const class DocType
{

  ** Constructor
  internal new make(DocAttrs attrs, DocTypeRef ref, Str:DocSlot slotMap)
  {
    this.ref     = ref
    this.loc     = attrs.loc
    this.flags   = attrs.flags
    this.facets  = attrs.facets
    this.doc     = attrs.doc
    this.base    = attrs.base
    this.mixins  = attrs.mixins
    this.slotMap = slotMap
    this.isErr   = base.find {it.qname=="sys::Err"} != null
    this.isNoDoc = hasFacet("sys::NoDoc")

    // create sorted list
    list := slotMap.vals.sort|a, b| { a.name <=> b.name }

    // filter out slots which shouldn't be documented,
    // but leave them in the map for lookup
    list = list.exclude |s|
    {
      s.isNoDoc ||
      DocFlags.isInternal(s.flags) ||
      DocFlags.isPrivate(s.flags)  ||
      DocFlags.isSynthetic(s.flags)
    }
    this.slots = list
  }

  ** Representation of this type definition as a reference
  const DocTypeRef ref

  ** Simple name of the type such as "Str".
  Str name() { ref.name }

  ** Qualified name formatted as "pod::name".
  Str qname() { ref.qname }

  ** Title of the document is the qualified name
  Str title() { qname }

  ** Return true if annotated as NoDoc
  const Bool isNoDoc

  ** Source code location of this type definition
  const DocLoc loc

  ** Flags mask - see `DocFlags`
  const Int flags

  ** Facets defined on this type
  const DocFacet[] facets

  ** Return if given facet is defined on type
  Bool hasFacet(Str qname) { facets.any |f| { f.type.qname == qname } }

  ** Fandoc documentation string
  const DocFandoc doc

  ** Base class inheritance chain where direct subclass is first
  ** and 'sys::Obj' is last.  If this type is a mixin or this is
  ** 'sys::Obj' itself then this is an empty list.
  const DocTypeRef[] base

  ** Mixins directly implemented by this type
  const DocTypeRef[] mixins

  ** Is this a subclass of 'sys::Err'
  const Bool isErr

  ** List of the public, documented slots in this type. 
  const DocSlot[] slots

  ** Get slot by name.  If not found return null or raise UknownSlotErr
  DocSlot? slot(Str name, Bool checked := true)
  {
    slot := slotMap[name]
    if (slot != null) return slot
    if (checked) throw UnknownSlotErr("${qname}::${name}")
    return null
  }
  private const Str:DocSlot slotMap

  ** return qname
  override Str toStr() { qname }

  ** Is an enum type
  Bool isEnum() { DocFlags.isEnum(flags) }

  ** Is an mixin type
  Bool isMixin() { DocFlags.isMixin(flags) }

  ** Is an facet type
  Bool isFacet() { DocFlags.isFacet(flags) }
}