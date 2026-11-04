"""Offline regressions for M1-44. Run: python3 -m unittest discover -s tests -v."""
import csv
import datetime as dt
import importlib.util
import io
import json
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("fetch_nasa_data", ROOT / "production/tools/fetch_nasa_data.py")
NASA = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(NASA)


def fixture(name):
    """Read a checked-in fixture without network access."""
    return json.loads((NASA.OUT / (name + ".json")).read_text())


class NasaFixtureTests(unittest.TestCase):
    def test_osdr_protocol_whitespace(self):
        # Exercise the fetcher itself so a future refresh cannot restore false flags.
        for space in (" ", "\u2009", "\u202f", "\u00a0"):
            with self.subTest(space=repr(space)):
                protocol = f"temperature 23{space}C. 16{space}h/8{space}h light dark; 200–300{space}μmol"
                hits = {"hits": {"hits": [{"_source": {"Accession": acc, "Study Protocol Description": protocol}}
                                          for acc in ("OSD-59", "OSD-412")]}}
                with patch.object(NASA, "get_json", return_value=hits):
                    values = NASA.fx_osdr_brassica_rapa_iss()["values"]["OSD-412"]
                self.assertTrue(values["photoperiod_16_8"])
                self.assertTrue(values["temperature_23C"])
                self.assertEqual(values["par_umol_m2_s"], [200, 300])
        values = fixture("osdr_brassica_rapa_iss")["values"]["OSD-412"]
        self.assertTrue(values["photoperiod_16_8"])
        self.assertTrue(values["temperature_23C"])

    def test_goes_detector_windows_and_end_beyond_chart(self):
        # Synthetic CSV deliberately gives the west channel a different peak.
        # The fourth block is still storm-level: the chart edge is not its end.
        text = io.StringIO()
        text.write("NOAA test metadata\ndata:\n")
        writer = csv.writer(text)
        writer.writerow(["time_tag", "ZPGT10E", "ZPGT100E", "ZPGT10W", "ZPGT100W"])
        onset = dt.datetime(2017, 9, 10, 16, 45)
        end = dt.datetime(2017, 9, 14, 17, 25)
        for n in range(6 * 24 * 12):
            time = dt.datetime(2017, 9, 10, 12) + dt.timedelta(minutes=5 * n)
            block = int((time - onset).total_seconds() // (7.2 * 3600))
            flux = [100, 200, 300, 400][block] if 0 <= block < 4 else 20
            if time < onset or time >= end:
                flux = 1
            writer.writerow([str(time), flux, flux / 10, 9000, 900])
        with patch.object(NASA, "get", return_value=text.getvalue()):
            result = NASA.fx_goes13_protons_2017_09()
        derived = {row["name"]: row["value"] for row in result["derived"]}
        self.assertEqual(derived["gt10MeV_peak"], 400)
        self.assertEqual(derived["gt100MeV_peak"], 40)
        self.assertEqual(derived["gt10MeV_reaches_10pfu"], NASA.iso(onset))
        self.assertEqual(derived["storm_level_end"], NASA.iso(end))
        self.assertEqual([derived[f"storm_shift{n}_mean_gt10MeV"] for n in range(1, 5)], [100, 200, 300, 400])
        self.assertEqual(derived["shift2_over_shift1"], 2)
        self.assertEqual(len(result["values"]["hourly"]), 48)
        self.assertIn("ZPGT10E", result["fields_used"][1])

    def test_goes_bundled_official_peak(self):
        result = fixture("goes13_protons_2017_09")
        derived = {row["name"]: row["value"] for row in result["derived"]}
        self.assertLess(abs(derived["gt10MeV_peak"] - 1490) / 1490, 0.01)
        self.assertEqual(derived["gt10MeV_peak"], 1493.5)
        self.assertIn("2017-09-11T11:45Z", next(row["formula"] for row in result["derived"] if row["name"] == "gt10MeV_peak"))
        self.assertEqual(derived["storm_level_end"], "2017-09-14T17:25Z")
        self.assertEqual(derived["shift2_over_shift1"], 1.63)

    def test_horizons_refresh_preserves_elevation_columns(self):
        # Replay the bundled ephemerides through both fetcher builders. This
        # checks script/fixture agreement and the Earth/Sun tuple permutation.
        sky = fixture("jpl_horizons_ch1_sky")
        relay = fixture("jpl_horizons_ch8_relay")

        def response(target, lon, lat, start, stop, step):
            if start == "2046-04-01":
                rows = sky["values"]["six_hourly"]
                samples = [(r[0], r[2], r[1]) if target == 399 else (r[0], 0, r[3]) for r in rows]
            else:
                rows = relay["values"]["malapert_15min" if step == "15 m" else "pole_6hourly"]
                samples = [(r[0], r[2], r[1]) for r in rows]
            return "cached", [(dt.datetime.strptime(t, "%Y-%m-%dT%H:%MZ"), az, el) for t, az, el in samples]

        with patch.object(NASA, "horizons", side_effect=response):
            self.assertEqual(NASA.fx_jpl_horizons_ch1_sky()["values"], sky["values"])
            self.assertEqual(NASA.fx_jpl_horizons_ch8_relay()["values"], relay["values"])
        crossings = NASA.crossings(response(399, 0, -90, "2046-04-01", "", "6 h")[1])
        self.assertIn(("2046-04-15T03:17Z", "set"), crossings)
        self.assertIn(("2046-04-28T06:03Z", "rise"), crossings)

    def test_story_dates_are_qualified(self):
        lifecycle = fixture("fast_plants_lifecycle")
        self.assertEqual(lifecycle["values"]["days_to_flower"], 14)
        self.assertTrue(all("story" in row["formula"] for row in lifecycle["derived"]))
        with patch.object(NASA, "verify_quotes", return_value=[]):
            self.assertEqual(NASA.fx_fast_plants_lifecycle()["derived"], lifecycle["derived"])


if __name__ == "__main__":
    unittest.main()
