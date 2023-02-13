//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019   Andy Frank   Creation
//   13 Feb 2023   Andy Frank   novantExt -> novantMercuryExt
//

using haystack
using skyarcd
using connExt

**
** Novant Extension
**
@ExtMeta
{
  name    = "novantMercury"
  icon    = "novant"
  depends = ["conn"]
}
const class NovantMercuryExt : ConnImplExt
{
  static NovantMercuryExt? cur(Bool checked := true)
  {
    Context.cur.ext("novantMercury", checked)
  }

  @NoDoc new make() : super(NovantMercuryModel())
  {
  }
}
