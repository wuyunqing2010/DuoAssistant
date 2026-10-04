#!/usr/bin/env python3
"""Regenerate the checked-in Xcode project using Python's standard library only."""
from pathlib import Path
from hashlib import sha1
import json
import plistlib

ROOT = Path(__file__).resolve().parents[1]

def uid(value):
    return sha1(value.encode()).hexdigest().upper()[:24]

def q(value):
    return json.dumps(str(value), ensure_ascii=False)

sources = sorted(str(p.relative_to(ROOT)) for p in ROOT.glob('App/**/*.swift'))
sources += sorted(str(p.relative_to(ROOT)) for p in ROOT.glob('Sources/**/*.swift'))
resources = ['App/Assets.xcassets', 'App/PrivacyInfo.xcprivacy']
objects = []
def add(key, value):
    objects.append(f'\t\t{uid(key)} = {{ {value} }};')

for path in sources + resources + ['App/Info.plist']:
    kind = ('sourcecode.swift' if path.endswith('.swift') else
            'folder.assetcatalog' if path.endswith('.xcassets') else 'text.plist.xml')
    add('ref:' + path, f'isa = PBXFileReference; lastKnownFileType = {kind}; path = {q(path)}; sourceTree = SOURCE_ROOT;')
for path in sources + resources:
    add('build:' + path, f'isa = PBXBuildFile; fileRef = {uid("ref:" + path)};')
add('product', 'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = PurchaseAssistant.app; sourceTree = BUILT_PRODUCTS_DIR;')
children = ', '.join(uid('ref:' + p) for p in sources + resources + ['App/Info.plist'])
add('main', f'isa = PBXGroup; children = ({children}, {uid("products")},); sourceTree = "<group>";')
add('products', f'isa = PBXGroup; children = ({uid("product")},); name = Products; sourceTree = "<group>";')
add('sources', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({", ".join(uid("build:" + p) for p in sources)},); runOnlyForDeploymentPostprocessing = 0;')
add('resources', f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({", ".join(uid("build:" + p) for p in resources)},); runOnlyForDeploymentPostprocessing = 0;')
add('frameworks', 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
add('target', f'isa = PBXNativeTarget; buildConfigurationList = {uid("target-config")}; buildPhases = ({uid("sources")}, {uid("frameworks")}, {uid("resources")},); buildRules = (); dependencies = (); name = PurchaseAssistant; productName = PurchaseAssistant; productReference = {uid("product")}; productType = "com.apple.product-type.application";')
add('project', f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1500; TargetAttributes = {{ {uid("target")} = {{ CreatedOnToolsVersion = 15.0; }}; }}; }}; buildConfigurationList = {uid("project-config")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = "zh-Hans"; hasScannedForEncodings = 0; knownRegions = ("zh-Hans", en, Base); mainGroup = {uid("main")}; productRefGroup = {uid("products")}; projectDirPath = ""; projectRoot = ""; targets = ({uid("target")},);')
for owner in ['project', 'target']:
    for config in ['Debug', 'Release']:
        if owner == 'project':
            values = {
                'ALWAYS_SEARCH_USER_PATHS': 'NO', 'CLANG_ENABLE_MODULES': 'YES',
                'CLANG_ENABLE_OBJC_ARC': 'YES', 'CLANG_WARN_DOCUMENTATION_COMMENTS': 'YES',
                'COPY_PHASE_STRIP': 'NO', 'GCC_C_LANGUAGE_STANDARD': 'gnu17',
                'IPHONEOS_DEPLOYMENT_TARGET': '17.0', 'SDKROOT': 'iphoneos',
                'SWIFT_VERSION': '5.0', 'SWIFT_STRICT_CONCURRENCY': 'targeted',
                'ENABLE_USER_SCRIPT_SANDBOXING': 'YES',
                'DEBUG_INFORMATION_FORMAT': 'dwarf' if config == 'Debug' else 'dwarf-with-dsym',
                'SWIFT_OPTIMIZATION_LEVEL': '-Onone' if config == 'Debug' else '-O',
            }
            if config == 'Debug':
                values.update(ENABLE_TESTABILITY='YES', ONLY_ACTIVE_ARCH='YES', SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG')
            else:
                values.update(SWIFT_COMPILATION_MODE='wholemodule', VALIDATE_PRODUCT='YES')
        else:
            values = {
                'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon',
                'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME': 'AccentColor',
                'CODE_SIGN_STYLE': 'Automatic', 'CURRENT_PROJECT_VERSION': '1',
                'DEVELOPMENT_TEAM': '', 'GENERATE_INFOPLIST_FILE': 'NO',
                'INFOPLIST_FILE': 'App/Info.plist', 'MARKETING_VERSION': '1.0.0',
                'PRODUCT_BUNDLE_IDENTIFIER': 'com.example.PurchaseAssistant',
                'PRODUCT_NAME': '$(TARGET_NAME)', 'SUPPORTED_PLATFORMS': 'iphoneos iphonesimulator',
                'SUPPORTS_MACCATALYST': 'NO', 'SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD': 'NO',
                'SWIFT_EMIT_LOC_STRINGS': 'YES', 'TARGETED_DEVICE_FAMILY': '1',
            }
        settings = ' '.join(f'{key} = {q(value)};' for key, value in values.items())
        add(f'{owner}-{config}', f'isa = XCBuildConfiguration; buildSettings = {{ {settings} }}; name = {config};')
    add(f'{owner}-config', f'isa = XCConfigurationList; buildConfigurations = ({uid(owner + "-Debug")}, {uid(owner + "-Release")},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
output = '// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n' + '\n'.join(objects) + '\n\t};\n\trootObject = ' + uid('project') + ';\n}\n'
(ROOT/'PurchaseAssistant.xcodeproj/project.pbxproj').write_text(output)
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1500" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
      <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid('target')}" BuildableName="PurchaseAssistant.app" BlueprintName="PurchaseAssistant" ReferencedContainer="container:PurchaseAssistant.xcodeproj"/>
    </BuildActionEntry></BuildActionEntries>
  </BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables/></TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
    <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid('target')}" BuildableName="PurchaseAssistant.app" BlueprintName="PurchaseAssistant" ReferencedContainer="container:PurchaseAssistant.xcodeproj"/></BuildableProductRunnable>
  </LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
    <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid('target')}" BuildableName="PurchaseAssistant.app" BlueprintName="PurchaseAssistant" ReferencedContainer="container:PurchaseAssistant.xcodeproj"/></BuildableProductRunnable>
  </ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
'''
(ROOT/'PurchaseAssistant.xcodeproj/xcshareddata/xcschemes/PurchaseAssistant.xcscheme').write_text(scheme)
info = {
    'CFBundleDevelopmentRegion': 'zh-Hans', 'CFBundleDisplayName': '购机准备',
    'CFBundleExecutable': '$(EXECUTABLE_NAME)', 'CFBundleIdentifier': '$(PRODUCT_BUNDLE_IDENTIFIER)',
    'CFBundleInfoDictionaryVersion': '6.0', 'CFBundleName': '$(PRODUCT_NAME)',
    'CFBundlePackageType': 'APPL', 'CFBundleShortVersionString': '$(MARKETING_VERSION)',
    'CFBundleVersion': '$(CURRENT_PROJECT_VERSION)', 'LSRequiresIPhoneOS': True,
    'UIApplicationSceneManifest': {'UIApplicationSupportsMultipleScenes': False},
    'UILaunchScreen': {}, 'UISupportedInterfaceOrientations': ['UIInterfaceOrientationPortrait'],
    'UIRequiresFullScreen': True,
}
privacy = {
    'NSPrivacyTracking': False, 'NSPrivacyTrackingDomains': [], 'NSPrivacyCollectedDataTypes': [],
    'NSPrivacyAccessedAPITypes': [{'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryUserDefaults',
                                 'NSPrivacyAccessedAPITypeReasons': ['CA92.1']}],
}
for path, data in [('App/Info.plist',info),('App/PrivacyInfo.xcprivacy',privacy)]:
    (ROOT/path).write_bytes(plistlib.dumps(data,sort_keys=False))
print(f'Generated project: {len(sources)} Swift source files; {len(resources)} resource references')
