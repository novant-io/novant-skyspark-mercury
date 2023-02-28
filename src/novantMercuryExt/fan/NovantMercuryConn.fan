//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019   Andy Frank   Creation
//   13 Feb 2023   Andy Frank   novantExt -> novantMercuryExt
//

using connExt
using folio
using haystack
using util
using web

**
** NovantConn
**
class NovantMercuryConn : Conn
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(ConnActor actor, Dict rec) : super(actor, rec) {}

  override Obj? receive(ConnMsg msg)
  {
    NovantMercuryExt ext := ext
    switch (msg.id)
    {
      default: return super.receive(msg)
    }
  }

  override Void onOpen() {}

  override Void onClose() {}

  override Dict onPing()
  {
    client.ping(deviceId)
    return Etc.emptyDict
  }

//////////////////////////////////////////////////////////////////////////
// Cur
//////////////////////////////////////////////////////////////////////////

  override Void onSyncCur(ConnPoint[] points)
  {
    try
    {
      // short-circuit if no points
      if (points.size == 0) return

      // short-circuit if polling under 1min
      now := DateTime.nowTicks
      if (now - lastValuesTicks < 1min.ticks) return
      this.lastValuesTicks = now

      // TODO: can this be cached somewhere?
      // get comma-sep point id list
      pointIds := StrBuf()
      points.each |p|
      {
        id := p.rec["novantMercuryCur"]
        if (id != null) pointIds.join(id, ",")
      }

      // request values
      Str:Obj? res := client.vals(deviceId, pointIds.toStr, lastValuesTs)
      this.lastValuesTs = DateTime.fromIso(res["ts"])

      // TODO: can this be cached somewhere?
      map := Str:ConnPoint[:]
      points.each |p| { map.set(p.rec["novantMercuryCur"], p) }

      // update curVals
      Obj[] data := res["data"]
      data.each |Map r|
      {
        ConnPoint? pt
        try
        {
          id  := r["id"]
          val := r["val"]

          // point not found
          pt = map[id]
          if (pt == null) return

          // sanity check to disallow his collection
          if (pt.rec.has("hisCollectCov") || pt.rec.has("hisCollectInterval"))
            throw ArgErr("hisCollect not allowed")

          // convert and update
          pval := NovantUtil.toConnPointVal(pt, val)
          pt.updateCurOk(pval)
        }
        catch (Err err) { pt?.updateCurErr(err) }
      }
    }
    catch (Err err) { close(err) }
  }

//////////////////////////////////////////////////////////////////////////
// Write
//////////////////////////////////////////////////////////////////////////

  override Void onWrite(ConnPoint point, Obj? val, Number level)
  {
    try
    {
      // convert to float
      Float? fval
      if (val is Number) fval = ((Number)val).toFloat
      if (val is Bool)   fval = val==true ? 1f : 0f

      // cap priority to max 16
      pri := level.toInt
      if (pri > 16) pri = 16

      // issue write
      pid := point.rec["novantMercuryWrite"]
      client.write(deviceId, pid, fval, pri)

      // update ok
      point.updateWriteOk(val, level)
    }
    catch (Err err) { point.updateWriteErr(val, level, err) }
  }

//////////////////////////////////////////////////////////////////////////
// His
//////////////////////////////////////////////////////////////////////////

  override Obj? onSyncHis(ConnPoint p, Span origSpan)
  {
    // sanity check
    if (p.rec["novantMercuryHis"] == null) throw Err("Missing novantMercuryHis tag")

    // update status to pending
    proj.commit(Diff(p.rec, pending, Diff.forceTransient))

    // floor span to nearest minute to align queue keys
    span := Span(floorTsMin(origSpan.start), floorTsMin(origSpan.end))

    // queue for next sync
    acc := hisSyncQueue[span] ?: ConnPoint[,]
    if (acc.find |x| { x.id == p.id } == null) acc.add(p)
    hisSyncQueue[span] = acc
    return null
  }

  override Void onHouseKeeping()
  {
    try
    {
      // short-circuit if nothing to sync
      if (hisSyncQueue.isEmpty) return

      // iterate queue
      hisSyncQueue.each |points, span| { doSyncHis(span, points) }
    }
    catch (Err err) { close(err) }
    finally
    {
      // for now to be safe always flush queue
      hisSyncQueue.clear
    }
  }

  private Void doSyncHis(Span span, ConnPoint[] points)
  {
    try
    {
      pmap  := Str:ConnPoint[:]   // map of point_id:ConnPoint
      refs  := Ref[,]             // list of backing rec ids
      intv  := hisInterval        // trend interval for sync
      hmap  := Str:HisItem[][:]   // map of point_id:HisItem[]
      tz    := TimeZone(points.first.rec["tz"])  // points should have same tz
      start := Duration.now

      // update hisStatus to 'syncing'
      points.each |p|
      {
        nid := p.rec["novantMercuryHis"]
        pmap[nid] = p
        refs.add(p.rec.id)
        proj.commit(Diff(p.rec, syncing, Diff.forceTransient))
      }

      // refresh backing rec for each point (the conn.point.rec instance
      // gets cached on conn.open; so we need to update to latest copy
      // so we can inspect hisStar/hisEnd
      recs := proj.readByIdsList(refs)
      rmap := Ref:Dict[:].setList(recs) |r| { r.id }
      pids := pmap.keys.join(",")

      // sync span trends by day
      span.eachDay |date|
      {
        log.info("syncHis [${date}] ...")
        client.trendsEach(deviceId, pids, date, intv, tz) |ts,pid,val|
        {
          // skip 'null' and 'na' vals
          pt   := pmap[pid]
          pval := NovantUtil.toConnPointVal(pt, val, false)
          if (pval == null) return

          // skip ts if < hisEnd; must use rmap; see above
          rec    := rmap[pt.rec.id]
          hisEnd := rec["hisEnd"] as DateTime
          if (hisEnd != null && ts <= hisEnd) return

          // append his item
          items := hmap[pid] ?: HisItem[,]
          items.add(HisItem(ts, pval))
          hmap[pid] = items
        }
      }

      // update his
      pmap.each |pt,pid|
      {
        items := hmap[pid] ?: HisItem#.emptyList
        pt.updateHisOk(items, span)
      }

      end := Duration.now
      dur := (end - start).toLocale
      log.info("syncHis OK: [${span}, ${points.size} points, ${dur}]")
    }
    catch (Err err)
    {
      // if req fails mark all points in fault
      points.each |p| { p.updateHisErr(err) }
      log.err("syncHis failed: [${span}]", err)
    }
  }

  private DateTime floorTsMin(DateTime orig)
  {
    t := Time(orig.hour, orig.min, 0)
    return orig.date.toDateTime(t, orig.tz)
  }

//////////////////////////////////////////////////////////////////////////
// Learn
//////////////////////////////////////////////////////////////////////////

  override Grid onLearn(Obj? arg)
  {
    gb := GridBuilder()
    gb.addColNames([
      "dis","learn","point","pointAddr","kind","novantMercuryCur","novantMercuryWrite","novantMercuryHis","unit"
    ])

    // cache points results for 1min
    now := Duration.nowTicks
    if (now-lastPointsTicks > 1min.ticks) this.pointsReq = client.points(deviceId)
    this.lastPointsTicks = now

    Obj[] sources := pointsReq["sources"]
    if (arg is Number)
    {
      Int i := ((Number)arg).toInt
      Map s := sources[i]
      Obj[] points := s["points"]
      points.each |Map p|
      {
        id   := p["id"]
        dis  := p["name"]
        addr := p["addr"]
        kind := p["kind"] == "bool" ? "Bool" : "Number"
        cur  := "${id}"
        wrt  := p["writable"] == true ? "${id}" : null
        his  := "${id}"
        unit := p["unit"]
        gb.addRow([dis, null, Marker.val, addr, kind, cur, wrt, his, unit])
      }
    }
    else
    {
      sources.each |Map s, Int i|
      {
        dis  := s["name"]
        learn := Number.makeInt(i)
        gb.addRow([dis, learn, null, null, null, null, null, null, null])
      }
    }

    return gb.toGrid
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Str:Obj? pointsReq := [:]
  private Int lastPointsTicks

  // lastTicks is our interal counter; lastTs is API argument
  private Int lastValuesTicks
  private DateTime lastValuesTs := DateTime.defVal

  internal Bool isDisabled() { rec["disabled"] != null }
  internal Str deviceId()    { rec->novantMercuryDeviceId }
  internal Str hisInterval() { rec["novantMercuryHisInterval"] ?: "15min" }
  internal Duration hisIntervalDur() { Duration.fromStr(hisInterval) }

  ** TimeZone for this device (assume all points are same tz).
  internal TimeZone? tz()
  {
    points.isEmpty ? null : points.first.tz
  }

  ** Get an authenicated NovantClient instance.
  internal NovantMercuryClient client()
  {
    // in 3.1.3 passwords now get stored using {id tagName}, so we
    // need to lookup with qualified key, otherwise fallback to
    // pre-3.1.3 of just {id}, or < 3.0.29 apiKey was stored as a
    // plain-text tag
    apiKey := ext.proj.passwords.get("${rec.id} apiKey")
    if (apiKey == null) apiKey = ext.proj.passwords.get("${rec.id}")
    if (apiKey == null) rec->apiKey
    if (apiKey == null) throw ArgErr("apiKey not found")

    return NovantMercuryClient(apiKey)
  }

  private static const Dict pending := Etc.makeDict(["hisStatus":"pending"])
  private static const Dict syncing := Etc.makeDict(["hisStatus":"syncing"])

  private Span:ConnPoint[] hisSyncQueue := [:]   // his sync queue
}