#!/usr/bin/env python3
"""Fetch the small offline NASA and partner data extracts the game shows (board M0-14).

Writes game/resources/data/nasa/<source_id>.json (one per source in docs/SCIENCE_AND_DATA.md §B1)
and puzzle_sources.json (P-01..P-16 and the SRC-* cards -> fixture ids). Standard library only.

  python3 production/tools/fetch_nasa_data.py              # fetch missing fixtures, rewrite the index
  python3 production/tools/fetch_nasa_data.py --refresh    # re-download every fixture
  python3 production/tools/fetch_nasa_data.py --only donki_2017_09,goes13_protons_2017_09
  python3 production/tools/fetch_nasa_data.py --check      # offline: validate fixtures and the index

Idempotent: an existing fixture is kept unless --refresh. Downloads are untrusted data: they are
parsed as text, JSON or CSV in memory, never executed and never saved; only the extracted fixture is
written. No source needs a key today (DONKI is read from the CCMC API, which is keyless). If a keyed
api.nasa.gov source is added, read NASA_API_KEY from the environment (a gitignored .env), never
from this file; sign up at https://api.nasa.gov/.

CERTIFICATE_VERIFY_FAILED on macOS means the OpenSSL bundle (/etc/ssl/cert.pem) lacks a newer root
(Sectigo R46: JPL, ESA, PDS Geosciences). Export the system roots and point Python at them; never
disable verification:
  security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > /tmp/roots.pem
  SSL_CERT_FILE=/tmp/roots.pem python3 production/tools/fetch_nasa_data.py
"""
import argparse
import csv
import datetime as dt
import html
import io
import json
import math
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game" / "resources" / "data" / "nasa"
MAX_BYTES = 200_000
MOON_R_KM = 1737.4  # IAU mean radius; also the Horizons reference sphere
UA = "Mozilla/5.0 (LastLightAcademy offline-fixture fetcher; NASA Space Apps 2026)"

US_GOV = "U.S. Government work (no U.S. copyright); free to use with credit"
JPL = "JPL Solar System Dynamics service output (NASA JPL/Caltech); free to use with credit"
QUOTED = "Facts and values quoted with citation; the article text remains (c) its publisher"
REQUIRED = ("source_id", "title", "agency", "dataset_id", "url", "retrieved", "licence", "citation",
            "fields_used", "values", "derived", "evidence_label", "boundary")


# ---------- network and text helpers ----------

def get(url, tries=3):
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=120) as r:
                return r.read().decode("utf-8", errors="replace")
        except Exception as exc:  # network errors: retry, then raise with the URL
            if attempt == tries - 1:
                raise RuntimeError(f"download failed: {url}: {exc}") from exc
            time.sleep(3)


def get_json(url):
    return json.loads(get(url))


def page_text(raw):
    raw = re.sub(r"(?is)<(script|style)[^>]*>.*?</\1>", " ", raw)
    return html.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", raw)))


def squash(s):
    return re.sub(r"\s+", "", s).lower()


def verify_quotes(checks):
    """checks: [(text_url, kind, [quotes])]; kind = html | ntrs | epmc | crossref. Returns records."""
    out = []
    for url, kind, quotes in checks:
        if kind == "ntrs":
            d = get_json(url)
            text = f"{d.get('title', '')} {d.get('abstract', '')}"
        elif kind == "epmc":
            res = get_json(url)["resultList"]["result"]
            text = (res[0].get("title", "") + " " + res[0].get("abstractText", "")) if res else ""
        elif kind == "crossref":
            m = get_json(url)["message"]
            text = (m.get("title") or [""])[0] + " " + m.get("abstract", "")
        else:
            text = page_text(get(url))
        text = squash(re.sub(r"<[^>]+>", "", text))
        for q in quotes:
            if squash(q) not in text:
                raise RuntimeError(f"quote not found at {url}: {q!r}")
        out.append({"checked_url": url, "quotes_found": quotes})
    return out


def ntrs(nid):
    return f"https://ntrs.nasa.gov/api/citations/{nid}"


def epmc(doi):
    return ("https://www.ebi.ac.uk/europepmc/webservices/rest/search?"
            + urllib.parse.urlencode({"query": f"DOI:{doi}", "resultType": "core", "format": "json"}))


def parse_time(s):
    return dt.datetime.strptime(s.replace("Z", "")[:16], "%Y-%m-%dT%H:%M")


def minutes(a, b):
    return round((parse_time(b) - parse_time(a)).total_seconds() / 60)


def derived(name, value, unit, formula, drives):
    return {"name": name, "value": value, "unit": unit, "formula": formula, "drives": drives}


def base(source_id, **kw):
    rec = {"source_id": source_id, "retrieved": dt.date.today().isoformat()}
    rec.update(kw)
    return rec


# ---------- API extracts ----------

DONKI = "https://ccmc.gsfc.nasa.gov/DONKI-API/get/{}?startDate={}&endDate={}"


def donki_records(kind, start, end):
    url = DONKI.format(kind, start, end)
    rows = get_json(url) or []
    keep = []
    for r in rows:
        if kind == "FLR":
            keep.append({k: r.get(k) for k in ("flrID", "classType", "beginTime", "peakTime", "endTime",
                                                 "sourceLocation", "activeRegionNum")})
        elif kind == "CME":
            best = [a for a in (r.get("cmeAnalyses") or []) if a.get("isMostAccurate")]
            keep.append({"activityID": r.get("activityID"), "startTime": r.get("startTime"),
                         "sourceLocation": r.get("sourceLocation"), "activeRegionNum": r.get("activeRegionNum"),
                         "speed_km_s": best[0].get("speed") if best else None,
                         "analysis_type": best[0].get("type") if best else None})
        else:  # SEP, IPS
            keep.append({"id": r.get("sepID") or r.get("activityID"), "eventTime": r.get("eventTime"),
                         "location": r.get("location"),
                         "instruments": [i.get("displayName") for i in r.get("instruments") or []]})
    return url, keep


def fx_donki_2017_09():
    urls, vals = [], {}
    for kind in ("FLR", "CME", "SEP"):
        u, vals[kind] = donki_records(kind, "2017-09-04", "2017-09-12")
        urls.append(u)
    x82 = next(f for f in vals["FLR"] if f["classType"] == "X8.2")
    x93 = next(f for f in vals["FLR"] if f["classType"] == "X9.3")
    sep10 = [s for s in vals["SEP"] if s["eventTime"].startswith("2017-09-10")]
    p100 = next(s for s in sep10 if any(">100 MeV" in i for i in s["instruments"]))
    p10 = next(s for s in sep10 if any(">10 MeV" in i for i in s["instruments"]))
    cme = next(c for c in vals["CME"] if c["startTime"].startswith("2017-09-10T16"))
    return base(
        "donki_2017_09", title="Solar flares, CMEs and particle events of 4-12 September 2017",
        agency="NASA GSFC Community Coordinated Modeling Center (DONKI)",
        dataset_id=f"DONKI {x82['flrID']}; {p100['id']}; {p10['id']}; {cme['activityID']}",
        url="https://ccmc.gsfc.nasa.gov/tools/DONKI/", request_urls=urls, licence=US_GOV,
        citation="NASA CCMC Space Weather Database Of Notifications, Knowledge, Information (DONKI), "
                 "records for 2017-09-04 to 2017-09-12.",
        fields_used=["FLR classType/beginTime/peakTime/activeRegionNum", "CME startTime/speed",
                     "SEP eventTime/instruments"],
        values=vals, evidence_label="Observed",
        derived=[
            derived("x82_flare_start", x82["beginTime"], "UTC", "DONKI FLR beginTime", "P-02 storm replay label"),
            derived("x82_flare_peak", x82["peakTime"], "UTC", "DONKI FLR peakTime", "P-02 storm replay label"),
            derived("x93_flare_peak", x93["peakTime"], "UTC", "DONKI FLR peakTime", "P-02 Rafi's shift-2 forecast"),
            derived("sep_gt100MeV_onset", p100["eventTime"], "UTC", "DONKI SEP, GOES13 >100 MeV", "P-02 shift-5 alarm"),
            derived("sep_gt10MeV_onset", p10["eventTime"], "UTC", "DONKI SEP, GOES13 >10 MeV", "P-02 storm onset"),
            derived("warning_lead_time", minutes(x82["beginTime"], p10["eventTime"]), "min",
                    ">10 MeV onset - X8.2 flare start", "P-02 alarm warning text"),
            derived("first_particles_after_peak", minutes(x82["peakTime"], p100["eventTime"]), "min",
                    ">100 MeV onset - X8.2 flare peak", "P-02 alarm warning text"),
            derived("cme_speed", cme["speed_km_s"], "km/s", "DONKI CME most-accurate analysis", "debrief card"),
        ],
        boundary="Historical event metadata. The storm is replayed on the game's fictional 2046 night; "
                 "it did not happen at Aurora. Earth-orbit and Moon doses differ.",
        src_card="SRC-STORM2017")


def fx_donki_2012_07():
    urls, vals = [], {}
    for kind in ("CME", "SEP", "IPS"):
        u, vals[kind] = donki_records(kind, "2012-07-22", "2012-07-26")
        urls.append(u)
    cme = next(c for c in vals["CME"] if c["startTime"].startswith("2012-07-23"))
    sta = next(s for s in vals["SEP"] if any("STEREO A" in i for i in s["instruments"]))
    shock = next(s for s in vals["IPS"] if s["location"] == "STEREO A")
    return base(
        "donki_2012_07", title="The July 2012 CME that missed Earth (STEREO-A)",
        agency="NASA GSFC Community Coordinated Modeling Center (DONKI)",
        dataset_id=f"DONKI {cme['activityID']}; {sta['id']}; {shock['id']}",
        url="https://ccmc.gsfc.nasa.gov/tools/DONKI/", request_urls=urls, licence=US_GOV,
        citation="NASA CCMC DONKI, records for 2012-07-22 to 2012-07-26.",
        fields_used=["CME startTime/speed", "SEP eventTime/instruments", "IPS eventTime/location"],
        values=vals, evidence_label="Observed",
        derived=[
            derived("cme_speed", cme["speed_km_s"], "km/s", "DONKI CME most-accurate analysis", "P-13 briefing"),
            derived("stereo_a_particle_onset", sta["eventTime"], "UTC", "DONKI SEP at STEREO A", "P-13 step 1 start"),
            derived("stereo_a_shock_arrival", shock["eventTime"], "UTC", "DONKI IPS at STEREO A", "P-13 peak step"),
            derived("onset_to_shock", round(minutes(sta["eventTime"], shock["eventTime"]) / 60, 2), "h",
                    "IPS time - SEP onset", "P-13 storm length"),
        ],
        boundary="The CME hit STEREO-A, not Earth or the Moon. Chapter 7's Moon strike, three waves, "
                 "damage and 2047 date are a labelled counterfactual.",
        src_card="SRC-STORM2012")


def fx_goes13_protons_2017_09():
    url = ("https://www.ncei.noaa.gov/data/goes-space-environment-monitor/access/avg/2017/09/goes13/csv/"
           "g13_epead_cpflux_5m_20170901_20170930.csv")
    lines = get(url).splitlines()
    start = next(i for i, ln in enumerate(lines) if ln.startswith("data:")) + 1
    rows = list(csv.DictReader(lines[start:]))
    t0, t1 = dt.datetime(2017, 9, 10, 12), dt.datetime(2017, 9, 12, 12)
    series = []
    for r in rows:
        t = dt.datetime.strptime(r["time_tag"][:19], "%Y-%m-%d %H:%M:%S")
        if t0 <= t < t1:
            p10, p100 = float(r["ZPGT10W"]), float(r["ZPGT100W"])
            series.append((t, p10 if p10 >= 0 else None, p100 if p100 >= 0 else None))
    onset = next(t for t, p10, _ in series if t >= dt.datetime(2017, 9, 10, 15, 35) and p10 and p10 >= 10)
    pk10 = max((s for s in series if s[1]), key=lambda s: s[1])
    pk100 = max((s for s in series if s[2]), key=lambda s: s[2])

    def mean10(a, b):
        v = [p for t, p, _ in series if a <= t < b and p is not None]
        return round(sum(v) / len(v), 1)
    shift = dt.timedelta(hours=7.2)
    m1, m2 = mean10(onset, onset + shift), mean10(onset + shift, onset + 2 * shift)
    hourly = []
    for h in range(int((t1 - t0).total_seconds() // 3600)):
        a = t0 + dt.timedelta(hours=h)
        p10s = [p for t, p, _ in series if a <= t < a + dt.timedelta(hours=1) and p is not None]
        p100s = [p for t, _, p in series if a <= t < a + dt.timedelta(hours=1) and p is not None]
        hourly.append([a.strftime("%Y-%m-%dT%H:%MZ"),
                       round(sum(p10s) / len(p10s), 3) if p10s else None,
                       round(sum(p100s) / len(p100s), 4) if p100s else None])
    iso = lambda t: t.strftime("%Y-%m-%dT%H:%MZ")
    return base(
        "goes13_protons_2017_09", title="GOES-13 proton flux during the 10 September 2017 storm",
        agency="NOAA National Centers for Environmental Information (partner agency)",
        dataset_id="GOES-13 EPEAD corrected integral proton flux, 5-min (g13_epead_cpflux_5m_20170901_20170930)",
        url="https://www.ncei.noaa.gov/products/goes-1-15/space-weather-instruments", request_urls=[url],
        licence=US_GOV, citation="NOAA NCEI, GOES-13 SEM EPEAD corrected proton flux, September 2017.",
        fields_used=["time_tag", "ZPGT10W (>10 MeV, west-facing, p/(cm^2 s sr))", "ZPGT100W (>100 MeV)"],
        values={"hourly_columns": ["hour_start_utc", "gt10MeV_pfu", "gt100MeV_pfu"], "hourly": hourly},
        evidence_label="Observed",
        derived=[
            derived("gt10MeV_reaches_10pfu", iso(onset), "UTC", "first 5-min value >= 10 pfu after the X8.2 flare",
                    "P-02 storm onset"),
            derived("gt10MeV_peak", pk10[1], "pfu", f"max 5-min value, at {iso(pk10[0])}", "debrief chart"),
            derived("gt100MeV_peak", pk100[2], "pfu", f"max 5-min value, at {iso(pk100[0])}", "debrief chart"),
            derived("storm_shift1_mean_gt10MeV", m1, "pfu", "mean over [onset, onset+7.2 h)", "P-02 shift 5"),
            derived("storm_shift2_mean_gt10MeV", m2, "pfu", "mean over [onset+7.2 h, onset+14.4 h)", "P-02 shift 6"),
            derived("shift2_over_shift1", round(m2 / m1, 2), "ratio", "storm_shift2_mean / storm_shift1_mean",
                    "P-02 proposal B3-4 (not applied)"),
        ],
        boundary="Measured in geostationary Earth orbit, inside Earth's magnetosphere; not a dose at the Moon. "
                 "pfu = protons/(cm^2 s sr).",
        src_card="SRC-STORM2017")


def fx_stereo_a_het_2012_07():
    url = ("https://cdaweb.gsfc.nasa.gov/hapi/data?id=STA_L1_HET&parameters=Proton_Flux"
           "&time.min=2012-07-23T00:00:00Z&time.max=2012-07-26T00:00:00Z&format=csv")
    info = get_json("https://cdaweb.gsfc.nasa.gov/hapi/info?id=STA_L1_HET")
    centers = next(p for p in info["parameters"] if p["name"] == "Proton_Flux")["bins"][0]["centers"]
    rows = [(dt.datetime.strptime(r[0][:19], "%Y-%m-%dT%H:%M:%S"), [float(x) for x in r[1:]])
            for r in csv.reader(io.StringIO(get(url))) if r]
    chans = {"14MeV": 0, "50MeV": 9, "80MeV": 10}
    onset = dt.datetime(2012, 7, 23, 3, 59)  # DONKI 2012-07-23T03:59:00-SEP-001 (STEREO A)
    steps = {}
    for name, ch in chans.items():
        f = []
        for k in range(6):
            a = onset + dt.timedelta(hours=7.2 * k)
            f.append(sum(v[ch] for t, v in rows if a <= t < a + dt.timedelta(hours=7.2) and v[ch] >= 0) * 60)
        steps[name] = [round(x / max(f), 3) for x in f]
    rule = [2 if x >= 0.5 else 1 for x in steps["80MeV"]]
    hourly = []
    t0 = dt.datetime(2012, 7, 23)
    for h in range(72):
        a = t0 + dt.timedelta(hours=h)
        sel = [v for t, v in rows if a <= t < a + dt.timedelta(hours=1)]
        means = []
        for ch in chans.values():
            ok = [v[ch] for v in sel if v[ch] >= 0]  # negative = fill value
            means.append(round(sum(ok) / len(ok), 4) if ok else None)
        hourly.append([a.strftime("%Y-%m-%dT%H:%MZ")] + means)
    return base(
        "stereo_a_het_2012_07", title="STEREO-A proton flux in the July 2012 storm",
        agency="NASA GSFC Space Physics Data Facility (CDAWeb), STEREO IMPACT/HET",
        dataset_id="CDAWeb STA_L1_HET, parameter Proton_Flux", url="https://cdaweb.gsfc.nasa.gov/hapi",
        request_urls=[url], licence=US_GOV,
        citation="NASA SPDF CDAWeb, STEREO-A IMPACT High Energy Telescope Level 1 proton flux, 23-25 July 2012.",
        fields_used=[f"Proton_Flux bin {ch} ({centers[ch]} MeV), #/(cm2 sr s MeV)" for ch in chans.values()],
        values={"hourly_columns": ["hour_start_utc"] + [f"{n}_flux" for n in chans], "hourly": hourly},
        evidence_label="Observed",
        derived=[
            derived(f"step_fluence_{n}", v, "fraction of peak step",
                    "sum of 1-min flux x 60 s over six 7.2 h steps from the 03:59 UT onset, / largest step",
                    "P-13/P-14 step multipliers (comparison)") for n, v in steps.items()
        ] + [derived("data_rule_multipliers_80MeV", rule, "multiplier", "2 if step fluence >= 0.5 of peak else 1",
                     "P-13 proposal B3-11 (not applied; game uses [1,1,2,2,1,1])")],
        boundary="Measured by STEREO-A in solar orbit, not at the Moon. The game's three waves are a counterfactual.",
        src_card="SRC-STORM2012")


def fx_crater_dose_2012_07():
    url = "https://crater-products.sr.unh.edu/data/inst/dose/table_l30drate.php"
    text = page_text(get(url))
    rows = re.findall(r"(2012-07-\d{2}) (\d{7}) ((?:[\d.]+ ){6})", text)
    days = sorted(([d] + [float(x) for x in vals.split()] for d, _, vals in rows if "2012-07-15" <= d <= "2012-07-31"))
    d = {r[0]: r for r in days}
    return base(
        "crater_dose_2012_07", title="Dose measured at the Moon by LRO CRaTER, July 2012",
        agency="NASA LRO CRaTER team (University of New Hampshire); archived at NASA PDS PPI",
        dataset_id="CRaTER L30 daily dose rate, detectors D1-D6 (as measured)", url=url, request_urls=[url],
        licence=US_GOV + " (NASA mission data)",
        citation="LRO CRaTER Legacy Data Products, daily average dose rates (Schwadron et al.), July 2012.",
        fields_used=["Date", "D1..D6 dose rate, mGy(Si)/day, not shadow-corrected"],
        values={"columns": ["date", "D1", "D2", "D3", "D4", "D5", "D6"], "daily": days},
        evidence_label="Observed",
        derived=[derived("d1_before", d["2012-07-22"][1], "mGy(Si)/day", "D1 on 2012-07-22", "P-13 card"),
                 derived("d1_peak", d["2012-07-24"][1], "mGy(Si)/day", "D1 on 2012-07-24", "P-13 card"),
                 derived("d1_rise", round(d["2012-07-24"][1] / d["2012-07-22"][1], 1), "ratio",
                         "D1 24 Jul / D1 22 Jul", "P-13 card: what reached the Moon")],
        boundary="Dose in silicon detectors in lunar orbit, not tissue dose on the surface. The July 2012 CME "
                 "itself missed; these particles are what really reached the Moon.",
        src_card="SRC-STORM2012")


HORIZONS = "https://ssd.jpl.nasa.gov/api/horizons.api"


def horizons(target, lon, lat, start, stop, step):
    q = {"format": "json", "COMMAND": f"'{target}'", "OBJ_DATA": "'NO'", "MAKE_EPHEM": "'YES'",
         "EPHEM_TYPE": "'OBSERVER'", "CENTER": "'coord@301'", "COORD_TYPE": "'GEODETIC'",
         "SITE_COORD": f"'{lon},{lat},0'", "START_TIME": f"'{start}'", "STOP_TIME": f"'{stop}'",
         "STEP_SIZE": f"'{step}'", "QUANTITIES": "'4'", "ANG_FORMAT": "'DEG'", "CSV_FORMAT": "'YES'"}
    url = HORIZONS + "?" + urllib.parse.urlencode(q)
    res = get_json(url)["result"]
    body = res[res.index("$$SOE") + 5:res.index("$$EOE")].strip().splitlines()
    out = []
    for ln in body:
        c = [x.strip() for x in ln.split(",")]
        t = dt.datetime.strptime(c[0], "%Y-%b-%d %H:%M")
        out.append((t, round(float(c[3]), 4), round(float(c[4]), 4)))
    return url, out


def crossings(series):
    """Linear-interpolated times when elevation changes sign: [(utc, 'rise'|'set')]."""
    out = []
    for (t0, _, e0), (t1, _, e1) in zip(series, series[1:]):
        if (e0 < 0) != (e1 < 0):
            t = t0 + (t1 - t0) * (-e0 / (e1 - e0))
            out.append((t.strftime("%Y-%m-%dT%H:%MZ"), "rise" if e1 > e0 else "set"))
    return out


def iso(t):
    return t.strftime("%Y-%m-%dT%H:%MZ")


HZ_CITE = "JPL Horizons On-Line Ephemeris System (DE441), observer table, airless, no terrain."


def fx_jpl_horizons_pole_season():
    url, sun = horizons(10, 0, -90, "2046-01-01", "2047-12-31", "1 d")
    by_year = {y: [s for s in sun if s[0].year == y] for y in (2046, 2047)}
    d = []
    for y, s in by_year.items():
        lo, hi = min(s, key=lambda x: x[2]), max(s, key=lambda x: x[2])
        d.append(derived(f"midwinter_{y}", lo[0].date().isoformat(), "date", f"min Sun elevation ({lo[2]} deg)",
                         "E1 seasons; P-02/P-15 dates"))
        d.append(derived(f"midsummer_{y}", hi[0].date().isoformat(), "date", f"max Sun elevation ({hi[2]} deg)",
                         "E1 seasons"))
    on = {s[0].date().isoformat(): s[2] for s in sun}
    d += [derived("sun_elevation_2046_04_25", on["2046-04-25"], "deg", "Horizons at the pole", "P-02 CH1 night"),
          derived("sun_elevation_2047_01_12", on["2047-01-12"], "deg", "Horizons at the pole", "P-11 eclipse"),
          derived("sun_elevation_range", [min(on.values()), max(on.values())], "deg", "min, max 2046-2047",
                  "why the Sun stays low")]
    return base(
        "jpl_horizons_pole_season", title="The Sun's height at the lunar south pole, 2046-2047",
        agency="NASA Jet Propulsion Laboratory (Horizons)", dataset_id="Horizons target 10 (Sun), site coord@301 0E -90 h0",
        url="https://ssd.jpl.nasa.gov/horizons/", request_urls=[url], licence=JPL, citation=HZ_CITE,
        fields_used=["date (UT)", "apparent elevation, deg"],
        values={"columns": ["date", "sun_elevation_deg"], "daily": [[s[0].date().isoformat(), s[2]] for s in sun]},
        evidence_label="Computed", derived=d,
        boundary="Geometric elevation above an ideal horizon at the exact pole. Local terrain and Aurora's "
                 "real site decide actual sunlight (pending LOLA horizon mask).",
        src_card="SRC-POLAR")


def fx_jpl_horizons_ch1_sky():
    u1, earth = horizons(399, 0, -90, "2046-04-01", "2046-05-05", "6 h")
    u2, sun = horizons(10, 0, -90, "2046-04-01", "2046-05-05", "6 h")
    e = {iso(t): el for t, _, el in earth}
    night = [x for x in earth if dt.datetime(2046, 4, 25, 18) <= x[0] <= dt.datetime(2046, 4, 27, 6)]
    return base(
        "jpl_horizons_ch1_sky", title="Earth and Sun from the lunar south pole, April 2046 (Chapter 1)",
        agency="NASA Jet Propulsion Laboratory (Horizons)",
        dataset_id="Horizons targets 399 (Earth) and 10 (Sun), site coord@301 0E -90 h0, 6-hourly",
        url="https://ssd.jpl.nasa.gov/horizons/", request_urls=[u1, u2], licence=JPL, citation=HZ_CITE,
        fields_used=["UT", "Earth azimuth/elevation, deg", "Sun elevation, deg"],
        values={"columns": ["utc", "earth_azimuth_deg", "earth_elevation_deg", "sun_elevation_deg"],
                "six_hourly": [[iso(a[0]), a[1], a[2], b[2]] for a, b in zip(earth, sun)]},
        evidence_label="Computed",
        derived=[derived("earth_horizon_crossings", crossings(earth), "utc", "linear interpolation of elevation sign change",
                         "P-02 Earth-set beat (see SCIENCE_AND_DATA B3-5)"),
                 derived("earth_elevation_night_start", e["2046-04-25T18:00Z"], "deg", "25 Apr 2046 18:00 UT", "P-02"),
                 derived("earth_elevation_night_end", e["2046-04-27T06:00Z"], "deg", "27 Apr 2046 06:00 UT", "P-02"),
                 derived("earth_below_horizon_all_night", all(x[2] < 0 for x in night), "bool",
                         "every 6-hourly sample 25 Apr 18:00 - 27 Apr 06:00 < 0", "P-02 'Earth is down'")],
        boundary="Ideal horizon at the exact pole. An elevated rim site sees farther; Aurora's coordinate and the "
                 "LOLA horizon mask are still pending.",
        src_card="SRC-POLAR")


MALAPERT = (-1.67, -85.98)  # USGS/IAU Gazetteer feature 16338 (planetographic, +East)
SHACKLETON = (129.78, -89.67)  # feature 5450


def fx_jpl_horizons_ch8_relay():
    u1, mal = horizons(399, *MALAPERT, "2047-04-08 18:00", "2047-04-09 06:00", "15 m")
    u2, pole = horizons(399, 0, -90, "2047-04-07", "2047-04-11", "6 h")
    win = [x for x in mal if dt.datetime(2047, 4, 9, 0, 45) <= x[0] <= dt.datetime(2047, 4, 9, 1, 45)]
    low = min(x[2] for x in win)
    hmin = MOON_R_KM * (1 / math.cos(math.radians(-low)) - 1) if low < 0 else 0.0
    return base(
        "jpl_horizons_ch8_relay", title="Where Earth is from Mons Malapert and from the pole, 8-10 April 2047",
        agency="NASA Jet Propulsion Laboratory (Horizons)",
        dataset_id="Horizons target 399 (Earth), sites coord@301 -1.67E -85.98 (Mons Malapert) and 0E -90",
        url="https://ssd.jpl.nasa.gov/horizons/", request_urls=[u1, u2], licence=JPL, citation=HZ_CITE,
        fields_used=["UT", "Earth azimuth/elevation, deg"],
        values={"columns": ["utc", "earth_azimuth_deg", "earth_elevation_deg"],
                "malapert_15min": [[iso(t), a, e] for t, a, e in mal],
                "pole_6hourly": [[iso(t), a, e] for t, a, e in pole]},
        evidence_label="Computed",
        derived=[derived("e3_azimuth_range", [min(x[1] for x in win), max(x[1] for x in win)], "deg",
                         "Earth azimuth from Mons Malapert, 9 Apr 2047 00:45-01:45 UT", "P-16 Earth bearing E3"),
                 derived("e3_elevation_range", [low, max(x[2] for x in win)], "deg",
                         "Earth elevation from Mons Malapert, same window", "P-16 Earth bearing E3"),
                 derived("min_height_for_line_of_sight", round(hmin, 2), "km",
                         "R * (1/cos(lowest elevation) - 1), R = 1737.4 km, smooth sphere", "P-16 why the summit"),
                 derived("earth_elevation_at_pole", [min(x[2] for x in pole), max(x[2] for x in pole)], "deg",
                         "Earth from the pole, 7-11 Apr 2047", "P-16 why Aurora needs the relay")],
        boundary="Geometric, no terrain. Summit height and terrain to the north need the LOLA DEM before the "
                 "bearings are called verified; until then the dial is labelled Computed.",
        src_card="SRC-RELAY")


def gc(lon1, lat1, lon2, lat2):
    p1, p2, dl = math.radians(lat1), math.radians(lat2), math.radians(lon2 - lon1)
    c = math.sin(p1) * math.sin(p2) + math.cos(p1) * math.cos(p2) * math.cos(dl)
    brg = math.degrees(math.atan2(math.sin(dl) * math.cos(p2),
                                  math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl))) % 360
    return round(math.acos(max(-1.0, min(1.0, c))) * MOON_R_KM, 1), round(brg, 1)


def fx_usgs_gazetteer_south_pole():
    feats, urls = {}, []
    for fid in (16338, 5450, 1439):
        u = f"https://planetarynames.wr.usgs.gov/Feature/{fid}"
        t = page_text(get(u))
        name = re.search(r"Feature Name (.+?) Clean Name", t).group(1).strip()
        lat = float(re.search(r"Center Latitude (-?[\d.]+)", t).group(1))
        lon = float(re.search(r"Center Longitude (-?[\d.]+)", t).group(1))
        diam = float(re.search(r"Diameter ([\d.]+) km", t).group(1))
        feats[name] = {"feature_id": fid, "center_lat_deg": lat, "center_lon_deg_east": lon, "diameter_km": diam}
        urls.append(u)
    m, s = feats["Mons Malapert"], feats["Shackleton"]
    pole_m = gc(0, -90, m["center_lon_deg_east"], m["center_lat_deg"])
    s_m = gc(s["center_lon_deg_east"], s["center_lat_deg"], m["center_lon_deg_east"], m["center_lat_deg"])
    m_s = gc(m["center_lon_deg_east"], m["center_lat_deg"], s["center_lon_deg_east"], s["center_lat_deg"])
    return base(
        "usgs_gazetteer_south_pole", title="Named south-pole features: Mons Malapert, Shackleton, de Gerlache",
        agency="USGS Astrogeology / IAU Working Group for Planetary System Nomenclature (partner agency)",
        dataset_id="Gazetteer of Planetary Nomenclature features 16338, 5450, 1439", url=urls[0], request_urls=urls,
        licence=US_GOV, citation="Gazetteer of Planetary Nomenclature, IAU WGPSN / USGS Astrogeology.",
        fields_used=["Feature Name", "Center Latitude", "Center Longitude", "Diameter"], values=feats,
        evidence_label="Computed",
        derived=[derived("pole_to_mons_malapert", pole_m[0], "km", "great circle on a 1737.4 km sphere",
                         "P-15 120 km each way"),
                 derived("shackleton_to_mons_malapert", s_m[0], "km", "great circle, crater centre to massif centre",
                         "P-15 range check"),
                 derived("bearing_malapert_to_shackleton", m_s[1], "deg from north",
                         "initial great-circle bearing", "P-16 local bearing L2")],
        boundary="Feature centres, not Aurora's site or the summit; the road is fictional and longer than a "
                 "great circle.",
        src_card="SRC-RELAY")


def fx_nasa_eclipse_2047_01_12():
    url = "https://eclipse.gsfc.nasa.gov/LEcat5/LE2001-2100.html"
    line = next(ln for ln in page_text(get(url)).split("09755") if ln.strip().startswith("2047 Jan 12"))
    tok = line.split()
    # 2047 Jan 12 01:26:14 90 581 125 T -p 0.3317 2.2649 1.2341 337.2 208.9 70.0 22N 19W
    td, dT = tok[3], int(tok[4])
    pen, par, tot = float(tok[12]), float(tok[13]), float(tok[14])
    g = dt.datetime.strptime("2047-01-12 " + td, "%Y-%m-%d %H:%M:%S") - dt.timedelta(seconds=dT)
    c = lambda mins: (g + dt.timedelta(minutes=mins)).strftime("%Y-%m-%dT%H:%M:%SZ")
    return base(
        "nasa_eclipse_2047_01_12", title="Total lunar eclipse of 12 January 2047",
        agency="NASA Goddard Space Flight Center (F. Espenak, Five Millennium Catalog)",
        dataset_id="Lunar eclipse catalog 2001-2100, catalog number 09755, Saros 125", url=url, request_urls=[url],
        licence=US_GOV, citation="Espenak, F. & Meeus, J., Five Millennium Catalog of Lunar Eclipses, NASA GSFC.",
        fields_used=["TD of greatest eclipse", "Delta T", "Saros", "type", "penumbral/partial/total durations"],
        values={"td_greatest": td, "delta_t_s": dT, "saros": int(tok[6]), "type": tok[7],
                "penumbral_min": pen, "partial_min": par, "total_min": tot},
        evidence_label="Observed",
        derived=[derived("greatest_eclipse_ut", g.strftime("%Y-%m-%dT%H:%M:%SZ"), "UTC", "TD - Delta T", "P-11/P-12"),
                 derived("contacts_ut", {"P1": c(-pen / 2), "U1": c(-par / 2), "U2": c(-tot / 2),
                                         "U3": c(tot / 2), "U4": c(par / 2), "P4": c(pen / 2)}, "UTC",
                         "greatest +/- half of each phase duration", "P-11 five segments; P-12 ingress/ring/egress"),
                 derived("partial_ingress_min", round((par - tot) / 2, 2), "min", "(partial - total) / 2", "P-11 ingress"),
                 derived("point_full_shadow_bounds_min", [tot, par], "min",
                         "a point on the Moon is fully shadowed for between total and partial duration", "E20 check"),
                 derived("segment_hours_over_shift", {"ingress": round((par - tot) / 2 / 60 / 7.2, 3),
                                                      "totality": round(tot / 60 / 7.2, 3)}, "shifts",
                         "minutes / 60 / 7.2 (08_PUZZLE_DESIGNS P-11 verified-data rule)", "P-11 proposal B3-10")],
        boundary="Whole-Moon contact times. Aurora's local ingress and egress depend on its coordinate and horizon.",
        src_card="SRC-ECLIPSE-DATE")


def fx_osdr_brassica_rapa_iss():
    url = ("https://osdr.nasa.gov/osdr/data/search?" +
           urllib.parse.urlencode({"term": "Brassica rapa", "type": "cgene", "size": 20}))
    hits = {h["_source"]["Accession"]: h["_source"] for h in get_json(url)["hits"]["hits"]}
    out = {}
    for acc in ("OSD-59", "OSD-412"):
        s = hits[acc]
        text = f"{s.get('Study Description', '')} {s.get('Study Protocol Description', '')}"
        par = re.search(r"(\d+)\s*[-–]\s*(\d+)\s*[µμ]mol", text)
        days = re.search(r"after (\d+) days cultivation", text)
        out[acc] = {"title": s.get("Study Title"), "mission": s.get("Mission"), "platform": s.get("Experiment Platform"),
                    "space_program": s.get("Space Program"), "organism": s.get("organism"),
                    "par_umol_m2_s": [int(par.group(1)), int(par.group(2))] if par else None,
                    "cultivation_days": int(days.group(1)) if days else None,
                    "photoperiod_16_8": "16 h/8 h" in text, "temperature_23C": "temperature 23 C" in text}
    return base(
        "osdr_brassica_rapa_iss", title="Brassica rapa (mizuna) grown on the International Space Station",
        agency="NASA Open Science Data Repository (GeneLab); OSD-59 with the Russian Federal Space Agency",
        dataset_id="OSDR OSD-59 (GLDS-59, Lada, Expedition 22); OSD-412 (Veggie VEG-03D, SpaceX-12)",
        url="https://osdr.nasa.gov/bio/repo/data/studies/OSD-59", request_urls=[url], licence=US_GOV,
        citation="Sugimoto et al. (OSD-59) and Hummerick et al. (OSD-412), NASA OSDR.",
        fields_used=["Accession", "Study Title", "Mission", "Experiment Platform", "protocol PAR, days, photoperiod"],
        values=out, evidence_label="Observed",
        derived=[derived("full_lamp_par_reference", out["OSD-412"]["par_umol_m2_s"], "umol/m2/s",
                         "Veggie VEG-03D protocol PAR range", "P-02 light FULL; garden lamp card"),
                 derived("lada_cultivation_days", out["OSD-59"]["cultivation_days"], "days",
                         "OSD-59 description", "Alo care montage context")],
        boundary="Leafy Brassica rapa on the ISS in microgravity, not Alo's flowering cultivar on the Moon. "
                 "OSD-412 PAR, photoperiod and temperature describe its ground chambers simulating ISS conditions.",
        src_card="SRC-PLANTS")


def fx_apollo_shallow_moonquakes():
    url = ("https://pds-geosciences.wustl.edu/lunar/urn-nasa-pds-apollo_seismic_event_catalog/data/"
           "nakamura_1979_sm_locations.csv")
    rows = list(csv.DictReader(io.StringIO(get(url))))
    quakes = []
    for r in rows:
        day = dt.date(int(r["Year"]), 1, 1) + dt.timedelta(days=int(r["Day"]) - 1)
        quakes.append({"date": day.isoformat(), "utc": f"{int(r['H']):02d}:{int(r['M']):02d}:{int(r['S']):02d}",
                       "lat": float(r["Lat"]) if r["Lat"] else None, "lon": float(r["Long"]) if r["Long"] else None,
                       "magnitude": float(r["Magnitude"])})
    south = [q for q in quakes if q["lat"] is not None and q["lat"] <= -60]
    return base(
        "apollo_shallow_moonquakes", title="The 28 shallow moonquakes recorded by Apollo seismometers",
        agency="NASA Planetary Data System, Geosciences Node (Apollo Passive Seismic Experiment)",
        dataset_id="urn:nasa:pds:apollo_seismic_event_catalog, nakamura_1979_sm_locations", url=url,
        request_urls=[url], licence=US_GOV,
        citation="Nakamura, Y. et al. (1979) shallow moonquake locations; NASA PDS Apollo seismic event catalog.",
        fields_used=["Year", "Day", "H", "M", "S", "Lat", "Long", "Magnitude"], values={"quakes": quakes},
        evidence_label="Observed",
        derived=[derived("count", len(quakes), "events", "rows in the catalog", "CH3 quake card"),
                 derived("max_magnitude", max(q["magnitude"] for q in quakes), "catalog magnitude", "max",
                         "CH3 quake card"),
                 derived("south_polar_event", south, "event", "events at latitude <= -60",
                         "P-05 aftershock: the 13 Mar 1973 south-polar quake")],
        boundary="Recorded by Apollo stations near the equator; the location of the polar event is uncertain. "
                 "The story's quake, leak and dates are fiction.",
        src_card="SRC-QUAKES")


# ---------- published values (quoted and checked against the source text) ----------

def pub(source_id, title, agency, dataset_id, url, licence, citation, values, derived_list, label, boundary,
        checks, transcribed=None, src_card=None):
    rec = base(source_id, title=title, agency=agency, dataset_id=dataset_id, url=url, licence=licence,
               citation=citation, fields_used=sorted(values), values=values, derived=derived_list,
               evidence_label=label, boundary=boundary, verification=verify_quotes(checks))
    if transcribed:
        rec["transcribed_from"] = transcribed
    if src_card:
        rec["src_card"] = src_card
    return rec


def fx_bvad_2022_metabolic():
    o2 = 0.895
    unit = round(4 * o2 * 7.2 / 24, 3)
    return pub(
        "bvad_2022_metabolic", "Crew oxygen, food and water per day (NASA BVAD Rev 2)", "NASA Johnson Space Center",
        "NASA/TP-2015-218570/REV2; NTRS 20210024855", "https://ntrs.nasa.gov/citations/20210024855", US_GOV,
        "Ewert, M.K., Chen, T.T. & Powell, C.D. (2022) Life Support Baseline Values and Assumptions Document, "
        "NASA/TP-2015-218570/REV2.",
        {"o2_kg_per_crew_day": o2, "co2_kg_per_crew_day": 1.085, "food_solids_kg_per_crew_day": 0.800,
         "food_energy_MJ_per_crew_day": 12.778, "potable_water_kg_per_crew_day": 3.217,
         "cabin_pressure_iss_kPa": 101.3, "cabin_pressure_exploration_kPa": 57},
        [derived("air_unit_kg_o2", unit, "kg O2", "4 crew x 0.895 kg/d x 7.2 h / 24 h", "P-02 A-1 per shift"),
         derived("air_per_shift_by_crew", {"2": 0.5, "4": 1.0, "5": 1.25}, "air units", "crew / 4",
                 "P-02, P-07, P-10, P-13, P-15"),
         derived("food_per_shift_by_crew", {"4": 1.2, "5": 1.5}, "crew-days", "crew x 7.2 / 24",
                 "P-02 R-1.2; P-13 R1.5"),
         derived("gauge_100_percent", 101.3, "kPa", "nominal ISS cabin pressure", "P-05 proposal B3-7")],
        "Published value",
        "Planning values for an 82 kg reference crew member; game air and food units are teaching abstractions.",
        [(ntrs(20210024855), "ntrs", ["Life Support Baseline Values and Assumptions Document"])],
        transcribed="Table 3-31 (printed p. 58, PDF p. 72) for metabolic values; cabin pressure PDF pp. 62, 75, 155; "
                    "read with pdftotext on 2026-11-03 from https://ntrs.nasa.gov/api/citations/20210024855/downloads/BVAD_2.15.22-final.pdf",
        src_card="SRC-LIFE-SUPPORT")


def fx_vsat_relocatable_array():
    return pub(
        "vsat_relocatable_array", "Relocatable 10 kW solar array for lunar south pole missions",
        "NASA Langley Research Center (Vertical Solar Array Technology)",
        "NASA/TM-20210011743; NTRS 20210011743; VSAT overview NTRS 20220013210",
        "https://ntrs.nasa.gov/citations/20210011743", US_GOV,
        "Pappa, R. et al. (2021) Relocatable 10 kW Solar Array for Lunar South Pole Missions, NASA/TM-20210011743.",
        {"array_power_kW": 10, "blanket_height_m": 10, "mast_length_m": 16},
        [derived("game_mean_power", round(8 * 10 / 7.2, 1), "kW", "8 sun-drops x 10 kWh / 7.2 h", "P-02 day +8"),
         derived("fraction_of_two_arrays", round(8 * 10 / 7.2 / 20, 2), "of 20 kW", "game_mean_power / (2 x 10 kW)",
                 "P-02 +8 is an [E] estimate")],
        "Published value", "A design study, not flight hardware; the 56 % mean output is our estimate [E].",
        [(ntrs(20210011743), "ntrs", ["conceptual design for a 10 kW solar array"]),
         (ntrs(20220013210), "ntrs", ["vertical array deployment on extension masts of up to 10m in length"])],
        transcribed="Blanket raised 10 m (PDF p. 5) and 16 m mast (PDF p. 8); pdftotext 2026-11-03 from "
                    "https://ntrs.nasa.gov/api/citations/20210011743/downloads/NASA-TM-20210011743.pdf")


def fx_clowdsley_2021_shielding():
    return pub(
        "clowdsley_2021_shielding", "How much shielding protects lunar crews from solar storms",
        "NASA Langley Research Center", "NTRS 20210009760", "https://ntrs.nasa.gov/citations/20210009760", US_GOV,
        "Clowdsley, M. (2021) Protecting Astronauts from Space Radiation on the Lunar Surface, Lunar Surface "
        "Innovation Consortium, 9 Feb 2021.",
        {"guideline_g_cm2": 20,
         "aug1972_spe_effective_dose_mSv_no_curtain": {"5": 185.4, "7": 136.9, "10": 105.4, "15": 85.1},
         "oct1989_spe_effective_dose_mSv_no_curtain": {"5": 160.1, "7": 136.9, "10": 108.0, "15": 88.9},
         "likely_spe_limit_mGy_eq_BFO": 250},
        [derived("water_per_wall_unit", round(20 / 6, 2), "g/cm2 = cm of water", "20 g/cm2 / 6 units",
                 "P-02 W cap 6; P-13 S6"),
         derived("relative_dose_aug1972", {"5": 1.0, "7": 0.74, "10": 0.57, "15": 0.46}, "fraction of 5 g/cm2",
                 "dose / dose at 5 g/cm2", "P-02 shelter table comparison (B3-3)")],
        "Published value",
        "Rover storm-shelter model for a female astronaut (slide 37); dose never reaches zero. Game zaps are not mSv.",
        [(ntrs(20210009760), "ntrs", ["Protecting Astronauts from Space Radiation on the Lunar Surface"])],
        transcribed="PDF pages 16 and 31 (20 g/cm2 guidance), 15 (250 mGy-eq), 37 (dose table); pdftotext 2026-11-03 "
                    "from https://ntrs.nasa.gov/api/citations/20210009760/downloads/Clowdsley_Lunar_Radiation_Talk_v2.pdf",
        src_card="SRC-SHIELDING")


def fx_lro_mazarico_2011_illumination():
    return pub(
        "lro_mazarico_2011_illumination", "Illumination of the lunar poles from LRO LOLA topography",
        "NASA Goddard Space Flight Center (LRO LOLA)", "NTRS 20120010094; DOI 10.1016/j.icarus.2010.10.030",
        "https://ntrs.nasa.gov/citations/20120010094", QUOTED,
        "Mazarico, E. et al. (2011) Illumination conditions of the lunar polar regions using LOLA topography, "
        "Icarus 211, 1066-1081.",
        {"longest_darkness_days": 1.5, "continuous_sunlight_days": 240},
        [derived("game_night_hours", 36, "h", "5 dark shifts x 7.2 h, sized to ~1.5 days", "P-02 shifts 3-7")],
        "Published value",
        "A specific Shackleton-rim site, not Aurora's fictional site; the game night is a training scenario.",
        [(ntrs(20120010094), "ntrs", ["sunlit continuously for 240 days, and its longest continuous period in total "
                                      "darkness is about 1.5 days"])],
        src_card="SRC-POLAR")


def fx_meo_lunar_impact_flashes():
    return pub(
        "meo_lunar_impact_flashes", "NASA lunar impact flash monitoring",
        "NASA Marshall Space Flight Center, Meteoroid Environment Office",
        "NTRS 20150016513 (Suggs et al. 2014 summary); NTRS 20170004471 (2015 Geminids)",
        "https://www.nasa.gov/meteoroid-environment-office/lunar-impact-monitoring/", US_GOV,
        "NASA MEO Lunar Impact Monitoring; Suggs, R.M. et al. (2014) flux summary (NTRS 20150016513); Moser, D.E., "
        "Suggs, R.M. & Ehlert, S.R. (2017) 2015 Geminid impact flashes (NTRS 20170004471).",
        {"nights_per_month": 10, "telescopes": 2, "calibrated_flashes_first_5_years": 126,
         "fraction_with_meteor_showers": 0.62, "geminid_detections_to_2017": "over 80"},
        [derived("verification_rule", "two telescopes must both see it", "rule", "MEO method",
                 "P-10 reject the two fixed artifacts")],
        "Published value", "Earth-based telescopes; the chapter's eight candidates and six-flash goal are authored.",
        [("https://www.nasa.gov/meteoroid-environment-office/lunar-impact-monitoring/", "html",
          ["observes the moon for meteoroid impact flashes about 10 nights per month",
           "Two telescopes fitted with astronomical video cameras"]),
         (ntrs(20150016513), "ntrs", ["Telescopic video observations of 126 impact flashes",
                                      "Approximately 62% of the impact flashes were correlated with major meteor showers"]),
         (ntrs(20170004471), "ntrs", ["over 80 detections"])],
        src_card="SRC-IMPACTS")


def fx_lcross_water_2009():
    return pub(
        "lcross_water_2009", "Water found by LCROSS in Cabeus crater", "NASA Ames Research Center (LCROSS)",
        "DOI 10.1126/science.1186986", "https://science.nasa.gov/mission/lcross/", QUOTED,
        "Colaprete, A. et al. (2010) Detection of water in the LCROSS ejecta plume, Science 330, 463-468.",
        {"water_ice_mass_percent": 5.6, "uncertainty_percent": 2.9, "impact_date": "2009-10-09"},
        [derived("positive_sample_reference", 5.6, "% water by mass", "LCROSS value", "P-07 ice scanner card")],
        "Published value", "One impact site; ice is not everywhere and is not drinking water.",
        [(epmc("10.1126/science.1186986"), "epmc", ["estimated to be 5.6 ± 2.9% by mass"])], src_card="SRC-ICE")


def fx_diviner_cold_traps():
    return pub(
        "diviner_cold_traps", "Diviner temperatures in south-polar cold traps", "NASA LRO Diviner (UCLA)",
        "DOI 10.1126/science.1187726", "https://www.diviner.ucla.edu/science", QUOTED,
        "Paige, D.A. et al. (2010) Diviner Lunar Radiometer observations of cold traps in the Moon's south polar "
        "region, Science 330, 479-482.",
        {"subsurface_temperature_K_lcross_site": 38},
        [derived("cold_trap_celsius", round(38 - 273.15, 1), "deg C", "K - 273.15", "P-07/P-08 cold card")],
        "Published value", "Estimated subsurface temperature at the LCROSS site; the vault site is fiction.",
        [(epmc("10.1126/science.1187726"), "epmc", ["subsurface temperatures are estimated to be 38 kelvin"])],
        src_card="SRC-ICE")


def fx_chandrayaan1_m3_ice():
    return pub(
        "chandrayaan1_m3_ice", "Exposed water ice seen by the Moon Mineralogy Mapper on Chandrayaan-1",
        "ISRO Chandrayaan-1 mission with NASA's Moon Mineralogy Mapper (partner agency)",
        "DOI 10.1073/pnas.1802345115", "https://doi.org/10.1073/pnas.1802345115", QUOTED,
        "Li, S. et al. (2018) Direct evidence of surface exposed water ice in the lunar polar regions, PNAS 115.",
        {"cold_traps_with_exposed_ice_percent": 3.5, "max_ice_wt_percent_some_pixels": 30},
        [derived("ice_is_patchy", True, "bool", "only ~3.5 % of cold traps show exposed ice", "P-07 survey lesson")],
        "Published value", "Surface (mm-deep) ice in some pixels; does not locate ice at the game's sample site.",
        [(epmc("10.1073/pnas.1802345115"), "epmc", ["3.5% of cold traps exhibit ice exposures",
                                                   "30 wt % ice that is intimately mixed with dry regolith"])],
        src_card="SRC-ICE")


def fx_kaguya_shackleton_floor():
    return pub(
        "kaguya_shackleton_floor", "Kaguya looks inside Shackleton crater",
        "JAXA SELENE (Kaguya) Terrain Camera (partner agency)", "DOI 10.1126/science.1164020",
        "https://darts.isas.jaxa.jp/planet/pdap/selene/", QUOTED,
        "Haruyama, J. et al. (2008) Lack of exposed ice inside lunar south pole Shackleton Crater, Science 322.",
        {"floor_temperature_K_below": 90, "exposed_pure_ice_seen": False},
        [derived("shackleton_floor_celsius_below", round(90 - 273.15, 1), "deg C", "K - 273.15", "P-08 vault card")],
        "Published value", "10 m resolution; ice may be mixed into soil below detection.",
        [(epmc("10.1126/science.1164020"), "epmc", ["less than approximately 90 kelvin",
                                                   "exposed relatively pure water-ice deposits are not on the crater floor"])],
        src_card="SRC-ICE")


def fx_viper_slope_limit():
    url = "https://science.nasa.gov/mission/viper/rover-and-instruments"
    return pub(
        "viper_slope_limit", "How steep a NASA lunar rover can climb", "NASA (VIPER rover)",
        "NASA VIPER rover and instruments page", url, US_GOV, "NASA Science, VIPER rover and instruments.",
        {"max_incline_deg": 15},
        [derived("rover_slope_limit", 15, "deg", "VIPER design incline", "P-07 limit 15 deg; P-15 road <= 12 deg")],
        "Published value", "VIPER's design figure; Aurora's rover and its road slopes are fictional [G].",
        [(url, "html", ["Capable of traversing an incline of as much as 15 degrees"])])


def fx_mir_brassica_seed_to_seed():
    return pub(
        "mir_brassica_seed_to_seed", "Brassica rapa completed seed-to-seed cycles on Mir",
        "NASA-funded experiment on Mir (Svet greenhouse)", "NTRS 20040141614",
        "https://ntrs.nasa.gov/citations/20040141614", QUOTED,
        "Musgrave, M.E. et al., Gravity independence of seed-to-seed cycling in Brassica rapa (NTRS 20040141614).",
        {"mission_days": 122, "species": "Brassica rapa"},
        [derived("hand_pollinated_in_space", True, "bool", "Mir Svet experiment", "P-03 and P-06 context")],
        "Published value", "Microgravity on Mir, not lunar gravity; Alo's dates and seed count are fiction.",
        [(ntrs(20040141614), "ntrs", ["During a 122-d opportunity on the Mir space station, full life cycles were "
                                      "completed in microgravity with Brassica rapa"])],
        src_card="SRC-POLLINATION")


def fx_fast_plants_lifecycle():
    url = "https://fastplants.org/frequently-asked-questions/"
    return pub(
        "fast_plants_lifecycle", "The Fast Plants (Brassica rapa) life cycle",
        "Wisconsin Fast Plants Program, University of Wisconsin-Madison (partner)", "Fast Plants FAQ", url,
        "CC BY-NC-SA (Wisconsin Fast Plants open resources); facts quoted with credit",
        "Wisconsin Fast Plants Program, Frequently Asked Questions, fastplants.org.",
        {"days_to_flower": 14, "stigma_receptive_days": [2, 4], "pollinate_days_after_planting": [15, 21],
         "pod_maturity_days_after_pollination": 20, "seed_harvest_days_after_planting": 40,
         "self_incompatible": True},
        [derived("alo_bloom_day", 16, "plant day", "planted 11 Apr, blooms 27 Apr (story)", "CH2; ~14 days"),
         derived("p03_run_days", [19, 25], "plant day", "30 Apr - 6 May after 11 Apr planting", "P-03 runs"),
         derived("p06_dry_down_end_day", 40, "plant day", "21 May after 11 Apr planting", "P-06 harvest")],
        "Published value", "Ideal Earth classroom conditions; lunar cultivation and the 42-seed count are fiction.",
        [(url, "html", ["uniform, short flowering time (14 days)", "Fast Plants are typically self-incompatible",
                        "stigma is receptive to pollen for 2-4 days",
                        "pollination to occur sometime between 15 and 21 days after planting",
                        "Seed pods mature about 20 days after pollination",
                        "harvestable seeds approximately 40 days after planting"])],
        src_card="SRC-PLANTS")


def fx_change4_lnd_surface_dose():
    return pub(
        "change4_lnd_surface_dose", "The first radiation dose measured on the Moon's surface",
        "CNSA Chang'e-4 lander, Lunar Lander Neutrons and Dosimetry (Kiel University) (partner agency)",
        "DOI 10.1126/sciadv.aaz1334", "https://doi.org/10.1126/sciadv.aaz1334", QUOTED,
        "Zhang, S. et al. (2020) First measurements of the radiation dose on the lunar surface, Science Advances 6.",
        {"absorbed_dose_rate_uGy_per_h_silicon": 13.2, "uncertainty": 1.0, "neutral_dose_rate_uGy_per_h": 3.1},
        [derived("quiet_dose_per_shift", round(13.2 * 7.2, 1), "uGy(Si) per 7.2 h", "13.2 x 7.2",
                 "P-14 route-dosimeter scale (proposal B3-13)")],
        "Published value", "Quiet-Sun dose in silicon on the far side, 2019; not a storm dose.",
        [(epmc("10.1126/sciadv.aaz1334"), "epmc", ["average total absorbed dose rate in silicon of 13.2 ± 1"])],
        src_card="SRC-SHIELDING")


def fx_change4_cotton():
    return pub(
        "change4_cotton", "A cotton seedling on the Moon (Chang'e-4, 2019)",
        "CNSA Chang'e-4 biological experiment, Chongqing University (partner agency)",
        "DOI 10.3390/ijms222111723", "https://doi.org/10.3390/ijms222111723", QUOTED,
        "Qiu, Jian, Zhang & Xie (2021) Plant gravitropism and signal conversion under a stress environment of "
        "altered gravity, Int. J. Mol. Sci. 22, 11723 (section 4.2).",
        {"year": 2019, "germinated": True, "flowered": False},
        [derived("milestone", "germination and a green seedling only", "fact", "experiment report", "P-09 parallel")],
        "Published value", "A sealed experiment; not a forecast for Aurora's garden. The finale's cotton is fiction.",
        [("https://api.crossref.org/works/10.3390/ijms222111723", "crossref",
          ["the first green leaf produced by mankind on the Moon"])],
        src_card="SRC-COTTON2019")


def fx_esa_moonlight_relay():
    url = "https://www.esa.int/Applications/Connectivity_and_Secure_Communications/Moonlight2"
    return pub(
        "esa_moonlight_relay", "Why south-pole crews need relays (ESA Moonlight)", "European Space Agency (partner)",
        "ESA Moonlight programme page", url, "(c) ESA; fact quoted with credit", "ESA, Moonlight.",
        {"direct_line_of_sight_can_be_blocked": True, "coverage_priority": "lunar south pole"},
        [derived("relay_needed", True, "bool", "terrain and curvature block direct Earth links", "P-15/P-16")],
        "Published value", "Aurora's road repeaters and Malapert relay are fiction; no service date is assumed.",
        [(url, "html", ["can prevent a direct line of sight between users on the surface and Earth",
                        "prioritise coverage of the lunar south pole"])],
        src_card="SRC-RELAY")


def fx_jpl_ipn_42_176_dte():
    url = "https://ipnpr.jpl.nasa.gov/progress_report/42-176/176C.pdf"
    get(url)  # existence check only; PDF text is not parsed (stdlib)
    rec = base(
        "jpl_ipn_42_176_dte", title="Sunlight and Earth-link availability near the south pole",
        agency="NASA Jet Propulsion Laboratory, Interplanetary Network Progress Report", dataset_id="IPN PR 42-176",
        url=url, licence=US_GOV,
        citation="Bryant, S. (2009) Lunar Pole Illumination and Communications Maps Computed from Goldstone Solar "
                 "System Radar Elevation Data, IPN Progress Report 42-176.",
        fields_used=["solar_availability_best_site_percent", "dte_availability_best_site_percent"],
        values={"solar_availability_best_site_percent": 92, "dte_availability_best_site_percent": 51},
        derived=[derived("why_malapert", "peaks near the pole can keep continuous Earth view", "fact",
                         "report abstract", "P-16")],
        evidence_label="Published value", boundary="Goldstone radar DEM (40 m); not Aurora's site.",
        verification=[{"checked_url": url, "quotes_found": [], "note": "HTTP 200; PDF not parsed"}],
        transcribed_from="Abstract, p. 1 (pdftotext 2026-11-03).", src_card="SRC-RELAY")
    return rec


FIXTURES = {f.__name__[3:]: f for f in (
    fx_donki_2017_09, fx_goes13_protons_2017_09, fx_donki_2012_07, fx_stereo_a_het_2012_07, fx_crater_dose_2012_07,
    fx_lro_mazarico_2011_illumination, fx_jpl_horizons_pole_season, fx_jpl_horizons_ch1_sky,
    fx_jpl_horizons_ch8_relay, fx_usgs_gazetteer_south_pole, fx_nasa_eclipse_2047_01_12, fx_bvad_2022_metabolic,
    fx_vsat_relocatable_array, fx_clowdsley_2021_shielding, fx_apollo_shallow_moonquakes, fx_meo_lunar_impact_flashes,
    fx_lcross_water_2009, fx_diviner_cold_traps, fx_chandrayaan1_m3_ice, fx_kaguya_shackleton_floor,
    fx_viper_slope_limit, fx_osdr_brassica_rapa_iss, fx_mir_brassica_seed_to_seed, fx_fast_plants_lifecycle,
    fx_change4_lnd_surface_dose, fx_change4_cotton, fx_esa_moonlight_relay, fx_jpl_ipn_42_176_dte)}

# Same mapping as docs/SCIENCE_AND_DATA.md §B2.
PUZZLES = {
    "P-01": ["osdr_brassica_rapa_iss", "fast_plants_lifecycle"],
    "P-02": ["donki_2017_09", "goes13_protons_2017_09", "lro_mazarico_2011_illumination", "jpl_horizons_pole_season",
             "jpl_horizons_ch1_sky", "bvad_2022_metabolic", "vsat_relocatable_array", "clowdsley_2021_shielding",
             "osdr_brassica_rapa_iss"],
    "P-03": ["fast_plants_lifecycle", "mir_brassica_seed_to_seed", "donki_2017_09"],
    "P-04": ["apollo_shallow_moonquakes"],
    "P-05": ["apollo_shallow_moonquakes", "bvad_2022_metabolic"],
    "P-06": ["fast_plants_lifecycle", "mir_brassica_seed_to_seed"],
    "P-07": ["viper_slope_limit", "lcross_water_2009", "diviner_cold_traps", "chandrayaan1_m3_ice",
             "kaguya_shackleton_floor", "bvad_2022_metabolic"],
    "P-08": ["diviner_cold_traps", "kaguya_shackleton_floor"],
    "P-09": ["change4_cotton"],
    "P-10": ["meo_lunar_impact_flashes", "bvad_2022_metabolic", "vsat_relocatable_array"],
    "P-11": ["nasa_eclipse_2047_01_12", "jpl_horizons_pole_season"],
    "P-12": ["nasa_eclipse_2047_01_12"],
    "P-13": ["donki_2012_07", "stereo_a_het_2012_07", "crater_dose_2012_07", "clowdsley_2021_shielding",
             "bvad_2022_metabolic"],
    "P-14": ["stereo_a_het_2012_07", "donki_2012_07", "change4_lnd_surface_dose"],
    "P-15": ["usgs_gazetteer_south_pole", "viper_slope_limit", "bvad_2022_metabolic", "esa_moonlight_relay"],
    "P-16": ["jpl_horizons_ch8_relay", "usgs_gazetteer_south_pole", "esa_moonlight_relay", "jpl_ipn_42_176_dte"],
}
SRC_CARDS = {
    "SRC-MOON": [], "SRC-POLAR": ["lro_mazarico_2011_illumination", "jpl_horizons_pole_season", "jpl_horizons_ch1_sky"],
    "SRC-LIFE-SUPPORT": ["bvad_2022_metabolic"], "SRC-PLANTS": ["fast_plants_lifecycle", "osdr_brassica_rapa_iss"],
    "SRC-POLLINATION": ["fast_plants_lifecycle", "mir_brassica_seed_to_seed"], "SRC-QUAKES": ["apollo_shallow_moonquakes"],
    "SRC-ICE": ["lcross_water_2009", "diviner_cold_traps", "chandrayaan1_m3_ice", "kaguya_shackleton_floor"],
    "SRC-IMPACTS": ["meo_lunar_impact_flashes"], "SRC-ECLIPSE": ["nasa_eclipse_2047_01_12"],
    "SRC-ECLIPSE-DATE": ["nasa_eclipse_2047_01_12"],
    "SRC-STORM2012": ["donki_2012_07", "stereo_a_het_2012_07", "crater_dose_2012_07"],
    "SRC-STORM2017": ["donki_2017_09", "goes13_protons_2017_09"],
    "SRC-SHIELDING": ["clowdsley_2021_shielding", "change4_lnd_surface_dose"],
    "SRC-RELAY": ["esa_moonlight_relay", "jpl_ipn_42_176_dte", "jpl_horizons_ch8_relay", "usgs_gazetteer_south_pole"],
    "SRC-COTTON2019": ["change4_cotton"],
}


def write_json(path, obj):
    path.write_text(json.dumps(obj, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")


def check():
    """Offline validation: every fixture has the required keys and size; every index id resolves."""
    problems = []
    for sid in FIXTURES:
        p = OUT / f"{sid}.json"
        if not p.exists():
            problems.append(f"missing fixture {p.name}")
            continue
        if p.stat().st_size >= MAX_BYTES:
            problems.append(f"{p.name} is {p.stat().st_size} bytes (limit {MAX_BYTES})")
        rec = json.loads(p.read_text(encoding="utf-8"))
        problems += [f"{p.name} lacks {k}" for k in REQUIRED if k not in rec or rec[k] in (None, "", [])]
        if rec.get("source_id") != sid:
            problems.append(f"{p.name} source_id is {rec.get('source_id')}")
    index = json.loads((OUT / "puzzle_sources.json").read_text(encoding="utf-8"))
    for key, ids in {**index["puzzles"], **index["src_cards"]}.items():
        problems += [f"{key} -> {i} has no fixture" for i in ids if not (OUT / f"{i}.json").exists()]
    if sorted(index["puzzles"]) != [f"P-{n:02d}" for n in range(1, 17)] or not all(index["puzzles"].values()):
        problems.append("puzzle index must list P-01..P-16, each with at least one fixture")
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--refresh", action="store_true", help="re-download fixtures that already exist")
    ap.add_argument("--only", default="", help="comma-separated fixture ids")
    ap.add_argument("--check", action="store_true", help="validate offline and exit")
    a = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    if a.check:
        problems = check()
        print("\n".join(problems) or f"OK: {len(FIXTURES)} fixtures, 16 puzzles, {len(SRC_CARDS)} source cards")
        return 1 if problems else 0
    wanted = [s for s in a.only.split(",") if s] or list(FIXTURES)
    unknown = [s for s in wanted if s not in FIXTURES]
    if unknown:
        sys.exit(f"unknown fixture ids: {unknown}")
    failed = []
    for sid in wanted:
        path = OUT / f"{sid}.json"
        if path.exists() and not a.refresh:
            print(f"keep   {sid}")
            continue
        try:
            rec = FIXTURES[sid]()
        except Exception as exc:  # report and continue: never write a partial or invented fixture
            failed.append(sid)
            print(f"FAIL   {sid}: {exc}")
            continue
        size = len(json.dumps(rec, indent=1, ensure_ascii=False).encode("utf-8"))
        if size >= MAX_BYTES:
            failed.append(sid)
            print(f"FAIL   {sid}: {size} bytes >= {MAX_BYTES}")
            continue
        write_json(path, rec)
        print(f"wrote  {sid} ({size} bytes)")
    write_json(OUT / "puzzle_sources.json", {
        "about": "P-01..P-16 and the SRC-* source cards -> fixture ids in this folder. Generated by "
                 "production/tools/fetch_nasa_data.py; mapping documented in docs/SCIENCE_AND_DATA.md §B2.",
        "puzzles": PUZZLES, "src_cards": SRC_CARDS})
    problems = check()
    print("\n".join(problems) or f"check OK: {len(FIXTURES)} fixtures")
    return 1 if failed or problems else 0


if __name__ == "__main__":
    sys.exit(main())
