//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019   Andy Frank   Creation
//   13 Feb 2023   Andy Frank   novantExt -> novantMercuryExt
//

using haystack
using connExt

**
** NovantModel
**
@Js
const class NovantMercuryModel : ConnModel
{
  new make() : super(NovantMercuryModel#.pod)
  {
    connProto = Etc.makeDict([
      "dis":                      "Novant Mercury Conn",
      "novantMercuryConn":        Marker.val,
      "novantMercuryDeviceId":    "dv_",
      "apiKey":                   "ak_",
      "novantMercuryHisInterval": "15min",
    ])
  }

  override const Dict connProto
  override Type? pointAddrType()     { Str#  }
  override PollingMode pollingMode() { PollingMode.buckets }
  override Bool isLearnSupported()   { true  }
  override Bool isCurSupported()     { true  }
  override Bool isWriteSupported()   { true  }
  override Bool isHisSupported()     { true  }
}

