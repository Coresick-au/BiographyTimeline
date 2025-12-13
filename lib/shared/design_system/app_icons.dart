import 'package:flutter/material.dart';

/// Semantic icon definitions for the Timeline Biography app
/// Provides consistent iconography for different content types
class AppIcons {
  // Private constructor to prevent instantiation
  AppIcons._();

  // ===========================================================================
  // CONTENT TYPE ICONS
  // ===========================================================================
  
  /// Event icons for timeline events
  static const IconData event = Icons.event;
  static const IconData eventNote = Icons.event_note;
  static const IconData eventAvailable = Icons.event_available;
  static const IconData eventBusy = Icons.event_busy;
  static const IconData eventSeat = Icons.event_seat;
  
  /// Media icons for photos, videos, and audio
  static const IconData photo = Icons.photo;
  static const IconData photoLibrary = Icons.photo_library;
  static const IconData photoCamera = Icons.photo_camera;
  static const IconData videocam = Icons.videocam;
  static const IconData videocamOff = Icons.videocam_off;
  static const IconData videoLibrary = Icons.video_library;
  static const IconData musicNote = Icons.music_note;
  static const IconData audioFile = Icons.audio_file;
  static const IconData mic = Icons.mic;
  static const IconData micOff = Icons.mic_off;
  
  /// Milestone icons for achievements and important dates
  static const IconData star = Icons.star;
  static const IconData stars = Icons.stars;
  static const IconData grade = Icons.grade;
  static const IconData emojiEvents = Icons.emoji_events;
  static const IconData workspacePremium = Icons.workspace_premium;
  static const IconData militaryTech = Icons.military_tech;
  static const IconData flag = Icons.flag;
  static const IconData bookmark = Icons.bookmark;
  static const IconData bookmarkBorder = Icons.bookmark_border;
  
  /// People icons for family, friends, and relationships
  static const IconData person = Icons.person;
  static const IconData people = Icons.people;
  static const IconData personAdd = Icons.person_add;
  static const IconData personRemove = Icons.person_remove;
  static const IconData group = Icons.group;
  static const IconData groups = Icons.groups;
  static const IconData familyRestroom = Icons.family_restroom;
  static const IconData childCare = Icons.child_care;
  static const IconData elderly = Icons.elderly;
  static const IconData accessibilityNew = Icons.accessibility_new;
  
  /// Location icons for places and geography
  static const IconData locationOn = Icons.location_on;
  static const IconData locationOff = Icons.location_off;
  static const IconData place = Icons.place;
  static const IconData home = Icons.home;
  static const IconData work = Icons.work;
  static const IconData school = Icons.school;
  static const IconData localHospital = Icons.local_hospital;
  static const IconData restaurant = Icons.restaurant;
  static const IconData localMall = Icons.local_mall;
  static const IconData park = Icons.park;
  static const IconData beachAccess = Icons.beach_access;
  static const IconData terrain = Icons.terrain;
  static const IconData public = Icons.public;
  static const IconData language = Icons.language;
  
  /// Time and date icons
  static const IconData today = Icons.today;
  static const IconData dateRange = Icons.date_range;
  static const IconData accessTime = Icons.access_time;
  static const IconData schedule = Icons.schedule;
  static const IconData update = Icons.update;
  static const IconData history = Icons.history;
  static const IconData hourglassEmpty = Icons.hourglass_empty;
  static const IconData hourglassFull = Icons.hourglass_full;
  
  /// Communication icons
  static const IconData message = Icons.message;
  static const IconData chat = Icons.chat;
  static const IconData phone = Icons.phone;
  static const IconData email = Icons.email;
  static const IconData contactMail = Icons.contact_mail;
  static const IconData contactPhone = Icons.contact_phone;
  static const IconData share = Icons.share;
  static const IconData send = Icons.send;
  
  /// Document and text icons
  static const IconData description = Icons.description;
  static const IconData article = Icons.article;
  static const IconData textSnippet = Icons.text_snippet;
  static const IconData notes = Icons.notes;
  static const IconData stickyNote2 = Icons.sticky_note_2;
  static const IconData libraryBooks = Icons.library_books;
  static const IconData autoStories = Icons.auto_stories;
  static const IconData menuBook = Icons.menu_book;
  
  /// Action and navigation icons
  static const IconData add = Icons.add;
  static const IconData remove = Icons.remove;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete;
  static const IconData save = Icons.save;
  static const IconData download = Icons.download;
  static const IconData upload = Icons.upload;
  static const IconData search = Icons.search;
  static const IconData filterList = Icons.filter_list;
  static const IconData sort = Icons.sort;
  static const IconData viewList = Icons.view_list;
  static const IconData viewModule = Icons.view_module;
  static const IconData viewCarousel = Icons.view_carousel;
  static const IconData viewTimeline = Icons.view_timeline;
  
  /// Status and feedback icons
  static const IconData check = Icons.check;
  static const IconData checkCircle = Icons.check_circle;
  static const IconData checkCircleOutline = Icons.check_circle_outline;
  static const IconData error = Icons.error;
  static const IconData errorOutline = Icons.error_outline;
  static const IconData warning = Icons.warning;
  static const IconData warningAmber = Icons.warning_amber;
  static const IconData info = Icons.info;
  static const IconData infoOutline = Icons.info_outline;
  static const IconData help = Icons.help;
  static const IconData helpOutline = Icons.help_outline;
  static const IconData lightbulb = Icons.lightbulb;
  static const IconData lightbulbOutline = Icons.lightbulb_outline;
  
  /// Settings and preferences icons
  static const IconData settings = Icons.settings;
  static const IconData settingsApplications = Icons.settings_applications;
  static const IconData tune = Icons.tune;
  static const IconData palette = Icons.palette;
  static const IconData style = Icons.style;
  static const IconData formatSize = Icons.format_size;
  static const IconData accessibility = Icons.accessibility;
  static const IconData contrast = Icons.contrast;
  static const IconData zoomIn = Icons.zoom_in;
  static const IconData zoomOut = Icons.zoom_out;
  
  /// Security and privacy icons
  static const IconData lock = Icons.lock;
  static const IconData lockOpen = Icons.lock_open;
  static const IconData security = Icons.security;
  static const IconData privacyTip = Icons.privacy_tip;
  static const IconData vpnKey = Icons.vpn_key;
  static const IconData fingerprint = Icons.fingerprint;
  
  /// Social and sharing icons
  static const IconData favorite = Icons.favorite;
  static const IconData favoriteBorder = Icons.favorite_border;
  static const IconData thumbUp = Icons.thumb_up;
  static const IconData thumbDown = Icons.thumb_down;
  static const IconData comment = Icons.comment;
  static const IconData tag = Icons.tag;
  static const IconData label = Icons.label;
  static const IconData labelImportant = Icons.label_important;
  
  /// Data and storage icons
  static const IconData storage = Icons.storage;
  static const IconData cloud = Icons.cloud;
  static const IconData cloudDone = Icons.cloud_done;
  static const IconData cloudDownload = Icons.cloud_download;
  static const IconData cloudUpload = Icons.cloud_upload;
  static const IconData cloudOff = Icons.cloud_off;
  static const IconData sync = Icons.sync;
  static const IconData syncProblem = Icons.sync_problem;
  static const IconData backup = Icons.backup;
  static const IconData restore = Icons.restore;
  
  /// Entertainment and hobbies icons
  static const IconData sportsSoccer = Icons.sports_soccer;
  static const IconData sportsBasketball = Icons.sports_basketball;
  static const IconData sportsTennis = Icons.sports_tennis;
  static const IconData sportsEsports = Icons.sports_esports;
  static const IconData musicVideo = Icons.music_video;
  static const IconData headphones = Icons.headphones;
  static const IconData games = Icons.games;
  static const IconData movie = Icons.movie;
  static const IconData tv = Icons.tv;
  static const IconData theaterComedy = Icons.theater_comedy;
  static const IconData nightlife = Icons.nightlife;
  static const IconData celebration = Icons.celebration;
  
  /// Health and wellness icons
  static const IconData fitnessCenter = Icons.fitness_center;
  static const IconData directionsRun = Icons.directions_run;
  static const IconData directionsBike = Icons.directions_bike;
  static const IconData selfImprovement = Icons.self_improvement;
  static const IconData spa = Icons.spa;
  static const IconData medication = Icons.medication;
  static const IconData medicalServices = Icons.medical_services;
  static const IconData healthAndSafety = Icons.health_andSafety;
  static const IconData monitorHeart = Icons.monitor_heart;
  
  /// Travel and transportation icons
  static const IconData flight = Icons.flight;
  static const IconData directionsCar = Icons.directions_car;
  static const IconData directionsTransit = Icons.directions_transit;
  static const IconData directionsWalk = Icons.directions_walk;
  static const IconData hotel = Icons.hotel;
  static const IconData luggage = Icons.luggage;
  static const IconData map = Icons.map;
  static const IconData navigation = Icons.navigation;
  static const IconData explore = Icons.explore;
  
  /// Shopping and commerce icons
  static const IconData shoppingCart = Icons.shopping_cart;
  static const IconData shoppingBag = Icons.shopping_bag;
  static const IconData store = Icons.store;
  static const IconData localOffer = Icons.local_offer;
  static const IconData pointOfSale = Icons.point_of_sale;
  static const IconData receipt = Icons.receipt;
  static const IconData payments = Icons.payments;
  static const IconData accountBalance = Icons.account_balance;
  static const IconData creditCard = Icons.credit_card;
  static const IconData attachMoney = Icons.attach_money;
  
  /// Weather and nature icons
  static const IconData wbSunny = Icons.wb_sunny;
  static const IconData wbCloudy = Icons.wb_cloudy;
  static const IconData cloudQueue = Icons.cloud_queue;
  static const IconData graining = Icons.grain;
  static const IconData waterDrop = Icons.water_drop;
  static const IconData air = Icons.air;
  static const IconData compost = Icons.compost;
  static const IconData eco = Icons.eco;
  
  // ===========================================================================
  // ICON SIZE PRESETS
  // ===========================================================================
  
  /// Extra small icon size (16px)
  static const double sizeXS = 16.0;
  
  /// Small icon size (20px)
  static const double sizeS = 20.0;
  
  /// Medium icon size (24px)
  static const double sizeM = 24.0;
  
  /// Large icon size (32px)
  static const double sizeL = 32.0;
  
  /// Extra large icon size (48px)
  static const double sizeXL = 48.0;
  
  /// XXL icon size (64px)
  static const double sizeXXL = 64.0;
  
  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================
  
  /// Get icon with specified size and color
  static Icon getIcon(
    IconData iconData, {
    double size = sizeM,
    Color? color,
  }) {
    return Icon(
      iconData,
      size: size,
      color: color,
    );
  }
  
  /// Get icon for content type
  static IconData getIconForContentType(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'event':
        return event;
      case 'photo':
      case 'image':
        return photo;
      case 'video':
        return videocam;
      case 'audio':
      case 'music':
        return musicNote;
      case 'milestone':
        return star;
      case 'person':
      case 'people':
        return people;
      case 'location':
      case 'place':
        return locationOn;
      case 'document':
      case 'text':
        return description;
      case 'link':
      case 'url':
        return link;
      default:
        return description;
    }
  }
  
  /// Get themed icon based on theme brightness
  static Icon getThemedIcon(
    IconData iconData, {
    double size = sizeM,
    Brightness brightness = Brightness.light,
  }) {
    final color = brightness == Brightness.dark ? Colors.white : Colors.black87;
    return getIcon(iconData, size: size, color: color);
  }
  
  /// Create an icon button with consistent styling
  static IconButton createIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = sizeM,
    Color? color,
    String? tooltip,
  }) {
    return IconButton(
      icon: getIcon(icon, size: size, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
  
  /// Create an outlined icon button with consistent styling
  static OutlinedButton.icon createOutlinedIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? iconColor,
  }) {
    return OutlinedButton.icon(
      icon: getIcon(icon, color: iconColor),
      label: Text(label),
      onPressed: onPressed,
    );
  }
  
  /// Create an elevated icon button with consistent styling
  static ElevatedButton.icon createElevatedIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? iconColor,
  }) {
    return ElevatedButton.icon(
      icon: getIcon(icon, color: iconColor),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

/// Extension on IconData for quick icon creation
extension IconDataExtension on IconData {
  /// Create an Icon widget with this data
  Icon toIcon({
    double size = AppIcons.sizeM,
    Color? color,
  }) {
    return Icon(
      this,
      size: size,
      color: color,
    );
  }
  
  /// Create a themed icon
  Icon themed({
    double size = AppIcons.sizeM,
    Brightness brightness = Brightness.light,
  }) {
    return AppIcons.getThemedIcon(
      this,
      size: size,
      brightness: brightness,
    );
  }
}
