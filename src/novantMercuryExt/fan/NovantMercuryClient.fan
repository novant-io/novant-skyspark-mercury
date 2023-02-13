//
// Copyright (c) 2021, Novant LLC
// Licensed under the MIT License
//
// History:
//   12 Nov 2021  Andy Frank  Creation
//   13 Feb 2023   Andy Frank   novantExt -> novantMercuryExt
//

using util
using web

**
** NovantClient
**
class NovantMercuryClient
{
  ** Constructor.
  new make(Str apiKey) { this.apiKey = apiKey }

  ** Invoke a 'ping' request for 'deviceId' throw 'IOErr' if ping failed.
  Void ping(Str deviceId)
  {
    invoke("ping", ["device_id": deviceId])
  }

  ** Request point details for 'device_id', or throw 'IOErr' if failed.
  Str:Obj? points(Str deviceId)
  {
    invoke("points", ["device_id": deviceId])
  }

  **
  ** Request current values for given 'deviceId' and optional 'pointIds'
  ** filter, or if null then return all point values for device.
  **
  ** If 'lastTs' is non-null, pass in as 'last_ts' argument, and return
  ** an empty map if values have not been modified since 'last_ts'.
  **
  ** Throws 'IOErr' if request failed.
  **
  Str:Obj? vals(Str deviceId, Str? pointIds := null, DateTime? lastTs := null)
  {
    args := ["device_id": deviceId]
    if (lastTs   != null) args["last_ts"]   = lastTs.toIso
    if (pointIds != null) args["point_ids"] = pointIds
    return invoke("values", args)
  }

  **
  ** Write a value to given 'pointId'.  If 'val' is null then clear
  ** the existing priority at 'priority' if applicable.  Throws 'IOErr'
  ** if request failed.
  **
  Void write(Str deviceId, Str pointId, Float? val, Int priority)
  {
    invoke("write", [
      "device_id": deviceId,
      "point_id":  pointId,
      "value":     val?.toStr ?: "null",
      "priority":  priority.toStr,
    ])
  }

  ** Get trend data for given list of points, or throws 'IOErr' if failed.
  Str:Obj? trends(Str deviceId, Str pointIds, Date date, Str? interval := null)
  {
    args := [
      "device_id": deviceId,
      "point_ids": pointIds,
      "date":      date.toStr,
    ]
    if (interval != null) args["interval"] = interval

    // TODO FIXIT: we need a streaming JsonReader here
    return invoke("trends", args)
  }

  ** Request trend date for given date. Throws 'IOErr' if request fails.
  Void trendsEach(Str deviceId, Str pointId, Date date, Str? interval, TimeZone tz, |DateTime,Obj?| f)
  {
    trends := this.trends(deviceId, pointId, date, interval)
    List data := trends["data"]
    data.each |Map tr|
    {
      ts  := DateTime.fromIso(tr["ts"]).toTimeZone(tz)
      val := tr[pointId]
      f(ts, val)
    }
  }

  ** Invoke API request or throw IOErr if error.
  private Str:Obj? invoke(Str op, Str:Str args)
  {
    c := WebClient(`https://api.novant.io/v1/${op}`)
    c.reqHeaders["Authorization"] = "Basic " + "${apiKey}:".toBuf.toBase64
    c.reqHeaders["Accept-Encoding"] = "gzip"
    c.postForm(args)

    // this is returned for /values if last_ts is not yet updated
    if (c.resCode == 304) return empty

    // check for error
    Str:Obj? json := JsonInStream(c.resStr.in).readJson
    if (c.resCode != 200)
    {
      msg := json["err_msg"] ?: "Unexpected error"
      throw IOErr(msg)
    }

    return json
  }

  private static const Str:Obj? empty := [:]

  private const Str apiKey
}