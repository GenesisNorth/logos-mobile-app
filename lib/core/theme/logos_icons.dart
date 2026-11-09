import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

/// Icon data type used by Hugeicons (SVG path JSON).
typedef LogosIconData = List<List<dynamic>>;

/// LOGOS IN ME icon registry — every icon in the app comes from the
/// Hugeicons stroke-rounded set (https://hugeicons.com).
///
/// Names mirror the Material icons they replaced so call sites stay readable.
/// The free set is stroke-only, so "filled/active" variants map to the same
/// glyph and active state is conveyed through color.
class LogosIcons {
  LogosIcons._();

  // Navigation & chrome
  static const LogosIconData arrowBack = HugeIcons.strokeRoundedArrowLeft01;
  static const LogosIconData arrowBackIos = HugeIcons.strokeRoundedArrowLeft01;
  static const LogosIconData arrowForwardRounded =
      HugeIcons.strokeRoundedArrowRight01;
  static const LogosIconData arrowForwardIos =
      HugeIcons.strokeRoundedArrowRight01;
  static const LogosIconData arrowDown = HugeIcons.strokeRoundedArrowDown01;
  static const LogosIconData arrowDropDownRounded =
      HugeIcons.strokeRoundedArrowDown01;
  static const LogosIconData chevronRight = HugeIcons.strokeRoundedArrowRight01;
  static const LogosIconData close = HugeIcons.strokeRoundedCancel01;
  static const LogosIconData closeRounded = HugeIcons.strokeRoundedCancel01;
  static const LogosIconData search = HugeIcons.strokeRoundedSearch01;
  static const LogosIconData refreshRounded = HugeIcons.strokeRoundedRefresh;
  static const LogosIconData dragIndicator =
      HugeIcons.strokeRoundedDragDropVertical;
  static const LogosIconData share = HugeIcons.strokeRoundedShare08;
  static const LogosIconData shareOutlined = HugeIcons.strokeRoundedShare08;
  static const LogosIconData send = HugeIcons.strokeRoundedSent;
  static const LogosIconData notificationsNone =
      HugeIcons.strokeRoundedNotification01;
  static const LogosIconData notificationsActive =
      HugeIcons.strokeRoundedNotification03;
  static const LogosIconData visibilityOutlined = HugeIcons.strokeRoundedView;

  // Tabs & Sacred
  static const LogosIconData cross = HugeIcons.strokeRoundedCross;
  static const LogosIconData spaOutlined = HugeIcons.strokeRoundedChurch;
  static const LogosIconData spaRounded = HugeIcons.strokeRoundedChurch;
  static const LogosIconData forumOutlined = HugeIcons.strokeRoundedBubbleChat;
  static const LogosIconData forumRounded = HugeIcons.strokeRoundedBubbleChat;
  static const LogosIconData shieldOutlined = HugeIcons.strokeRoundedShield01;
  static const LogosIconData shieldRounded = HugeIcons.strokeRoundedShield01;
  static const LogosIconData shield = HugeIcons.strokeRoundedShield01;

  // Liturgical hours / circadian
  static const LogosIconData wbTwilightRounded = HugeIcons.strokeRoundedSunrise;
  static const LogosIconData wbSunnyRounded = HugeIcons.strokeRoundedSun03;
  static const LogosIconData wbShadeRounded = HugeIcons.strokeRoundedSunset;
  static const LogosIconData nightlightRound = HugeIcons.strokeRoundedMoon02;
  static const LogosIconData bedtimeRounded = HugeIcons.strokeRoundedMoon02;
  static const LogosIconData bedtimeOutlined = HugeIcons.strokeRoundedMoon02;

  // Status & progress
  static const LogosIconData checkCircleRounded =
      HugeIcons.strokeRoundedCheckmarkCircle02;
  static const LogosIconData checkRounded = HugeIcons.strokeRoundedTick02;
  static const LogosIconData radioButtonUncheckedRounded =
      HugeIcons.strokeRoundedCircle;
  static const LogosIconData lockOutlineRounded =
      HugeIcons.strokeRoundedSquareLock02;
  static const LogosIconData verified = HugeIcons.strokeRoundedCheckmarkBadge01;
  static const LogosIconData verifiedRounded =
      HugeIcons.strokeRoundedCheckmarkBadge01;
  static const LogosIconData verifiedOutlined =
      HugeIcons.strokeRoundedCheckmarkBadge01;
  static const LogosIconData verifiedUser =
      HugeIcons.strokeRoundedCheckmarkBadge01;
  static const LogosIconData timerOutlined = HugeIcons.strokeRoundedTimer02;
  static const LogosIconData calendarToday = HugeIcons.strokeRoundedCalendar03;
  static const LogosIconData localFireDepartment = HugeIcons.strokeRoundedFire;
  static const LogosIconData localFireDepartmentRounded =
      HugeIcons.strokeRoundedFire;
  static const LogosIconData eco = HugeIcons.strokeRoundedLeaf01;
  static const LogosIconData ecoRounded = HugeIcons.strokeRoundedLeaf01;
  static const LogosIconData fileDownload = HugeIcons.strokeRoundedDownload01;
  static const LogosIconData bookDownload = HugeIcons.strokeRoundedBookDownload;
  static const LogosIconData cloudDoneRounded =
      HugeIcons.strokeRoundedCloudCheck;
  static const LogosIconData cloudQueueRounded = HugeIcons.strokeRoundedCloud;

  // Audio & media
  static const LogosIconData mic = HugeIcons.strokeRoundedMic01;
  static const LogosIconData micRounded = HugeIcons.strokeRoundedMic01;
  static const LogosIconData stop = HugeIcons.strokeRoundedStop;
  static const LogosIconData stopRounded = HugeIcons.strokeRoundedStop;
  static const LogosIconData playArrowRounded = HugeIcons.strokeRoundedPlay;
  static const LogosIconData playCircleFill = HugeIcons.strokeRoundedPlayCircle;
  static const LogosIconData playCircleFilled =
      HugeIcons.strokeRoundedPlayCircle;
  static const LogosIconData playCircleFillRounded =
      HugeIcons.strokeRoundedPlayCircle;
  static const LogosIconData pauseCircleFilled =
      HugeIcons.strokeRoundedPauseCircle;
  static const LogosIconData pauseCircleFilledRounded =
      HugeIcons.strokeRoundedPauseCircle;
  static const LogosIconData volumeUpRounded =
      HugeIcons.strokeRoundedVolumeHigh;
  static const LogosIconData volumeOffRounded =
      HugeIcons.strokeRoundedVolumeOff;
  static const LogosIconData graphicEq = HugeIcons.strokeRoundedAudioWave01;
  static const LogosIconData graphicEqRounded =
      HugeIcons.strokeRoundedAudioWave01;
  static const LogosIconData recordVoiceOver =
      HugeIcons.strokeRoundedHandPrayer;
  static const LogosIconData hearing = HugeIcons.strokeRoundedEar;
  static const LogosIconData videoCallOutlined = HugeIcons.strokeRoundedVideo01;
  static const LogosIconData slowWinds = HugeIcons.strokeRoundedSlowWinds;
  static const LogosIconData churchBell = HugeIcons.strokeRoundedBell;

  // Scripture, study & reflection
  static const LogosIconData menuBook = HugeIcons.strokeRoundedBookOpen01;
  static const LogosIconData bookOpen = HugeIcons.strokeRoundedBookOpen01;
  static const LogosIconData autoStories = HugeIcons.strokeRoundedBook02;
  static const LogosIconData autoStoriesRounded = HugeIcons.strokeRoundedBook02;
  static const LogosIconData editNote = HugeIcons.strokeRoundedNoteEdit;
  static const LogosIconData shortTextRounded =
      HugeIcons.strokeRoundedTextAlignLeft;
  static const LogosIconData keyboardAltOutlined =
      HugeIcons.strokeRoundedKeyboard;
  // Non-AI, elevated liturgical and achievement glyphs:
  static const LogosIconData psychologyRounded = HugeIcons.strokeRoundedAward01;
  static const LogosIconData autoAwesome = HugeIcons.strokeRoundedQuillWrite01;
  static const LogosIconData blurOnRounded = HugeIcons.strokeRoundedPuzzle;
  static const LogosIconData syncAltRounded = HugeIcons.strokeRoundedExchange01;
  static const LogosIconData layersClear = HugeIcons.strokeRoundedDelete02;
  static const LogosIconData autoDeleteOutlined =
      HugeIcons.strokeRoundedDelete02;

  // Community
  static const LogosIconData terrain = HugeIcons.strokeRoundedMountain;
  static const LogosIconData waterDrop = HugeIcons.strokeRoundedDroplet;
  static const LogosIconData cake = HugeIcons.strokeRoundedBirthdayCake;
  static const LogosIconData personPin = HugeIcons.strokeRoundedUserCircle;
  static const LogosIconData volunteerActivism =
      HugeIcons.strokeRoundedHandPrayer;
  static const LogosIconData favoriteRounded = HugeIcons.strokeRoundedFavourite;
  static const LogosIconData favoriteOutlineRounded =
      HugeIcons.strokeRoundedFavourite;

  // Settings, safety & account
  static const LogosIconData settings = HugeIcons.strokeRoundedSettings02;
  static const LogosIconData user = HugeIcons.strokeRoundedUserCircle;
  static const LogosIconData edit = HugeIcons.strokeRoundedEdit02;
  static const LogosIconData delete = HugeIcons.strokeRoundedDelete02;
  static const LogosIconData info = HugeIcons.strokeRoundedInformationCircle;
  static const LogosIconData mail = HugeIcons.strokeRoundedMail01;
  static const LogosIconData legal = HugeIcons.strokeRoundedLegalDocument01;
  static const LogosIconData clock = HugeIcons.strokeRoundedClock01;
  static const LogosIconData moon = HugeIcons.strokeRoundedMoon02;
  static const LogosIconData cloudUpload = HugeIcons.strokeRoundedCloudUpload;
  static const LogosIconData flag = HugeIcons.strokeRoundedFlag02;
  static const LogosIconData hide = HugeIcons.strokeRoundedViewOff;
  static const LogosIconData phoneCall = HugeIcons.strokeRoundedCallRinging01;
  static const LogosIconData alert = HugeIcons.strokeRoundedAlert02;
  static const LogosIconData quill = HugeIcons.strokeRoundedQuillWrite01;
  static const LogosIconData volumeHigh = HugeIcons.strokeRoundedVolumeHigh;
  static const LogosIconData more = HugeIcons.strokeRoundedMoreVertical;
}

/// Drop-in replacement for Flutter's [Icon] that renders Hugeicons.
///
/// Respects the ambient [IconTheme] (size & color) just like [Icon], so it
/// works inside [IconButton], [ElevatedButton.icon], etc.
class AppIcon extends StatelessWidget {
  final LogosIconData icon;
  final double? size;
  final Color? color;
  final double? strokeWidth;

  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return HugeIcon(
      icon: icon,
      size: size ?? theme.size ?? 24.0,
      color: color ?? theme.color,
      strokeWidth: strokeWidth ?? 1.8,
    );
  }
}
