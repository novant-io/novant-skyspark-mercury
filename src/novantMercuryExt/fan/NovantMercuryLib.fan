//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019   Andy Frank   Creation
//   13 Feb 2023   Andy Frank   novantExt -> novantMercuryExt
//

using axon
using connExt
using folio
using haystack
using skyarcd

**
** Axon functions for novantMercury
**
const class NovantMercuryLib
{
  **
  ** Perform a synchronous learn read on the given connector.
  ** Following columns are returned:
  **   - 'dis': display name of point
  **   - 'point': point marker
  **   - 'kind': point kind
  **   - 'novantMercuryCur': address to read live data for point
  **   - 'novantMercuryWrite': address to write values back for point
  **   - 'novantMercuryHis': address to sync trend data for point
  **
  @Axon { admin = true }
  static Grid novantMercuryLearn(Obj conn, Obj? arg := null)
  {
    NovantMercuryExt.cur.connActor(conn).learn(arg)
  }

  **
  ** Asynchronously sync given points with the current values.
  ** The proxies may be any value suppored by `toRecList`.
  **
  @Axon { admin = true }
  static Obj? novantMercurySyncCur(Obj points)
  {
    NovantMercuryExt.cur.syncCur(points)
  }

  **
  ** Import the latest historical data from one or more external
  ** points. The proxies may be any value suppored by `toRecList`.
  **
  ** Each proxy record must contain:
  **  - `novantMercuryConnRef`: references the haystack connector
  **  - `novantMerucryHis`: Str identifier of the Novant point id
  **  - `his`: all the standard historized point tags
  **
  ** If the range is unspecified, then an attempt is made to
  ** synchronize any data after 'hisEnd' (last timestamp read).
  **
  ** This method is designed to be run in the context of a
  ** job via the `ext-job::doc`.
  **
  @Axon { admin = true }
  static Obj? novantMercurySyncHis(Obj proxies, Obj? range := null)
  {
    NovantMercuryExt.cur.syncHis(proxies, range)
  }

//////////////////////////////////////////////////////////////////////////
// Fix Tags
//////////////////////////////////////////////////////////////////////////

  **
  ** Fixup tag names for previous installations by renaming all
  ** 'novantXXX' tags -> 'novantMercuryXXX'. THe argument to this
  ** method is one or more conectors, and this method will manage
  ** recursively updating all associated points.
  **
  @NoDoc @Axon { admin = true }
  static Void novantMercuryFixTags(Obj conns)
  {
    cx := Context.cur
    Etc.toRecs(conns).each |conn|
    {
      fixTags(conn, cx)
      points := cx.proj.readAll("point and novantConnRef == $conn.id.toCode")
      points.each |p| { fixTags(p, cx) }
    }
  }

  private static Void fixTags(Dict rec, Context cx)
  {
    mod := Str:Obj?[:]
    rec.each |v,n|
    {
      if (n.startsWith("novant") && !n.startsWith("novantMercury"))
      {
        suffix := n["novant".size..-1]
        mod[n] = Remove.val
        if (v != null) mod["novantMercury${suffix}"] = v
      }
    }
    if (mod.size > 0) cx.proj.commit(Diff(rec, mod))
  }

//////////////////////////////////////////////////////////////////////////
// Unfix tags
//////////////////////////////////////////////////////////////////////////

  @NoDoc @Axon { admin = true }
  static Void novantMercuryUnfixTags(Obj conns)
  {
    cx := Context.cur
    Etc.toRecs(conns).each |conn|
    {
      unfixTags(conn, cx)
      points := cx.proj.readAll("point and novantMercuryConnRef == $conn.id.toCode")
      points.each |p| { unfixTags(p, cx) }
    }
  }

  private static Void unfixTags(Dict rec, Context cx)
  {
    mod := Str:Obj?[:]
    rec.each |v,n|
    {
      if (n.startsWith("novantMercury"))
      {
        suffix := n["novantMercury".size..-1]
        mod[n] = Remove.val
        mod["novant${suffix}"] = v
      }
    }
    if (mod.size > 0) cx.proj.commit(Diff(rec, mod))
  }
}

