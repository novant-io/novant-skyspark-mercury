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
}

