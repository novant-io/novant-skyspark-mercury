# Changelog

## Version 0.27 (working)

## Version 0.26 (8-Mar-2023)
* More fixes for `novantMercuryFixTags`

## Version 0.25 (28-Feb-2023)
* Fix `novantMercuryHisInterval` tag to work properly
* Rework `hisSync` to be async and batch up API requests

## Version 0.24 (13-Feb-2023)
* Rename `novantExt` -> `novantMercuryExt`
* Drop auto-his-sync behavoir; require jobs for his syncs

## Version 0.23 (unreleased)
* Bump `minSyncTime` to `05:00` to avoid DST issues

## Version 0.22 (25-Apr-2022)
* Improve trend sync behavoir

## Version 0.21 (24-Mar-2022)
* Add debug tracing for each point in `NovantSyncWorker`
* Update `NovantSyncWorker` to improve throughput
    - Throttle each `hisWrite` call with a small delay
    - Block until queue is flushed before next `hisWrite`
* Add new `novantSyncPoints` method to sync individual points

## Version 0.20 (10-Mar-2022)
* Update password lookup for `3.1.3` changes
* Update `novantLearn` to include `pointAddr` tag for downstream point addr

## Version 0.19 (27-Jan-2022)
* Fix timezone bugs when server timezone != device timezone
* Add support for `force` opt for trend syncs

## Version 0.18 (27-Dec-2021)
* Rework his sync to base off point `histStart` and `hisEnd`
* Improve his sync behavoir to optimzie point list for each sync date
* Remove obsolete `novantHisStart` and `novantHisEnd` tags

## Version 0.17 (8-Dec-2021)
* Fix syncs to skip `disabled` connectors
* New `novantHisInterval` tag to support `1min`, `5min`, `15min` his intervals
* New columns in `Conn|Novant` view: `disabled` and `hisInterval`

## Version 0.16 (19-Nov-2021)
* Update dependency to SkySpark `3.1`

## Version 0.15 (12-Nov-2021)
* New `NovantClient` API
   - Switch `NovantConn` over to use `NovantClient`
   - Fixup error handling for all API requests
* Update to fallback to `apiKey` as tag value for older SkySpark versions

## Version 0.14 (22-Sep-2021)
* Open source on GitHub
* Change license to MIT
* Update `NovantConn.onPing` to use new lightweight `/ping` API endpoint
* Fix `NovantConn` unit handling to allow `curConvert` to work properly

## Version 0.13 (18-Jul-2021)
* Update learn to use new Points API `kind` tag
* Update `syncCur` and `syncHis` to support `Bool` points

## Version 0.12 (18-Jun-2021)
* Update API calls to pass `point_ids` to optmize responses
* Fix `SyncActor` to handle non-historized points

## Version 0.11 (10-Mar-2021)
* Check response codes for all API requests

## Version 0.10 (10-Feb-2021)
* Add `write` support using new `/write` API

## Version 0.9 (26-Jan-2021)
* Add `curVal` support using new `/values` API

## Version 0.8 (29-Nov-2020)
* Fix `yesterday` syncs to wait till `2:00am` to ensure full data
* Add support for learning `unit` during conn learn

## Version 0.7 (22-Oct-2020)
* Update WebClient to use gzip compression
* Fix hisWrite clipping to using point tz

## Version 0.6 (18-Oct-2020)
* Improve handling of `na` data

## Version 0.5 (7-Jul-2020)
* Update learn to use source > point nesting
* Change `novantHis` tag to use `p` prefix

## Version 0.4 (17-Jun-2020)
* Add pod-doc
* Fix NPE with `dispatchSync` on background actor

## Version 0.3 (16-Jun-2020)
* Misc fixes to make sync more reliable
* Rework `novantSync` to skip already synced days be default
* Update `novantSync` to allow taking multiple conns
* Fix sync behavoir to never sync past `Date.yesterday`
* Add `{force}` option support to `novantSync`
* Add `novantHisClear` func
* Add simple ConnTool to sync/clear his using UI

## Version 0.2 (4-Jun-2020)
* Remove icon.png (not needed for StackHub)
* Fix `deviceId` -> `novantDeviceId` rename in NovantConn

## Version 0.1 (11-May-2020)
* Initial version with basic API learn and sync functionality