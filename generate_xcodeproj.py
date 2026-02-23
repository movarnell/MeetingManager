#!/usr/bin/env python3
"""Generate a proper Xcode project.pbxproj for MeetingManager."""

import hashlib
import os

# Generate deterministic UUIDs based on path
def make_uuid(seed: str) -> str:
    return hashlib.md5(seed.encode()).hexdigest()[:24].upper()

import re

def quote_plist_string(s: str) -> str:
    """Quote a string for old-style plist if it contains special characters."""
    # Old-style plist requires quoting for strings with non-alphanumeric chars
    # (except _ and .) that aren't already quoted
    if re.search(r'[^a-zA-Z0-9_.]', s):
        return f'"{s}"'
    return s

# All swift source files (relative to project root)
SWIFT_FILES = [
    "MeetingManager/MeetingManagerApp.swift",
    "MeetingManager/Extensions/AVAudioPCMBuffer+Extensions.swift",
    "MeetingManager/Extensions/CMSampleBuffer+Extensions.swift",
    "MeetingManager/Extensions/Data+WAVHeader.swift",
    "MeetingManager/Models/AudioSource.swift",
    "MeetingManager/Models/Meeting.swift",
    "MeetingManager/Models/MeetingNotes.swift",
    "MeetingManager/Models/OllamaTypes.swift",
    "MeetingManager/Models/RecordingState.swift",
    "MeetingManager/Models/Transcript.swift",
    "MeetingManager/Services/AudioMixerService.swift",
    "MeetingManager/Services/AudioRecordingService.swift",
    "MeetingManager/Services/MicrophoneCaptureService.swift",
    "MeetingManager/Services/OllamaService.swift",
    "MeetingManager/Services/StorageService.swift",
    "MeetingManager/Services/SystemAudioCaptureService.swift",
    "MeetingManager/Services/TranscriptionService.swift",
    "MeetingManager/Utilities/AudioFormatConverter.swift",
    "MeetingManager/Utilities/Constants.swift",
    "MeetingManager/Utilities/DateFormatters.swift",
    "MeetingManager/Utilities/WAVFileWriter.swift",
    "MeetingManager/ViewModels/MeetingNotesViewModel.swift",
    "MeetingManager/ViewModels/MeetingsListViewModel.swift",
    "MeetingManager/ViewModels/RecordingViewModel.swift",
    "MeetingManager/ViewModels/SettingsViewModel.swift",
    "MeetingManager/ViewModels/TranscriptionViewModel.swift",
    "MeetingManager/Views/Components/EmptyStateView.swift",
    "MeetingManager/Views/Components/StatusIndicatorView.swift",
    "MeetingManager/Views/Components/TagEditorView.swift",
    "MeetingManager/Views/Components/WaveformView.swift",
    "MeetingManager/Views/ContentView.swift",
    "MeetingManager/Views/MeetingDetailView.swift",
    "MeetingManager/Views/MenuBar/MenuBarView.swift",
    "MeetingManager/Views/Notes/ExportOptionsView.swift",
    "MeetingManager/Views/Notes/MarkdownRendererView.swift",
    "MeetingManager/Views/Notes/MeetingNotesView.swift",
    "MeetingManager/Views/Recording/AudioLevelMeterView.swift",
    "MeetingManager/Views/Recording/AudioSourceToggleView.swift",
    "MeetingManager/Views/Recording/RecordButtonView.swift",
    "MeetingManager/Views/Recording/RecordingTimerView.swift",
    "MeetingManager/Views/Recording/RecordingView.swift",
    "MeetingManager/Views/Settings/OllamaSettingsView.swift",
    "MeetingManager/Views/Settings/SettingsView.swift",
    "MeetingManager/Views/Settings/StorageSettingsView.swift",
    "MeetingManager/Views/Settings/WhisperSettingsView.swift",
    "MeetingManager/Views/Sidebar/MeetingRowView.swift",
    "MeetingManager/Views/Sidebar/MeetingsSidebarView.swift",
    "MeetingManager/Views/Transcript/TranscriptSegmentView.swift",
    "MeetingManager/Views/Transcript/TranscriptView.swift",
]

# Groups (folders in Xcode project navigator)
GROUPS = {
    "MeetingManager": ["Extensions", "Models", "Services", "Utilities", "ViewModels", "Views"],
    "Views": ["Components", "MenuBar", "Notes", "Recording", "Settings", "Sidebar", "Transcript"],
}

# Fixed UUIDs for well-known objects
PROJECT_UUID = make_uuid("project")
MAIN_GROUP_UUID = make_uuid("mainGroup")
MM_GROUP_UUID = make_uuid("group_MeetingManager")
PRODUCTS_GROUP_UUID = make_uuid("productsGroup")
PACKAGES_GROUP_UUID = make_uuid("packagesGroup")
TARGET_UUID = make_uuid("target_MeetingManager")
APP_PRODUCT_UUID = make_uuid("product_MeetingManager.app")
SOURCES_PHASE_UUID = make_uuid("sourcesBuildPhase")
RESOURCES_PHASE_UUID = make_uuid("resourcesBuildPhase")
FRAMEWORKS_PHASE_UUID = make_uuid("frameworksBuildPhase")
DEBUG_CONFIG_UUID = make_uuid("debugConfig")
RELEASE_CONFIG_UUID = make_uuid("releaseConfig")
TARGET_DEBUG_CONFIG_UUID = make_uuid("targetDebugConfig")
TARGET_RELEASE_CONFIG_UUID = make_uuid("targetReleaseConfig")
PROJECT_CONFIG_LIST_UUID = make_uuid("projectConfigList")
TARGET_CONFIG_LIST_UUID = make_uuid("targetConfigList")
ASSETS_FILE_REF_UUID = make_uuid("fileRef_Assets.xcassets")
ASSETS_BUILD_FILE_UUID = make_uuid("buildFile_Assets.xcassets")
INFOPLIST_FILE_REF_UUID = make_uuid("fileRef_Info.plist")
ENTITLEMENTS_FILE_REF_UUID = make_uuid("fileRef_MeetingManager.entitlements")
PKG_REF_WHISPERKIT_UUID = make_uuid("pkgRef_WhisperKit")
PKG_PRODUCT_WHISPERKIT_UUID = make_uuid("pkgProduct_WhisperKit")
PKG_PRODUCT_BUILD_FILE_UUID = make_uuid("pkgProductBuildFile_WhisperKit")

# Group UUIDs
EXTENSIONS_GROUP_UUID = make_uuid("group_Extensions")
MODELS_GROUP_UUID = make_uuid("group_Models")
SERVICES_GROUP_UUID = make_uuid("group_Services")
UTILITIES_GROUP_UUID = make_uuid("group_Utilities")
VIEWMODELS_GROUP_UUID = make_uuid("group_ViewModels")
VIEWS_GROUP_UUID = make_uuid("group_Views")
COMPONENTS_GROUP_UUID = make_uuid("group_Components")
MENUBAR_GROUP_UUID = make_uuid("group_MenuBar")
NOTES_GROUP_UUID = make_uuid("group_Notes")
RECORDING_GROUP_UUID = make_uuid("group_Recording")
SETTINGS_GROUP_UUID = make_uuid("group_Settings")
SIDEBAR_GROUP_UUID = make_uuid("group_Sidebar")
TRANSCRIPT_GROUP_UUID = make_uuid("group_Transcript")

def get_group_uuid(folder_name):
    mapping = {
        "Extensions": EXTENSIONS_GROUP_UUID,
        "Models": MODELS_GROUP_UUID,
        "Services": SERVICES_GROUP_UUID,
        "Utilities": UTILITIES_GROUP_UUID,
        "ViewModels": VIEWMODELS_GROUP_UUID,
        "Views": VIEWS_GROUP_UUID,
        "Components": COMPONENTS_GROUP_UUID,
        "MenuBar": MENUBAR_GROUP_UUID,
        "Notes": NOTES_GROUP_UUID,
        "Recording": RECORDING_GROUP_UUID,
        "Settings": SETTINGS_GROUP_UUID,
        "Sidebar": SIDEBAR_GROUP_UUID,
        "Transcript": TRANSCRIPT_GROUP_UUID,
    }
    return mapping.get(folder_name, make_uuid(f"group_{folder_name}"))

def categorize_file(filepath):
    """Return the group name this file belongs to."""
    parts = filepath.replace("MeetingManager/", "", 1).split("/")
    if len(parts) == 1:
        return None  # Root level of MeetingManager group
    if len(parts) == 2:
        return parts[0]  # e.g., Extensions, Models, etc.
    if len(parts) == 3 and parts[0] == "Views":
        return parts[1]  # e.g., Components, Recording, etc.
    return parts[0]

# Build file references and build files
file_refs = {}
build_files = {}

for f in SWIFT_FILES:
    filename = os.path.basename(f)
    ref_uuid = make_uuid(f"fileRef_{f}")
    build_uuid = make_uuid(f"buildFile_{f}")
    file_refs[f] = ref_uuid
    build_files[f] = build_uuid

# Now generate the pbxproj
lines = []

def w(line=""):
    lines.append(line)

w("// !$*UTF8*$!")
w("{")
w("\tarchiveVersion = 1;")
w("\tclasses = {")
w("\t};")
w("\tobjectVersion = 56;")
w("\tobjects = {")
w("")

# PBXBuildFile section
w("/* Begin PBXBuildFile section */")
for f in SWIFT_FILES:
    filename = os.path.basename(f)
    w(f"\t\t{build_files[f]} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {filename} */; }};")
w(f"\t\t{ASSETS_BUILD_FILE_UUID} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ASSETS_FILE_REF_UUID} /* Assets.xcassets */; }};")
w(f"\t\t{PKG_PRODUCT_BUILD_FILE_UUID} /* WhisperKit in Frameworks */ = {{isa = PBXBuildFile; productRef = {PKG_PRODUCT_WHISPERKIT_UUID} /* WhisperKit */; }};")
w("/* End PBXBuildFile section */")
w("")

# PBXFileReference section
w("/* Begin PBXFileReference section */")
w(f"\t\t{APP_PRODUCT_UUID} /* MeetingManager.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MeetingManager.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
for f in SWIFT_FILES:
    filename = os.path.basename(f)
    qfn = quote_plist_string(filename)
    w(f"\t\t{file_refs[f]} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {qfn}; sourceTree = \"<group>\"; }};")
w(f"\t\t{ASSETS_FILE_REF_UUID} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};")
w(f"\t\t{INFOPLIST_FILE_REF_UUID} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};")
w(f"\t\t{ENTITLEMENTS_FILE_REF_UUID} /* MeetingManager.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = MeetingManager.entitlements; sourceTree = \"<group>\"; }};")
w("/* End PBXFileReference section */")
w("")

# PBXFrameworksBuildPhase
w("/* Begin PBXFrameworksBuildPhase section */")
w(f"\t\t{FRAMEWORKS_PHASE_UUID} /* Frameworks */ = {{")
w("\t\t\tisa = PBXFrameworksBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
w(f"\t\t\t\t{PKG_PRODUCT_BUILD_FILE_UUID} /* WhisperKit in Frameworks */,")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXFrameworksBuildPhase section */")
w("")

# PBXGroup section
w("/* Begin PBXGroup section */")

# Main group (project root)
w(f"\t\t{MAIN_GROUP_UUID} = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
w(f"\t\t\t\t{MM_GROUP_UUID} /* MeetingManager */,")
w(f"\t\t\t\t{PRODUCTS_GROUP_UUID} /* Products */,")
w(f"\t\t\t\t{PACKAGES_GROUP_UUID} /* Packages */,")
w("\t\t\t);")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")
w("")

# Products group
w(f"\t\t{PRODUCTS_GROUP_UUID} /* Products */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
w(f"\t\t\t\t{APP_PRODUCT_UUID} /* MeetingManager.app */,")
w("\t\t\t);")
w("\t\t\tname = Products;")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")
w("")

# Packages group (for SPM)
w(f"\t\t{PACKAGES_GROUP_UUID} /* Packages */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
w("\t\t\t);")
w("\t\t\tname = Packages;")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")
w("")

# Helper to get files in a group
def files_in_group(group_path):
    """Get files that belong to a specific group."""
    result = []
    for f in SWIFT_FILES:
        rel = f.replace("MeetingManager/", "", 1)
        parts = rel.split("/")
        if group_path == "" and len(parts) == 1:
            result.append(f)
        elif group_path and rel.startswith(group_path + "/"):
            remaining = rel[len(group_path) + 1:]
            if "/" not in remaining:
                result.append(f)
    return result

# MeetingManager group
root_files = files_in_group("")
w(f"\t\t{MM_GROUP_UUID} /* MeetingManager */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
# Root swift files first
for f in root_files:
    filename = os.path.basename(f)
    w(f"\t\t\t\t{file_refs[f]} /* {filename} */,")
# Then subgroups
for subgroup in ["Extensions", "Models", "Services", "Utilities", "ViewModels", "Views"]:
    w(f"\t\t\t\t{get_group_uuid(subgroup)} /* {subgroup} */,")
# Then resources
w(f"\t\t\t\t{ASSETS_FILE_REF_UUID} /* Assets.xcassets */,")
w(f"\t\t\t\t{INFOPLIST_FILE_REF_UUID} /* Info.plist */,")
w(f"\t\t\t\t{ENTITLEMENTS_FILE_REF_UUID} /* MeetingManager.entitlements */,")
w("\t\t\t);")
w("\t\t\tpath = MeetingManager;")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")
w("")

# Subgroups under MeetingManager
for subgroup in ["Extensions", "Models", "Services", "Utilities", "ViewModels"]:
    group_files = files_in_group(subgroup)
    w(f"\t\t{get_group_uuid(subgroup)} /* {subgroup} */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for f in sorted(group_files, key=lambda x: os.path.basename(x)):
        filename = os.path.basename(f)
        w(f"\t\t\t\t{file_refs[f]} /* {filename} */,")
    w("\t\t\t);")
    w(f"\t\t\tpath = {subgroup};")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")
    w("")

# Views group (has subgroups)
views_root_files = files_in_group("Views")
w(f"\t\t{VIEWS_GROUP_UUID} /* Views */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
for f in sorted(views_root_files, key=lambda x: os.path.basename(x)):
    filename = os.path.basename(f)
    w(f"\t\t\t\t{file_refs[f]} /* {filename} */,")
for subgroup in ["Components", "MenuBar", "Notes", "Recording", "Settings", "Sidebar", "Transcript"]:
    w(f"\t\t\t\t{get_group_uuid(subgroup)} /* {subgroup} */,")
w("\t\t\t);")
w("\t\t\tpath = Views;")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")
w("")

# Views subgroups
for subgroup in ["Components", "MenuBar", "Notes", "Recording", "Settings", "Sidebar", "Transcript"]:
    group_files = files_in_group(f"Views/{subgroup}")
    w(f"\t\t{get_group_uuid(subgroup)} /* {subgroup} */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for f in sorted(group_files, key=lambda x: os.path.basename(x)):
        filename = os.path.basename(f)
        w(f"\t\t\t\t{file_refs[f]} /* {filename} */,")
    w("\t\t\t);")
    w(f"\t\t\tpath = {subgroup};")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")
    w("")

w("/* End PBXGroup section */")
w("")

# PBXNativeTarget
w("/* Begin PBXNativeTarget section */")
w(f"\t\t{TARGET_UUID} /* MeetingManager */ = {{")
w("\t\t\tisa = PBXNativeTarget;")
w(f"\t\t\tbuildConfigurationList = {TARGET_CONFIG_LIST_UUID} /* Build configuration list for PBXNativeTarget \"MeetingManager\" */;")
w("\t\t\tbuildPhases = (")
w(f"\t\t\t\t{SOURCES_PHASE_UUID} /* Sources */,")
w(f"\t\t\t\t{FRAMEWORKS_PHASE_UUID} /* Frameworks */,")
w(f"\t\t\t\t{RESOURCES_PHASE_UUID} /* Resources */,")
w("\t\t\t);")
w("\t\t\tbuildRules = (")
w("\t\t\t);")
w("\t\t\tdependencies = (")
w("\t\t\t);")
w("\t\t\tname = MeetingManager;")
w("\t\t\tpackageProductDependencies = (")
w(f"\t\t\t\t{PKG_PRODUCT_WHISPERKIT_UUID} /* WhisperKit */,")
w("\t\t\t);")
w(f"\t\t\tproductName = MeetingManager;")
w(f"\t\t\tproductReference = {APP_PRODUCT_UUID} /* MeetingManager.app */;")
w("\t\t\tproductType = \"com.apple.product-type.application\";")
w("\t\t};")
w("/* End PBXNativeTarget section */")
w("")

# PBXProject
w("/* Begin PBXProject section */")
w(f"\t\t{PROJECT_UUID} /* Project object */ = {{")
w("\t\t\tisa = PBXProject;")
w("\t\t\tattributes = {")
w("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
w("\t\t\t\tLastSwiftUpdateCheck = 1600;")
w("\t\t\t\tLastUpgradeCheck = 1600;")
w("\t\t\t};")
w(f"\t\t\tbuildConfigurationList = {PROJECT_CONFIG_LIST_UUID} /* Build configuration list for PBXProject \"MeetingManager\" */;")
w("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
w("\t\t\tdevelopmentRegion = en;")
w("\t\t\thasScannedForEncodings = 0;")
w("\t\t\tknownRegions = (")
w("\t\t\t\ten,")
w("\t\t\t\tBase,")
w("\t\t\t);")
w(f"\t\t\tmainGroup = {MAIN_GROUP_UUID};")
w("\t\t\tpackageReferences = (")
w(f"\t\t\t\t{PKG_REF_WHISPERKIT_UUID} /* XCRemoteSwiftPackageReference \"WhisperKit\" */,")
w("\t\t\t);")
w(f"\t\t\tproductRefGroup = {PRODUCTS_GROUP_UUID} /* Products */;")
w("\t\t\tprojectDirPath = \"\";")
w("\t\t\tprojectRoot = \"\";")
w("\t\t\ttargets = (")
w(f"\t\t\t\t{TARGET_UUID} /* MeetingManager */,")
w("\t\t\t);")
w("\t\t};")
w("/* End PBXProject section */")
w("")

# PBXResourcesBuildPhase
w("/* Begin PBXResourcesBuildPhase section */")
w(f"\t\t{RESOURCES_PHASE_UUID} /* Resources */ = {{")
w("\t\t\tisa = PBXResourcesBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
w(f"\t\t\t\t{ASSETS_BUILD_FILE_UUID} /* Assets.xcassets in Resources */,")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXResourcesBuildPhase section */")
w("")

# PBXSourcesBuildPhase
w("/* Begin PBXSourcesBuildPhase section */")
w(f"\t\t{SOURCES_PHASE_UUID} /* Sources */ = {{")
w("\t\t\tisa = PBXSourcesBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
for f in SWIFT_FILES:
    filename = os.path.basename(f)
    w(f"\t\t\t\t{build_files[f]} /* {filename} in Sources */,")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXSourcesBuildPhase section */")
w("")

# XCBuildConfiguration section
w("/* Begin XCBuildConfiguration section */")

# Project-level Debug
w(f"\t\t{DEBUG_CONFIG_UUID} /* Debug */ = {{")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
w("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
w("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;")
w("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";")
w("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
w("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
w("\t\t\t\tCOPY_PHASE_STRIP = NO;")
w("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
w("\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;")
w("\t\t\t\tENABLE_TESTABILITY = YES;")
w("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
w("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
w("\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (")
w("\t\t\t\t\t\"DEBUG=1\",")
w("\t\t\t\t\t\"$(inherited)\",")
w("\t\t\t\t);")
w("\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;")
w("\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;")
w("\t\t\t\tMTL_FAST_MATH = YES;")
w("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
w("\t\t\t\tSDKROOT = macosx;")
w("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = \"$(inherited) DEBUG\";")
w("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
w("\t\t\t};")
w("\t\t\tname = Debug;")
w("\t\t};")
w("")

# Project-level Release
w(f"\t\t{RELEASE_CONFIG_UUID} /* Release */ = {{")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
w("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
w("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;")
w("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";")
w("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
w("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
w("\t\t\t\tCOPY_PHASE_STRIP = NO;")
w("\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";")
w("\t\t\t\tENABLE_NS_ASSERTIONS = NO;")
w("\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;")
w("\t\t\t\tGCC_OPTIMIZATION_LEVEL = s;")
w("\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;")
w("\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;")
w("\t\t\t\tMTL_FAST_MATH = YES;")
w("\t\t\t\tSDKROOT = macosx;")
w("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
w("\t\t\t};")
w("\t\t\tname = Release;")
w("\t\t};")
w("")

# Target-level Debug
w(f"\t\t{TARGET_DEBUG_CONFIG_UUID} /* Debug */ = {{")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
w("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
w("\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;")
w("\t\t\t\tCODE_SIGN_ENTITLEMENTS = MeetingManager/MeetingManager.entitlements;")
w("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
w("\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;")
w("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
w("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
w("\t\t\t\tINFOPLIST_FILE = MeetingManager/Info.plist;")
w("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
w("\t\t\t\t\t\"$(inherited)\",")
w("\t\t\t\t\t\"@executable_path/../Frameworks\",")
w("\t\t\t\t);")
w("\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;")
w("\t\t\t\tMARKETING_VERSION = 1.0;")
w("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.meetingmanager.app;")
w("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
w("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
w("\t\t\t\tSWIFT_VERSION = 5.0;")
w("\t\t\t};")
w("\t\t\tname = Debug;")
w("\t\t};")
w("")

# Target-level Release
w(f"\t\t{TARGET_RELEASE_CONFIG_UUID} /* Release */ = {{")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
w("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
w("\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;")
w("\t\t\t\tCODE_SIGN_ENTITLEMENTS = MeetingManager/MeetingManager.entitlements;")
w("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
w("\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;")
w("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
w("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
w("\t\t\t\tINFOPLIST_FILE = MeetingManager/Info.plist;")
w("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
w("\t\t\t\t\t\"$(inherited)\",")
w("\t\t\t\t\t\"@executable_path/../Frameworks\",")
w("\t\t\t\t);")
w("\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;")
w("\t\t\t\tMARKETING_VERSION = 1.0;")
w("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.meetingmanager.app;")
w("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
w("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
w("\t\t\t\tSWIFT_VERSION = 5.0;")
w("\t\t\t};")
w("\t\t\tname = Release;")
w("\t\t};")

w("/* End XCBuildConfiguration section */")
w("")

# XCConfigurationList
w("/* Begin XCConfigurationList section */")
w(f"\t\t{PROJECT_CONFIG_LIST_UUID} /* Build configuration list for PBXProject \"MeetingManager\" */ = {{")
w("\t\t\tisa = XCConfigurationList;")
w("\t\t\tbuildConfigurations = (")
w(f"\t\t\t\t{DEBUG_CONFIG_UUID} /* Debug */,")
w(f"\t\t\t\t{RELEASE_CONFIG_UUID} /* Release */,")
w("\t\t\t);")
w("\t\t\tdefaultConfigurationIsVisible = 0;")
w("\t\t\tdefaultConfigurationName = Release;")
w("\t\t};")

w(f"\t\t{TARGET_CONFIG_LIST_UUID} /* Build configuration list for PBXNativeTarget \"MeetingManager\" */ = {{")
w("\t\t\tisa = XCConfigurationList;")
w("\t\t\tbuildConfigurations = (")
w(f"\t\t\t\t{TARGET_DEBUG_CONFIG_UUID} /* Debug */,")
w(f"\t\t\t\t{TARGET_RELEASE_CONFIG_UUID} /* Release */,")
w("\t\t\t);")
w("\t\t\tdefaultConfigurationIsVisible = 0;")
w("\t\t\tdefaultConfigurationName = Release;")
w("\t\t};")
w("/* End XCConfigurationList section */")
w("")

# XCRemoteSwiftPackageReference
w("/* Begin XCRemoteSwiftPackageReference section */")
w(f"\t\t{PKG_REF_WHISPERKIT_UUID} /* XCRemoteSwiftPackageReference \"WhisperKit\" */ = {{")
w("\t\t\tisa = XCRemoteSwiftPackageReference;")
w("\t\t\trepositoryURL = \"https://github.com/argmaxinc/WhisperKit.git\";")
w("\t\t\trequirement = {")
w("\t\t\t\tkind = upToNextMajorVersion;")
w("\t\t\t\tminimumVersion = 0.9.0;")
w("\t\t\t};")
w("\t\t};")
w("/* End XCRemoteSwiftPackageReference section */")
w("")

# XCSwiftPackageProductDependency
w("/* Begin XCSwiftPackageProductDependency section */")
w(f"\t\t{PKG_PRODUCT_WHISPERKIT_UUID} /* WhisperKit */ = {{")
w("\t\t\tisa = XCSwiftPackageProductDependency;")
w(f"\t\t\tpackage = {PKG_REF_WHISPERKIT_UUID} /* XCRemoteSwiftPackageReference \"WhisperKit\" */;")
w("\t\t\tproductName = WhisperKit;")
w("\t\t};")
w("/* End XCSwiftPackageProductDependency section */")
w("")

w("\t};")
w(f"\trootObject = {PROJECT_UUID} /* Project object */;")
w("}")

# Write the file
output = "\n".join(lines)
output_path = "/Users/michaelvarnell/Desktop/MeetingManager/MeetingManager.xcodeproj/project.pbxproj"
with open(output_path, "w") as f:
    f.write(output)

print(f"Generated {output_path}")
print(f"Total source files: {len(SWIFT_FILES)}")
print(f"Total lines: {len(lines)}")
