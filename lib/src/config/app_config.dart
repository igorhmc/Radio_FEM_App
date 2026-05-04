class AppConfig {
  static const requestTimeout = Duration(seconds: 8);
  static const stationName = 'Radio FEM';
  static const baseUrl = 'https://radio.forroemmilao.com/';
  static const apiBaseUrl = 'https://radio.forroemmilao.com/api/';
  static const stationShortcode = 'radiofem';
  static const analyticsStationId = 1;
  static const streamUrl =
      'https://radio.forroemmilao.com/listen/radiofem/android.mp3';
  static const websiteUrl = 'https://radio.forroemmilao.com/public/radiofem';
  static const androidDownloadUrl =
      'https://play.google.com/store/apps/details?id=com.forroemmilao.radiofem';
  static const forroEmMilaoWebsiteUrl = 'https://www.forroemmilao.com';
  static const partnersSourceUrl =
      'https://www.forroemmilao.com/radio.html?lang=en';
  static const contactEmail = 'info@radio.forroemmilao.com';
  static const localBridgeHost = '127.0.0.1';
  static const localBridgePort = 43871;
  static const localBridgeKey = 'radiofem-watch-bridge-v1';
  static const analyticsApiKey = String.fromEnvironment(
    'RADIO_FEM_ANALYTICS_API_KEY',
    defaultValue: '',
  );
  static const aboutShort =
      'Radio FEM is a radio station dedicated to forro in Milan, with curated music, special programming, and community-driven content.';
  static const aboutLong =
      'In the app you can listen to the live stream, browse the weekly and monthly schedule, open the station podcasts, and contact the team.';
}
