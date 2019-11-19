//
// Copyright (c) 2019, Novant LLC
// All Rights Reserved
//
// History:
//   18 Nov 19   Andy Frank   Creation
//

using haystack
using connExt

**
** NovantModel
**
@Js
const class NovantModel : ConnModel
{
  new make() : super(NovantModel#.pod)
  {
    connProto = Etc.makeDict([
      "dis":        "Novant Conn",
      "novantConn": Marker.val,
      "deviceId":   "dv_",
      "apiKey":     "ak_",
    ])
  }

  override const Dict connProto
  override Type? pointAddrType()     { Str#  }
  override Bool isPollingSupported() { false }
  override Bool isLearnSupported()   { true  }
  override Bool isCurSupported()     { false }
  override Bool isWriteSupported()   { false }
  override Bool isHisSupported()     { true  }
}

