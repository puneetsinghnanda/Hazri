/// The icons designs 100 and 101 add to the set, as inner SVG markup for
/// `AppIcon` (24 dp outlines, stroke 1.8). They are kept here rather than in
/// `core/theme/icon_data.dart`, which is generated from `design/html`.
abstract final class ProfileIcons {
  static const String edit = '<path d="M4 20h4L19 9a2.8 2.8 0 0 0-4-4L4 16z"/><path d="M13.5 6.5l4 4"/>';

  static const String cloud = '<path d="M7 18.5a4.5 4.5 0 0 1-.6-9A6 6 0 0 1 18 8.6a4 4 0 0 1-.5 7.9"/>'
      '<path d="M12 12v8M9 15l3-3 3 3"/>';

  static const String restore = '<path d="M4 12a8 8 0 1 0 2.4-5.7"/><path d="M4 4v4.5h4.5"/><path d="M12 8v4l3 2"/>';

  static const String shield = '<path d="M12 3l7.5 3v5.5c0 4.6-3.2 8.2-7.5 9.5-4.3-1.3-7.5-4.9-7.5-9.5V6z"/>'
      '<path d="M9 12l2.2 2.2L15.5 10"/>';

  static const String verified = '<path d="M12 3l2.4 1.8 3 .2.9 2.9 2.2 2-1 2.8 1 2.9-2.2 2-.9 2.9-3 .2L12 21'
      'l-2.4-1.8-3-.2-.9-2.9-2.2-2 1-2.9-1-2.8 2.2-2 .9-2.9 3-.2z"/><path d="M8.5 12.2l2.4 2.4 4.6-4.8"/>';

  static const String search = '<circle cx="11" cy="11" r="6.5"/><path d="M16 16l4.5 4.5"/>';

  static const String sunrise = '<path d="M3 18h18"/><path d="M7 18a5 5 0 0 1 10 0"/>'
      '<path d="M12 4v4M9.5 6.5L12 4l2.5 2.5"/>';

  static const String sunset = '<path d="M3 18h18"/><path d="M7 18a5 5 0 0 1 10 0"/>'
      '<path d="M12 4v4M9.5 5.5L12 8l2.5-2.5"/>';
}
