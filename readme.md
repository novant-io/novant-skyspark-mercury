# Novant Connector for SkySpark

The novantMercuryExt implements [SkySpark](https://skyfoundry.com) connector
support for the [Novant](https://novant.io) Smart Building PaaS.

## Installing

[rel]: https://github.com/novant-io/novant-skyspark-mercury/releases

The simplest way to install the `novantMercuryExt` is using the Install Manager
tool in SkySpark. You may also manually download the pod from [Releases][rel]
and copy into the `lib/fan/` folder. A restart is required for the extension to
take effect.

## API Keys

Access to Novant devices are built around API keys. It's recommended you
create a specific API key just for SkySpark access.

## Connectors

Each connector in SkySpark maps 1:1 to a Novant device.  To create and map a
new connector:

    novantMercuryConn
    dis: "My Device"
    apiKey: "***********"
    novantMercuryDeviceId: dv_xxxxxxxxxxxxx
    novantMercuryHisInterval: "15min"

Where `apiKey` is the key you generated from the Novant platform, and
'novantMercuryDeviceId' is the Novant device id for the device to connect.

## Cur/Write/His

Current values are configured using the `novantMercuryCur` tag on a point.
Writable points use the `novantMercuryWrite` tag.  Likewise histories use the
`novantMercuryHis` tag. The value of these tags maps to the point ID for the
Novant device, which will be in the format of `"p{id}"`.

    point
    dis: "My Point"
    novantMercuryCur: "p15"
    novantMercuryWrite: "p15"
    novantMercuryHis: "p15"
    equipRef: @equip-id
    siteRef: @site-id
    kind: "Number"
    unit: "kW"

The SkySpark write level will be carried over directly into the downstream
I/O device under the Novant gateway.  For protocols that support priority, like
Bacnet, this means the Bacnet priority array level matches the SkySpark write
level. For protocols that do not support priority (such as Modbus) this value
is ignored.

## Learn

The Novant connector supports learning.  Once a connector has been added, you
can use the Site Builder to walk the device tree and add any or all points.
