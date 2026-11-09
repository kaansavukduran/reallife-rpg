import copy
import json
import os
import threading
import unittest
from http.client import HTTPConnection
from http.server import ThreadingHTTPServer
from unittest.mock import patch
from assessment_server import DIMENSIONS, Handler, validate_result


class AssessmentTests(unittest.TestCase):
    def setUp(self):
        self.evidence = "This is the exact submitted work sample. " * 5
        self.result = {d: {"score": 2, "reason": "Kısmi kanıt.", "quote": "exact submitted work"} for d in DIMENSIONS}
        self.result.update(next_steps="Sınır durumları ekle.", uncertainty="Küçük örneklem.")

    def test_score_is_sum_of_validated_dimensions(self):
        result = validate_result(self.result, self.evidence, "test-model")
        self.assertEqual((result["score"], result["total"]), (8, 16))
        self.assertIn("test-model", result["feedback"])

    def test_hallucinated_quote_is_rejected(self):
        self.result["accuracy"]["quote"] = "not in the evidence"
        with self.assertRaises(ValueError):
            validate_result(self.result, self.evidence, "test")

    def test_missing_and_out_of_range_dimensions_rejected(self):
        for value in [5, -1, True, "4"]:
            result = copy.deepcopy(self.result)
            result["accuracy"]["score"] = value
            with self.assertRaises(ValueError):
                validate_result(result, self.evidence, "test")
        del self.result["accuracy"]
        with self.assertRaises(ValueError):
            validate_result(self.result, self.evidence, "test")

    def test_nonzero_score_requires_actual_quote(self):
        self.result["accuracy"]["quote"] = ""
        with self.assertRaises(ValueError):
            validate_result(self.result, self.evidence, "test")
        self.result["accuracy"]["score"] = 0
        self.assertEqual(validate_result(self.result, self.evidence, "test")["score"], 6)

    def test_http_input_validation_and_missing_key_do_not_fake_score(self):
        server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            with patch.dict(os.environ, {}, clear=True):
                for payload, expected in [([], 400), ({"skill": "software", "evidence": "short"}, 400),
                    ({"skill": "unknown", "evidence": self.evidence}, 400),
                    ({"skill": "software", "evidence": self.evidence}, 503)]:
                    conn = HTTPConnection("127.0.0.1", server.server_port)
                    conn.request("POST", "/assess", json.dumps(payload), {"Content-Type": "application/json"})
                    response = conn.getresponse()
                    self.assertEqual(response.status, expected)
                    self.assertNotIn("score", json.loads(response.read()))
                    conn.close()
        finally:
            server.shutdown()
            server.server_close()
            thread.join()


if __name__ == "__main__":
    unittest.main()
