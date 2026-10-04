#!/usr/bin/env python3
"""Structural checks and independent JSON-fixture oracle. Does NOT compile/run Swift."""
from pathlib import Path
import json, plistlib, re, struct, sys, unittest, xml.etree.ElementTree as ET
from decimal import Decimal

ROOT = Path(__file__).resolve().parents[1]

class SourceStructureChecks(unittest.TestCase):
    def test_source_references_are_complete(self):
        pbx = (ROOT/'PurchaseAssistant.xcodeproj/project.pbxproj').read_text()
        sources = list(ROOT.glob('App/**/*.swift')) + list(ROOT.glob('Sources/**/*.swift'))
        self.assertEqual(len(sources), 15)
        for source in sources:
            self.assertIn(str(source.relative_to(ROOT)), pbx)
        for path in re.findall(r'path = "([^"]+)"; sourceTree = SOURCE_ROOT;', pbx):
            self.assertTrue((ROOT/path).exists(), path)
        self.assertIn('IPHONEOS_DEPLOYMENT_TARGET = "17.0"', pbx)
        self.assertIn('DEVELOPMENT_TEAM = ""', pbx)

    def test_xcode_object_references_are_resolved(self):
        pbx = (ROOT/'PurchaseAssistant.xcodeproj/project.pbxproj').read_text()
        definitions = re.findall(r'^\s*([A-F0-9]{24}) = \{ isa = ', pbx, re.M)
        self.assertEqual(len(definitions), len(set(definitions)))
        references = set(re.findall(r'\b[A-F0-9]{24}\b', pbx))
        self.assertEqual(set(definitions), references)
        scheme = ET.parse(ROOT/'PurchaseAssistant.xcodeproj/xcshareddata/xcschemes/PurchaseAssistant.xcscheme')
        for node in scheme.findall('.//BuildableReference'):
            self.assertIn(node.attrib['BlueprintIdentifier'], definitions)

    def test_info_and_privacy_manifests(self):
        info = plistlib.loads((ROOT/'App/Info.plist').read_bytes())
        self.assertEqual(info['CFBundleDisplayName'], '购机准备')
        self.assertNotIn('NSAppTransportSecurity', info)
        self.assertFalse(any(key.endswith('UsageDescription') for key in info))
        privacy = plistlib.loads((ROOT/'App/PrivacyInfo.xcprivacy').read_bytes())
        self.assertFalse(privacy['NSPrivacyTracking'])
        self.assertEqual(privacy['NSPrivacyCollectedDataTypes'], [])
        self.assertEqual(privacy['NSPrivacyAccessedAPITypes'][0]['NSPrivacyAccessedAPITypeReasons'], ['CA92.1'])

    def test_assets(self):
        for file in ROOT.glob('App/Assets.xcassets/**/Contents.json'):
            json.loads(file.read_text())
        data = (ROOT/'App/Assets.xcassets/AppIcon.appiconset/AppIcon.png').read_bytes()
        self.assertEqual(data[:8], b'\x89PNG\r\n\x1a\n')
        width, height, depth, color = struct.unpack('>IIBB', data[16:26])
        self.assertEqual((width, height, depth, color), (1024, 1024, 8, 2))

    def test_no_automation_or_web_injection(self):
        source = '\n'.join(path.read_text() for path in list(ROOT.glob('App/**/*.swift')) + list(ROOT.glob('Sources/**/*.swift')))
        for forbidden in ['WKWebView', 'evaluateJavaScript', 'URLSession', 'URLRequest', 'HTTPCookie', 'SecItemAdd', 'javascript:']:
            self.assertNotIn(forbidden, source)
        urls = set(re.findall(r'https?://[^\s"\)]+', source))
        self.assertEqual(urls, {'https://www.apple.com.cn/iphone/', 'https://www.apple.com.cn/store'})

    def test_reminder_cancel_invalidation_is_present(self):
        source = (ROOT/'App/Services/ReminderService.swift').read_text()
        self.assertIn('import Combine', source)
        self.assertEqual(source.count('guard operation == generation'), 2)
        self.assertIn('func cancel() async {\n        generation += 1', source)
        self.assertIn('repeats: false', source)
        self.assertIn('nextDate > Date()', source)
        root_view = (ROOT/'App/Views/ContentView.swift').read_text()
        self.assertIn('.task(id: reminders.nextFireDate)', root_view)

    def test_cloud_build_is_manual_and_bounded(self):
        source = (ROOT/'.github/workflows/build-unsigned-ipa.yml').read_text()
        self.assertIn('  workflow_dispatch:', source)
        for forbidden in ['  push:', '  pull_request:', '  schedule:', 'strategy:', '-large', '-xlarge', 'secrets.']:
            self.assertNotIn(forbidden, source)
        self.assertEqual(source.count('    runs-on:'), 1)
        self.assertIn('runs-on: macos-15', source)
        self.assertIn('timeout-minutes: 5', source)
        self.assertIn('retention-days: 1', source)
        self.assertIn('contents: read', source)
        self.assertIn('persist-credentials: false', source)
        self.assertIn('github.event.repository.private == false', source)
        self.assertIn("github.repository == 'wuyunqing2010/DuoAssistant'", source)
        self.assertIn('CODE_SIGNING_ALLOWED=NO', source)
        self.assertIn('/usr/bin/lipo "$APP/$EXECUTABLE" -verify_arch arm64', source)
        self.assertNotIn('/usr/bin/lipo -verify_arch arm64 "$APP/$EXECUTABLE"', source)

    def test_native_tests_are_present_not_claimed_run(self):
        source = (ROOT/'Tests/PurchaseCoreTests/PurchaseCoreTests.swift').read_text()
        self.assertEqual(len(re.findall(r'func test\w+\(', source)), 17)
        self.assertIn('testOfflineReviewFixtures', source)
        self.assertIn('.process("Fixtures")', (ROOT/'Package.swift').read_text())

class IndependentFixtureOracleChecks(unittest.TestCase):
    """An independently written reference oracle checks fixture expectations only."""
    def test_review_fixture_expectations(self):
        fixtures = json.loads((ROOT/'Tests/PurchaseCoreTests/Fixtures/manual-review.json').read_text())
        def amount(text):
            value = text.strip()
            if not re.fullmatch(r'[0-9]{1,8}(\.[0-9]{1,2})?', value): return None
            n = Decimal(value)
            return n if Decimal(0) < n <= Decimal('99999999.99') else None
        self.assertEqual(len(fixtures), 12)
        for item in fixtures:
            with self.subTest(name=item['name']):
                budget, total = amount(item['budget']), amount(item['total'])
                expected = (budget is not None and total is not None and total <= budget
                            and item['quantity'].strip() == '1'
                            and item['storage'].strip().lower() == '256gb'
                            and item['currencyConfirmed'] and item['feesConfirmed'] and item['oneTimeConfirmed'])
                self.assertEqual(expected, item['expectedConsistent'])

if __name__ == '__main__':
    print('STATIC/REFERENCE CHECKS ONLY: Swift, SwiftUI and XCTest are not executed.', flush=True)
    unittest.main(verbosity=2)
